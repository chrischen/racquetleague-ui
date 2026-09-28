import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { make as EventLocationStory, query } from "./EventLocationStory.gen";

// The venue block on the event page's Location tab (inside EventDetails):
// name, the address linked to the first map link, every link, and the venue's
// notes. Shadow events (imported from elsewhere) hide the address and links.
const VENUE = {
  name: "Minato Sports Center (港区スポーツセンター)",
  address: "1-16-1 Shibaura, Minato City, Tokyo 105-0023",
  links: ["https://maps.app.goo.gl/Minato5FArena", "https://www.minatoku-sports.com/facility/arena"],
  details:
    "Indoor hardwood, 3 pickleball courts on the 5F arena.\n" +
    "Enter from the east side of the building and take the elevator to 5F. Indoor shoes only.\n" +
    "Lockers take ¥100 coins (returned). The nearest station is Tamachi, a 5 minute walk.",
};

const meta = {
  title: "Organisms/EventLocation",
  component: EventLocationStory,
  args: { hideAddress: false },
  parameters: { relay: { query, mocks: { Query: { location: {} }, Location: VENUE } } },
} satisfies Meta<typeof EventLocationStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Everything filled in: the address opens the first map link. */
export const Default: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const address = canvas.getByRole("link", { name: VENUE.address });
    await expect(address).toHaveAttribute("href", VENUE.links[0]);
    await expect(canvas.getByText(/Indoor shoes only/)).toBeVisible();
  },
};

/** No links: the address is plain text. */
export const AddressWithoutLinks: Story = {
  parameters: { relay: { mocks: { Location: { links: null } } } },
};

/** A shadow event keeps the venue's name and notes but hides where it is. */
export const HiddenAddress: Story = {
  args: { hideAddress: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByText(VENUE.address)).toBeNull();
  },
};

/** Links over 50 characters are cut with an ellipsis. */
export const LongLinks: Story = {
  parameters: {
    relay: {
      mocks: {
        Location: {
          name: "Ota City General Gymnasium Sub Arena",
          address: "4-27-20 Higashikamata, Ota City, Tokyo 144-0031",
          links: [
            "https://www.google.com/maps/place/Ota+City+General+Gymnasium/@35.5667,139.7262,17z/data=!3m1!4b1",
            "https://www.city.ota.tokyo.jp/shisetsu/sports/sougou_taiikukan/index.html",
          ],
        },
      },
    },
  },
};

/** A venue that only has a name. */
export const NameOnly: Story = {
  parameters: {
    relay: { mocks: { Location: { name: "Shibuya Ward Gym", address: null, links: null, details: null } } },
  },
};

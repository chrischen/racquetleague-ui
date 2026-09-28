import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, within } from "storybook/test";
import { make as EventDetailsStory, query } from "./EventDetailsStory.gen";

// The tabbed card under the event header on the event page: the organizer's
// description (one paragraph per line), and the venue (EventLocation plus its
// MediaList videos). Shadow events hide the venue's address.
const DETAILS =
  "Thursday night rated doubles at Minato. Games to 11, rally scoring off; we rotate partners every game.\n" +
  "Open to 3.5+ players. Please arrive 10 minutes early to help set up the nets.\n" +
  "¥1,500 per person, paid on the day or with your saved card.\n" +
  "日本語OK・英語OK。初めての方も歓迎です！";

const VENUE = {
  id: "loc-minato",
  name: "Minato Sports Center (港区スポーツセンター)",
  address: "1-16-1 Shibaura, Minato City, Tokyo 105-0023",
  links: ["https://maps.app.goo.gl/Minato5FArena"],
  details: "Indoor hardwood, 3 courts on the 5F arena. Indoor shoes only.\nLockers take ¥100 coins (returned).",
  media: [
    {
      id: "media-1",
      title: "How to find the 5F arena",
      url:
        "data:text/html;charset=utf-8," +
        encodeURIComponent(
          '<body style="margin:0;height:100vh;display:flex;align-items:center;justify-content:center;' +
            'background:#0f0f0f;color:#f1f1f1;font:14px system-ui">▶ How to find the 5F arena</body>',
        ),
    },
  ],
};

const meta = {
  title: "Organisms/EventDetails",
  component: EventDetailsStory,
  parameters: {
    relay: {
      query,
      mocks: {
        Query: { event: {} },
        Event: { details: DETAILS, shadow: false, club: { name: "Tokyo Pickleball Club" }, location: VENUE },
      },
    },
  },
} satisfies Meta<typeof EventDetailsStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The description tab, open by default. */
export const Description: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/Open to 3.5\+ players/)).toBeVisible();
  },
};

/** The location tab: venue, address, notes and the venue's video. */
export const LocationTab: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Location Details" }));
    await expect(await canvas.findByRole("link", { name: VENUE.address })).toBeVisible();
    await expect(canvas.getByText("How to find the 5F arena")).toBeVisible();
  },
};

/** A shadow event's location tab: no address or links. */
export const ShadowEventLocation: Story = {
  parameters: { relay: { mocks: { Event: { shadow: true } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Location Details" }));
    await expect(await canvas.findByText(VENUE.name)).toBeVisible();
    await expect(canvas.queryByText(VENUE.address)).toBeNull();
  },
};

/** No description: the tab shows only its icon. */
export const NoDescription: Story = {
  parameters: { relay: { mocks: { Event: { details: null } } } },
};

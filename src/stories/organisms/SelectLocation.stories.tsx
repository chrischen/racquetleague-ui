import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { make as SelectLocationStory, query } from "./SelectLocationStory.gen";

// The older venue picker for an event: every known venue as a link (the one
// in the URL is bold), and a form to add a new venue by hand. The picked
// venue's page renders in the outlet beside the list.
const venue = (id: string, name: string) => ({ node: { id, name } });
const VENUES = [
  venue("loc-minato", "Minato Sports Center"),
  venue("loc-shibuya", "Shibuya Ward Gym, Sub Arena"),
  venue("loc-ota", "Ota City General Gymnasium"),
  venue("loc-setagaya", "Setagaya Sogo Undojo Gymnasium"),
  venue("loc-koto", "Koto Ward Sports Hall (江東区スポーツ会館)"),
  venue("loc-yokohama", "Yokohama Cultural Gymnasium"),
];

const meta = {
  title: "Organisms/SelectLocation",
  component: SelectLocationStory,
  parameters: {
    router: { path: "location/*", url: "/location" },
    relay: { query, mocks: { Query: { locations: { edges: VENUES } } } },
  },
} satisfies Meta<typeof SelectLocationStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The known venues, none picked. */
export const Venues: Story = {};

/** The venue in the URL is bold. */
export const VenuePicked: Story = {
  parameters: { router: { path: "location/*", url: "/location/loc-shibuya" } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("link", { name: "Shibuya Ward Gym, Sub Arena" })).toHaveClass("font-extrabold");
  },
};

/** "+ add new location" opens the form for a venue by hand. */
export const AddingVenue: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText(/add new location/));
    // The form slides in, so wait for it to settle.
    const cancel = await canvas.findByRole("button", { name: /cancel/i });
    await waitFor(() => expect(cancel).toBeVisible());
  },
};

/** No venues yet. */
export const Empty: Story = {
  parameters: { relay: { mocks: { Query: { locations: { edges: [] } } } } },
};

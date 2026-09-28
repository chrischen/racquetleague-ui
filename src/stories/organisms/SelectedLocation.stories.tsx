import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as SelectedLocationStory, query } from "./SelectedLocationStory.gen";

// The venue section of the event form once a venue is chosen: its name and a
// "change location" toggle that opens the venue search. The search itself
// (AutocompleteLocation) needs Google Places, which Storybook doesn't load,
// so it shows its input but never suggests anything.
const meta = {
  title: "Organisms/SelectedLocation",
  component: SelectedLocationStory,
  args: { onNewLocation: fn() },
  parameters: {
    relay: { query, mocks: { Query: { location: {} }, Location: { name: "Minato Sports Center (港区スポーツセンター)" } } },
  },
} satisfies Meta<typeof SelectedLocationStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A venue is chosen. */
export const Chosen: Story = {};

/** "change location" opens the venue search under it. */
export const ChangingLocation: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("change location"));
    await expect(await canvas.findByRole("combobox")).toBeVisible();
  },
};

/** A venue with no name on record shows "?". */
export const UnnamedVenue: Story = {
  parameters: { relay: { mocks: { Location: { name: null } } } },
};

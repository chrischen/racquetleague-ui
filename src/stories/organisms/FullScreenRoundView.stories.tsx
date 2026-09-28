import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, waitFor, within } from "storybook/test";
import { make as FullScreenRoundViewStory, query } from "./FullScreenRoundViewStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The TV view of the active round, opened from the round header's full-screen
// button: one column per court with big avatars and names, the serving team
// on top (marked SERVING until the court has a score). Players come from the
// shared match roster (StoryFixturesMatch).
const meta = {
  title: "Organisms/FullScreenRoundView",
  component: FullScreenRoundViewStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: { control: "select", options: ["notStarted", "partlyScored", "twoCourts", "fourCourts", "longNames"] },
  },
  args: { state: "notStarted", onClose: fn() },
} satisfies Meta<typeof FullScreenRoundViewStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Three courts, none started: every court shows who serves. */
export const NotStarted: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    // The overlay fades in, so wait for it rather than asserting on first paint.
    await waitFor(() => expect(canvas.getByText("Round 3")).toBeVisible());
    await expect(canvas.getAllByText("SERVING")).toHaveLength(3);
  },
};

/** Court 1 has a score, so it drops the serving marker. */
export const PartlyScored: Story = {
  args: { state: "partlyScored" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getAllByText("SERVING")).toHaveLength(2);
  },
};

export const TwoCourts: Story = { args: { state: "twoCourts" } };

export const FourCourts: Story = { args: { state: "fourCourts" } };

export const LongNames: Story = { args: { state: "longNames" } };

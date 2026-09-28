import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, within } from "storybook/test";
import { make as SeedAdjustmentTimelineStory, query } from "./SeedAdjustmentTimelineStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The amber marker on EventManager's round board where the organiser
// re-seeded players. Collapsed, it counts the players moved (↑ up, ↓ down);
// expanded, each player shows the size of their move, and a delete button
// removes the whole batch. The wrapper sets it on the board's slate
// background, which the marker's label is cut out of.
const meta = {
  title: "Organisms/SeedAdjustmentTimeline",
  component: SeedAdjustmentTimelineStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: { control: "inline-radio", options: ["seeds", "singlePlayer", "everyone", "severalRounds"] },
  },
  args: { state: "seeds", onDelete: fn() },
} satisfies Meta<typeof SeedAdjustmentTimelineStory>;

export default meta;
type Story = StoryObj<typeof meta>;

const expand = async (canvasElement: HTMLElement, index = 0) => {
  const canvas = within(canvasElement);
  await userEvent.click((await canvas.findAllByRole("button", { name: /Seeds Adjusted/ }))[index]);
  return canvas;
};

/** The seeding before round 1, collapsed: six players, three up and three down. */
export const Collapsed: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("6 players")).toBeVisible();
    await expect(canvas.getByText("↑3")).toBeVisible();
    await expect(canvas.getByText("↓3")).toBeVisible();
  },
};

/** Expanded: each player's move, avatars where they have a picture, and delete. */
export const Expanded: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = await expand(canvasElement);
    await expect(await canvas.findByText("Daniel Kim")).toBeVisible();
    await expect(canvas.getByText("3.1")).toBeVisible();
    await userEvent.click(canvas.getByTitle("Delete seed adjustment"));
    await expect(args.onDelete).toHaveBeenCalledWith("Before round 1");
  },
};

/** One player moved: singular count, up arrow only. */
export const SinglePlayer: Story = {
  args: { state: "singlePlayer" },
  play: async ({ canvasElement }) => {
    await expect(await within(canvasElement).findByText("1 player")).toBeVisible();
  },
};

/** Everyone re-seeded, walk-ins too: a dense grid with long names; two unmoved players show a dash. */
export const EveryoneMoved: Story = {
  args: { state: "everyone" },
  play: async ({ canvasElement }) => {
    const canvas = await expand(canvasElement);
    await expect(await canvas.findByText("Maximilian von Hohenberg-Schwarzenau")).toBeVisible();
    await expect(canvas.getAllByText("—")).toHaveLength(2);
  },
};

/** Three batches down the board: the seeding, then adjustments before rounds 2 and 3. */
export const SeveralRounds: Story = {
  args: { state: "severalRounds" },
  play: async ({ canvasElement }) => {
    const canvas = await expand(canvasElement, 2);
    // The round-3 batch includes the walk-in, who has no picture.
    await expect(await canvas.findByText("Kaito Mori")).toBeVisible();
  },
};

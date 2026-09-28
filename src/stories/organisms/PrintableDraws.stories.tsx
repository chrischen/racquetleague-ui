import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, within } from "storybook/test";
import { make as PrintableDrawsStory } from "./PrintableDrawsStory.gen";

// The print preview of the whole draw (EventManager's print button): a dark
// toolbar with Print and close, then an A4-ish sheet with each round's
// courts, player numbers and empty score boxes. The date in the sheet header
// is today's, so it changes between runs. Players come from the shared match
// roster (StoryFixturesMatch); no Relay data.
const meta = {
  title: "Organisms/PrintableDraws",
  component: PrintableDrawsStory,
  parameters: { layout: "fullscreen" },
  argTypes: {
    state: { control: "select", options: ["threeRounds", "empty", "singleMatch", "longNames", "manyRounds"] },
  },
  args: { state: "threeRounds", onClose: fn() },
} satisfies Meta<typeof PrintableDrawsStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Three rounds on three courts. */
export const ThreeRounds: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Tournament Draws")).toBeVisible();
    await expect(canvas.getAllByText("3 matches")).toHaveLength(3);
  },
};

export const Empty: Story = {
  args: { state: "empty" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByText("No draws generated yet.")).toBeVisible();
  },
};

/** One court: the round header says "1 match". */
export const SingleMatch: Story = {
  args: { state: "singleMatch" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByText("1 match")).toBeVisible();
  },
};

export const LongNames: Story = { args: { state: "longNames" } };

/** Eight rounds: a long sheet. */
export const ManyRounds: Story = { args: { state: "manyRounds" } };

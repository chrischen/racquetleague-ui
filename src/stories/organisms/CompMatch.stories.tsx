import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as CompMatchStory } from "./CompMatchStory.gen";

// The match chooser AiTetsu's queue screen opens ("Choose Match"): strategy
// tabs, the gender-mixed toggle, the recommended match and every candidate
// with its quality bar. Teams seen before are shaded yellow, last round's red.
// Players come from the shared match roster (StoryFixturesMatch); the
// component reads no Relay data.
const meta = {
  title: "Organisms/CompMatch",
  component: CompMatchStory,
  argTypes: {
    state: {
      control: "select",
      options: ["queue", "notEnoughPlayers", "withHistory", "somePlaying", "replacePlayer"],
    },
    strategy: { control: "inline-radio", options: ["competitive", "mixed"] },
  },
  args: { state: "queue", strategy: "competitive", onSelectMatch: fn() },
} satisfies Meta<typeof CompMatchStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Eight players queued for two courts, Competitive strategy. */
export const Competitive: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Recommended Match")).toBeVisible();
    await expect(canvas.getByText(/Analyzed \d+ matches\./)).toBeVisible();
  },
};

/** Mixed strategy: strong and weak players paired together. */
export const Mixed: Story = { args: { strategy: "mixed" } };

/** Fewer than four queued: nothing to recommend. */
export const NotEnoughPlayers: Story = {
  args: { state: "notEnoughPlayers" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByRole("alert")).toHaveTextContent("Not enough players in the queue.");
  },
};

/** Kenji & Yuki and Chris & Aiko partnered earlier (yellow), Kenji & Chris last round (red). */
export const WithHistory: Story = { args: { state: "withHistory" } };

/** Twelve queued but four still on court: they are left out of every candidate. */
export const SomePlaying: Story = { args: { state: "somePlaying" } };

/** Replacing one player: every candidate keeps the other three. */
export const ReplacePlayer: Story = { args: { state: "replacePlayer" } };

/** Ticking Gender Mixed Doubles re-ranks for mixed pairs. */
export const GenderMixed: Story = {
  play: async ({ canvasElement }) => {
    const checkbox = within(canvasElement).getByRole("checkbox");
    await userEvent.click(checkbox);
    await waitFor(() => expect(checkbox).toBeChecked());
  },
};

/** Select on the recommended match hands it to the queue. */
export const SelectRecommended: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getAllByRole("link", { name: "Select" })[0]);
    await waitFor(() => expect(args.onSelectMatch).toHaveBeenCalled());
  },
};

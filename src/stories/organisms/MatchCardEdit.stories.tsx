import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as MatchCardEditStory, query } from "./MatchCardEditStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// MatchCard's edit mode (the pencil on a court card): the line-up as editable
// player rows, the recorded score read-only (scores are entered through the
// score modal), and save / delete in the header. Players come from the shared
// match roster (StoryFixturesMatch).
const meta = {
  title: "Organisms/MatchCardEdit",
  component: MatchCardEditStory,
  parameters: { relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: { control: "inline-radio", options: ["unscored", "scored", "winnerPicked", "longNames"] },
  },
  args: { state: "scored", courtNumber: 1, onSave: fn(), onCancel: fn(), onDelete: fn() },
} satisfies Meta<typeof MatchCardEditStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A finished match: 11–7 shown beside each team. */
export const Scored: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Court 1 - Editing")).toBeVisible();
    await expect(canvas.getByText("11")).toBeVisible();
    // Saving hands the recorded score back untouched.
    await userEvent.click(canvas.getByRole("button", { name: "Save" }));
    await waitFor(() => expect(args.onSave).toHaveBeenCalledWith([11, 7]));
    await expect(args.onCancel).toHaveBeenCalled();
  },
};

/** Not played yet: dashes where the scores go. */
export const Unscored: Story = { args: { state: "unscored" } };

/** Winner tapped without a score (1 to −1): dashes, never a bare "−1". */
export const WinnerPicked: Story = {
  args: { state: "winnerPicked" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).queryByText("-1")).toBeNull();
  },
};

export const LongNames: Story = { args: { state: "longNames", courtNumber: 12 } };

/** Without a delete handler the header has only the save tick. */
export const NoDelete: Story = {
  args: { onDelete: undefined },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).queryByRole("button", { name: "Delete match" })).toBeNull();
  },
};

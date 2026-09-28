import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fireEvent, fn, userEvent, waitFor, within } from "storybook/test";
import { make as MatchCardStory, query } from "./MatchCardStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// One court's card on the round board (EventManager / Round Robin): two
// doubles teams, the serving dot or result icons, the prediction bar under the
// favoured team, and the header's rebalance / delete / edit actions. Tap a team
// to record it as the winner; long-press it for the score modal. Players come
// from the shared match roster (StoryFixturesMatch).
const meta = {
  title: "Organisms/MatchCard",
  component: MatchCardStory,
  parameters: { relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: {
      control: "select",
      options: ["unscored", "scored", "winnerPicked", "draw", "mismatch", "repeat", "lastRound", "longNames"],
    },
  },
  args: {
    state: "unscored",
    courtNumber: 1,
    onDelete: fn(),
    onRebalance: fn(),
    onUpdated: fn(),
  },
} satisfies Meta<typeof MatchCardStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Not started: the blue dot marks the serving team. */
export const Unscored: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("Court 1")).toBeVisible();
    await expect(canvas.getByText("Kenji Tanaka")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Rebalance match" })).toBeVisible();
  },
};

/** Scored 11–7: trophy and bold names for the winners, muted losers. */
export const Scored: Story = { args: { state: "scored" } };

/** The organiser tapped the winning team without entering a score: trophy, no numbers. */
export const WinnerPicked: Story = { args: { state: "winnerPicked" } };

/** Equal scores are a draw: both teams get the equals icon. */
export const Draw: Story = { args: { state: "draw" } };

/** The two strongest players against the two weakest: a long prediction bar. */
export const Mismatch: Story = { args: { state: "mismatch" } };

/** Both teams and the match were already played in an earlier round (amber). */
export const RepeatPairing: Story = {
  args: { state: "repeat" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByText("Repeat")).toBeVisible();
  },
};

/** Exactly last round's match again (red). */
export const LastRoundRematch: Story = {
  args: { state: "lastRound" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByText("Last Round")).toBeVisible();
  },
};

export const LongNames: Story = { args: { state: "longNames", courtNumber: 12 } };

/** Edit mode (the pencil): the line-up as editable rows, the score read-only. */
export const EditMode: Story = {
  args: { state: "scored", editing: true },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByText("Court 1 - Editing")).toBeVisible();
  },
};

/** Debug mode adds match quality in the header and μ/σ under each player. */
export const Debug: Story = { args: { debug: true } };

/** As the Round Robin draws preview shows it: no rebalance or delete. */
export const DrawsPreview: Story = {
  args: { onDelete: undefined, onRebalance: undefined },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByRole("button", { name: "Rebalance match" })).toBeNull();
    await expect(canvas.queryByRole("button", { name: "Delete match" })).toBeNull();
  },
};

/** Tapping a team records it as the winner (1 to −1, no score). */
export const TapToPickWinner: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("Kenji Tanaka"));
    await waitFor(() => expect(args.onUpdated).toHaveBeenCalledWith([1, -1]));
  },
};

/** Long-pressing a team opens the score modal with that team as the winner. */
export const LongPressForScore: Story = {
  parameters: { layout: "fullscreen" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const team = canvas.getByText("Yuki Sato");
    fireEvent.pointerDown(team, { pointerId: 1, pageX: 10, pageY: 10 });
    const title = await canvas.findByText("Enter Match Score", {}, { timeout: 3000 });
    fireEvent.pointerUp(team, { pointerId: 1, pageX: 10, pageY: 10 });
    await expect(title).toBeVisible();
    await expect(canvas.getByText("Winning Team (Team 2)")).toBeVisible();
  },
};

/** Deleting asks first. */
export const DeleteConfirmation: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Delete match" }));
    const body = within(canvasElement.ownerDocument.body);
    // The dialog fades in, so wait for it rather than asserting on first paint.
    const title = await body.findByText("Delete this match?");
    await waitFor(() => expect(title).toBeVisible());
  },
};

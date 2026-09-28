import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as ScoreModalStory, query } from "./ScoreModalStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The score entry modal a long-press on a MatchCard team opens. It is framed
// around the pressed team as the winner: pick its score, then the other
// team's (which can't be higher; equal is a draw), or record the winner with
// No Score. onSubmit gets (team 1 score, team 2 score). Players come from the
// shared match roster (StoryFixturesMatch).
const meta = {
  title: "Organisms/ScoreModal",
  component: ScoreModalStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    winningTeam: { control: "inline-radio", options: ["team1", "team2"] },
    state: { control: "inline-radio", options: ["typical", "longNames"] },
  },
  args: { winningTeam: "team1", state: "typical", onSubmit: fn(), onClose: fn() },
} satisfies Meta<typeof ScoreModalStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// The first score grid belongs to the pressed team, the second to the other.
const grids = (canvasElement: HTMLElement) => {
  const canvas = within(canvasElement);
  return {
    canvas,
    winner: (n: number) => canvas.getAllByRole("button", { name: String(n) })[0],
    loser: (n: number) => canvas.getAllByRole("button", { name: String(n) })[1],
  };
};

/** Team 1 was pressed: nothing entered yet, Save disabled. */
export const Team1Pressed: Story = {
  play: async ({ canvasElement }) => {
    const { canvas } = grids(canvasElement);
    await expect(canvas.getByText("Winning Team (Team 1)")).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Save Score" })).toBeDisabled();
  },
};

export const Team2Pressed: Story = { args: { winningTeam: "team2" } };

/** 11–7 entered: the losing grid disables scores above 11, and Save submits. */
export const ScoreEntered: Story = {
  play: async ({ args, canvasElement }) => {
    const { canvas, winner, loser } = grids(canvasElement);
    await userEvent.click(winner(11));
    await expect(loser(12)).toBeDisabled();
    await userEvent.click(loser(7));
    const save = canvas.getByRole("button", { name: "Save Score" });
    await expect(save).toBeEnabled();
    await userEvent.click(save);
    await waitFor(() => expect(args.onSubmit).toHaveBeenCalledWith(11, 7));
  },
};

/** Team 2 pressed and won 11–9: onSubmit still gets team 1's score first. */
export const Team2Won: Story = {
  args: { winningTeam: "team2" },
  play: async ({ args, canvasElement }) => {
    const { canvas, winner, loser } = grids(canvasElement);
    await userEvent.click(winner(11));
    await userEvent.click(loser(9));
    await userEvent.click(canvas.getByRole("button", { name: "Save Score" }));
    await waitFor(() => expect(args.onSubmit).toHaveBeenCalledWith(9, 11));
  },
};

/** Equal scores: the win/loss framing drops and the footer says it's a draw. */
export const Draw: Story = {
  play: async ({ canvasElement }) => {
    const { canvas, winner, loser } = grids(canvasElement);
    await userEvent.click(winner(10));
    await userEvent.click(loser(10));
    await expect(canvas.getByText("Equal scores — this will be recorded as a draw")).toBeVisible();
    await expect(canvas.getByText("Team 1")).toBeVisible();
  },
};

/** No Score records the pressed team as the winner (1 to −1). */
export const NoScore: Story = {
  play: async ({ args, canvasElement }) => {
    await userEvent.click(within(canvasElement).getByRole("button", { name: "No Score" }));
    await waitFor(() => expect(args.onSubmit).toHaveBeenCalledWith(1, -1));
    await expect(args.onClose).toHaveBeenCalled();
  },
};

export const LongNames: Story = { args: { state: "longNames" } };

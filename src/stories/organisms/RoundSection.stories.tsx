import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fn, userEvent, waitFor, within } from "storybook/test";
import { make as RoundSectionStory, query } from "./RoundSectionStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// One round on the EventManager board. The active round is outlined in blue
// with its actions (full screen, rebalance, reset with mixed pairs, reset);
// past rounds are faded and start collapsed; upcoming rounds are faded but
// open. Under the courts, the avatars of checked-in players sitting out
// expand into a list. The wrapper keeps the matches in state, so tapping
// teams, scoring, deleting and replacing players all work. Fixture: a
// Thursday night, 16 players on three courts (StoryFixturesMatch).
const meta = {
  title: "Organisms/RoundSection",
  component: RoundSectionStory,
  parameters: { relay: { query, mocks: { Query: { event: eventMock } } } },
  argTypes: {
    state: { control: "select", options: ["current", "repeats", "past", "upcoming", "manyWaiting"] },
  },
  args: {
    state: "current",
    debug: false,
    onRebalance: fn(),
    onRebalanceMatch: fn(),
    onReset: fn(),
    onFullScreen: fn(),
    onMatchUpdated: fn(),
    onMatchCanceled: fn(),
  },
} satisfies Meta<typeof RoundSectionStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Round 2 in play: court 1 is in, courts 2 and 3 still playing; four sit out. */
export const CurrentRound: Story = {
  play: async ({ args, canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("ACTIVE ROUND")).toBeVisible();
    await expect(canvas.getByText("3 matches")).toBeVisible();
    await userEvent.click(canvas.getByTitle("Reset this round with mixed gender pairs"));
    await expect(args.onReset).toHaveBeenCalledWith(true);
  },
};

/** Round 3 active: court 1 replays a round-1 match (amber), court 2 reuses a pair from last round (red). */
export const RepeatWarnings: Story = {
  args: { state: "repeats" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByText("Repeat")).toBeVisible();
  },
};

/** A finished round starts collapsed. */
export const PastRoundCollapsed: Story = {
  args: { state: "past" },
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).queryByText("Court 1")).toBeNull();
  },
};

/** Expanded: 11–8, 9–11, and a winner tapped without a score. */
export const PastRoundExpanded: Story = {
  args: { state: "past" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: /Round 1/ }));
    await expect(await canvas.findByText("Court 1")).toBeVisible();
  },
};

/** Drawn but not started: faded, open, no actions. */
export const UpcomingRound: Story = { args: { state: "upcoming" } };

/** Two courts in play and eight waiting: five avatars and "+3", which expand into the list. */
export const ManyWaiting: Story = {
  args: { state: "manyWaiting" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByText("+3"));
    await expect(await canvas.findByText("Naomi Yoshida")).toBeVisible();
  },
};

/** Without round handlers the header has no actions. */
export const NoRoundActions: Story = {
  args: { onRebalance: undefined, onReset: undefined, onFullScreen: undefined, onRebalanceMatch: undefined },
};

/** Debug mode: average match quality in the header, μ/σ on every player. */
export const Debug: Story = { args: { debug: true } };

/** Edit a court, then tap a player to swap in someone sitting out. */
export const ReplacePlayer: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getAllByRole("button", { name: "Edit match" })[1]);
    await userEvent.click(await canvas.findByText("Chris Chen"));
    const body = within(canvasElement.ownerDocument.body);
    await expect(await body.findByText("Replace Player")).toBeVisible();
    await userEvent.click(await body.findByText("Sarah Johnson"));
    await waitFor(() => expect(body.queryByText("Replace Player")).toBeNull());
  },
};

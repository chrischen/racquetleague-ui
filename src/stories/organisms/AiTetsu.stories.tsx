import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { make as AiTetsuStory, query } from "./AiTetsuStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";
import { must } from "../support";

// The older session tool on a league event page (AiTetsu). Its first screen
// holds Start Session and an Offline Mode switch, the leaderboard in three
// columns strongest first, Advanced Options (queue or check in everyone, and
// three icon toggles for the team builder, adding a walk-in and settings),
// the event's submitted matches (the children slot: MatchHistoryList) and the
// session's own match history. Start Session switches to the black full-screen
// session (MatchesView), which opens on check-in. The session is restored from
// localStorage, which the wrapper fills first: a Thursday night with 20 RSVPs
// (StoryFixturesMatch), 16 checked in, and round 1 and 2 results. (No walk-ins:
// AiTetsu cannot read back the walk-ins it saves; see AiTetsuStory.res.)
const EVENT = {
  ...eventMock,
  tags: [],
  activity: { id: "act-pickleball", slug: "pickleball" },
};

const users = Object.fromEntries(eventMock.rsvps.edges.map((e) => [e.node.user.id, e.node.user]));

/** [user id, mu before, change in mu] */
type Seat = [string, number, number];

// A result as the server has it: winners' score first, each player's rating
// before the match and its change.
const match = (id: string, createdAt: string, winners: Seat[], losers: Seat[], score: [number, number]) => ({
  node: {
    id,
    createdAt,
    namespace: "doubles:rec",
    score,
    winners: winners.map(([u]) => users[u]),
    losers: losers.map(([u]) => users[u]),
    playerMetadata: JSON.stringify(
      Object.fromEntries(
        [...winners, ...losers].map(([u, mu, muDiff]) => [u, { mu, sigma: 4.2, muDiff, sigmaDiff: -0.05 }]),
      ),
    ),
  },
});

// Round 1 as submitted from the session screen.
const SUBMITTED = {
  edges: [
    match(
      "match-r1-c2",
      "2026-10-15T10:14:00.000Z",
      [["user-aiko", 28.8, 0.9], ["user-daniel", 24.6, 1.4]],
      [["user-chris", 29.6, -0.8], ["user-sarah", 22.1, -1.1]],
      [11, 9],
    ),
    match(
      "match-r1-c1",
      "2026-10-15T10:12:00.000Z",
      [["user-kenji", 32.4, 0.5], ["user-mai", 25.2, 1.2]],
      [["user-yuki", 30.9, -0.6], ["user-takumi", 26.1, -0.9]],
      [11, 8],
    ),
  ],
};

const meta = {
  title: "Organisms/AiTetsu",
  component: AiTetsuStory,
  parameters: {
    layout: "fullscreen",
    relay: { query, mocks: { Query: { event: EVENT, matches: SUBMITTED } } },
  },
  argTypes: { state: { control: "inline-radio", options: ["fresh", "underway"] } },
  args: { state: "underway" },
} satisfies Meta<typeof AiTetsuStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// The three icon toggles beside "Checkin All Players": team builder, add a walk-in, settings.
const toggles = async (canvasElement: HTMLElement) => {
  const canvas = within(canvasElement);
  const checkinAll = await canvas.findByRole("button", { name: "Checkin All Players" });
  const bar = must(must(checkinAll.parentElement, "check-in row").parentElement, "check-in bar");
  const [teams, addPlayer, settings] = Array.from(bar.querySelectorAll<HTMLElement>(":scope > a"));
  return { teams, addPlayer, settings };
};

/** A new session: the leaderboard from everyone's rating, nobody checked in, nothing played. */
export const FreshSession: Story = {
  args: { state: "fresh" },
  parameters: { relay: { mocks: { Query: { matches: { edges: [] } } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Leaderboard")).toBeVisible();
    await expect(canvas.getByText("Kenji Tanaka")).toBeVisible();
  },
};

/** Two rounds in: round 1 submitted to the server, and six results in the session's own history. */
export const Underway: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Match History")).toBeVisible();
    await waitFor(() => expect(canvas.getAllByText("Cancel")).toHaveLength(6));
  },
};

/** The settings toggle: players on a break per round, re-initialise ratings, clear the session. */
export const SettingsPane: Story = {
  play: async ({ canvasElement }) => {
    const { settings } = await toggles(canvasElement);
    await userEvent.click(settings);
    await expect(await within(canvasElement).findByText("Initialize Ratings")).toBeVisible();
  },
};

/** The team builder: fixed pairs and anti-teams, picked from the leaderboard. */
export const TeamBuilder: Story = {
  play: async ({ canvasElement }) => {
    const { teams } = await toggles(canvasElement);
    await userEvent.click(teams);
    await expect(
      await within(canvasElement).findByText("Players in teams will always be placed in a match together on the same side."),
    ).toBeVisible();
  },
};

/** Start Session: the black full-screen session opens on check-in, 16 of 20 here. */
export const SessionCheckIn: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByText("Start Session"));
    await expect(await canvas.findByText("# of courts")).toBeVisible();
  },
};

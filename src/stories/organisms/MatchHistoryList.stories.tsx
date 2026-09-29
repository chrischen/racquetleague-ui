import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { roster } from "./StoryFixturesProfile.gen";
import { make as MatchHistoryListStory, query } from "./MatchHistoryListStory.gen";

// Match cards for a player's league page or an event's results: both teams
// with each player's rating change and a ring for their skill within the
// match, the score and result, and a bar under the card for the pre-match
// favourite (blue; amber when the favourite lost, an "Even" tab when neither
// side was over 55% to win). From a player's page their team is on the left
// and the result is theirs (WIN/LOSS); without a player the winners are.
// Players come from the shared roster in StoryFixturesProfile.res.

/** [user id, mu before the match, sigma before, change in mu] */
type Seat = [string, number, number, number];

const user = (id: string) => {
  const p = roster.find((r) => r.id === id);
  if (!p) throw new Error(`no roster player ${id}`);
  return { id: p.id, lineUsername: p.lineUsername, picture: p.picture, gender: p.gender };
};

const match = (
  id: string,
  createdAt: string,
  winners: Seat[],
  losers: Seat[],
  score: [number, number] | null,
  namespace = "doubles:comp",
) => {
  // Each player's rating before the match and its change, keyed by user id.
  const playerMetadata = JSON.stringify(
    Object.fromEntries(
      [...winners, ...losers].map(([u, mu, sigma, muDiff]) => [u, { mu, sigma, muDiff, sigmaDiff: -0.04 }]),
    ),
  ) as string | null;
  return {
    node: {
      id,
      createdAt,
      namespace,
      // Winners' score first, as the server stores it.
      score,
      winners: winners.map(([u]) => user(u)),
      losers: losers.map(([u]) => user(u)),
      playerMetadata,
    },
  };
};

/** A match with no rating data (a friendly): no rating changes, and no favourite, so the bar shows "Even". */
const unrated = (m: ReturnType<typeof match>) => ({ node: { ...m.node, playerMetadata: null } });

const connection = (edges: ReturnType<typeof match>[], pageInfo: Record<string, unknown> = {}) => ({
  edges,
  pageInfo: { hasNextPage: false, hasPreviousPage: false, startCursor: null, endCursor: null, ...pageInfo },
});

/** Kenji's last few weeks: expected results, upsets both ways, an unrated drawn friendly, a competitive match. */
const KENJI: ReturnType<typeof match>[] = [
  match("match-601", "2026-09-26T11:40:00.000Z",
    [["user-kenji", 41.5, 2.1, 0.31], ["user-aki", 40.1, 2.3, 0.28]],
    [["user-dan", 39.6, 2.4, -0.27], ["user-yuki", 38.1, 2.2, -0.25]], [11, 8]),
  match("match-600", "2026-09-26T11:10:00.000Z",
    [["user-kenji", 41.3, 2.1, 0.12], ["user-ren", 24.1, 5.2, 1.94]],
    [["user-emily", 35.1, 2.7, -0.52], ["user-sho", 34.7, 2.7, -0.48]], [11, 9]),
  match("match-590", "2026-09-19T11:30:00.000Z",
    [["user-taro", 26.4, 4.1, 1.62], ["user-jess", 27.2, 3.8, 1.47]],
    [["user-kenji", 41.9, 2.1, -0.61], ["user-mai", 33.2, 2.6, -0.55]], [11, 9]),
  match("match-589", "2026-09-19T11:00:00.000Z",
    [["user-takumi", 37.9, 2.6, 0.22], ["user-haruka", 36.4, 2.5, 0.2]],
    [["user-kenji", 42.0, 2.1, -0.14], ["user-naomi", 28.7, 3.4, -0.31]], [11, 6]),
  unrated(match("match-575", "2026-09-12T10:45:00.000Z",
    [["user-kenji", 40.0, 2.5, 0], ["user-olivia", 30.0, 3.0, 0]],
    [["user-ryo", 40.0, 2.5, 0], ["user-sakura", 30.0, 3.0, 0]], [10, 10], "friendly")),
  match("match-561", "2026-09-05T11:20:00.000Z",
    [["user-kenji", 40.9, 2.3, 0.45], ["user-chris", 33.9, 2.8, 0.4]],
    [["user-ryo", 35.8, 2.4, -0.4], ["user-lucas", 32.8, 3.1, -0.38]], [11, 5], "competitive"),
];

/** One event night's results, as LeagueEventPage lists them (no player). */
const EVENT_NIGHT = [
  match("match-701", "2026-09-24T12:10:00.000Z",
    [["user-aki", 40.2, 2.3, 0.35], ["user-sho", 34.7, 2.7, 0.3]],
    [["user-yuki", 38.1, 2.2, -0.3], ["user-kaito", 29.8, 3.3, -0.36]], [11, 7]),
  match("match-700", "2026-09-24T11:50:00.000Z",
    [["user-mike", 28.1, 3.6, 1.38], ["user-sakura", 30.4, 3.1, 1.21]],
    [["user-dan", 39.6, 2.4, -0.66], ["user-emily", 35.1, 2.7, -0.59]], [12, 10]),
  match("match-699", "2026-09-24T11:30:00.000Z",
    [["user-takumi", 37.9, 2.6, 0.18], ["user-olivia", 31.9, 3.0, 0.2]],
    [["user-hiroshi", 31.5, 3.2, -0.21], ["user-naomi", 28.7, 3.4, -0.2]], [11, 4]),
  // An unscored draw is stored as the (-1, -1) sentinel.
  match("match-698", "2026-09-24T11:10:00.000Z",
    [["user-ryo", 35.8, 2.4, 0], ["user-jess", 27.2, 3.8, 0]],
    [["user-lucas", 32.8, 3.1, 0], ["user-mai", 33.2, 2.6, 0]], [-1, -1]),
  // A match recorded without a score: no score, the recorded winners won.
  match("match-697", "2026-09-24T10:50:00.000Z",
    [["user-kenji", 41.5, 2.1, 0.2], ["user-haruka", 36.4, 2.5, 0.18]],
    [["user-chris", 33.9, 2.8, -0.2], ["user-taro", 26.4, 4.1, -0.16]], null),
];

const meta = {
  title: "Organisms/MatchHistoryList",
  component: MatchHistoryListStory,
  // `user: {}` makes the user(id:) root field non-null (it takes the id from the argument).
  parameters: { relay: { query, mocks: { Query: { user: {}, matches: connection(KENJI) } } } },
  args: { perspective: "player" },
} satisfies Meta<typeof MatchHistoryListStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** On Kenji's page: his team always on the left, results read from his side. */
export const PlayerHistory: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect((await canvas.findAllByText("WIN")).length).toBeGreaterThan(0);
    await expect(canvas.getAllByText("Upset").length).toBeGreaterThan(0);
    await expect(canvas.getAllByText("Even").length).toBeGreaterThan(0);
    await expect(canvas.getAllByText("DRAW").length).toBeGreaterThan(0);
  },
};

/**
 * An event's results, with no player to anchor the cards. They read neutrally:
 * the team that won on the score is on the left, "left BEAT right", and the
 * unscored draw and the match recorded without a score show none.
 */
export const EventResults: Story = {
  args: { perspective: "event" },
  parameters: { relay: { mocks: { Query: { matches: connection(EVENT_NIGHT) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect((await canvas.findAllByText("BEAT")).length).toBeGreaterThan(0);
    await expect(canvas.queryByText("LOSS")).toBeNull();
    await expect(canvas.queryByText("WIN")).toBeNull();
    await expect(canvas.getAllByText("DRAW").length).toBeGreaterThan(0);
    await expect(canvas.queryByText("-1")).toBeNull();
    // No made-up score for the match without one.
    await expect(canvas.queryByText("21")).toBeNull();
  },
};

/** Links to earlier and later pages of matches around the loaded window. */
export const MorePages: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          matches: connection(KENJI.slice(0, 3), {
            hasNextPage: true,
            hasPreviousPage: true,
            startCursor: "cursor-21",
            endCursor: "cursor-23",
          }),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("link", { name: "Load more matches..." })).toBeVisible();
    await expect(canvas.getByRole("link", { name: "...load previous matches" })).toBeVisible();
  },
};

/** No matches recorded: the list renders nothing, not even a message. */
export const NoMatches: Story = {
  parameters: { relay: { mocks: { Query: { matches: connection([]) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByText(/WIN|LOSS|DRAW/)).toBeNull();
  },
};

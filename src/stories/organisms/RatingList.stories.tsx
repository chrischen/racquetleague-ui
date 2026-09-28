import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { roster, type player } from "./StoryFixturesProfile.gen";
import { make as RatingListStory, query } from "./RatingListStory.gen";

// The league leaderboard (LeagueRankingsPage): rank, player, rating (ordinal,
// mu - 3 sigma), estimated DUPR and days at #1, each row filled in proportion
// to the rating, the leader crowned. The page's gender filter and search box
// arrive as props; the viewer's own row is pinned above as "Your standing".
// Players come from the shared roster in StoryFixturesProfile.res.
const ordinal = (p: player) => p.mu - 3 * p.sigma;
const RANKED = [...roster].sort((a, b) => ordinal(b) - ordinal(a));

const edge = (p: player) => ({
  node: {
    id: `rating-${p.id}`,
    ordinal: ordinal(p),
    mu: p.mu,
    user: {
      id: p.id,
      lineUsername: p.lineUsername,
      gender: p.gender,
      picture: p.picture,
      leagueUserStats: { daysNumberOne: p.daysNumberOne },
    },
  },
});

const page = (players: player[], pageInfo: Record<string, unknown> = {}) => ({
  edges: players.map(edge),
  pageInfo: { hasNextPage: false, hasPreviousPage: false, startCursor: null, endCursor: null, ...pageInfo },
});

const meta = {
  title: "Organisms/RatingList",
  component: RatingListStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { ratings: page(RANKED) } } } },
} satisfies Meta<typeof RatingListStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** The whole season loaded: 22 players, men and women together. */
export const Leaderboard: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("All players loaded")).toBeVisible();
    await expect(canvas.getAllByRole("listitem")).toHaveLength(RANKED.length);
  },
};

/** Signed in as a mid-table player: pinned on top, left out of the list. */
export const YourStanding: Story = {
  args: { viewerId: "user-chris" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Your standing")).toBeVisible();
    await expect(canvas.getAllByRole("listitem")).toHaveLength(RANKED.length - 1);
  },
};

/** The Women filter. Ranks keep their place in the full table. */
export const Women: Story = {
  args: { genderFilter: "female" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    // Each row also carries the name in its full-row link, for screen readers.
    await expect((await canvas.findAllByText("Aki"))[0]).toBeVisible();
    await expect(canvas.queryByText("Kenji")).toBeNull();
  },
};

/**
 * The shelved playoff-draft UI (off in the app for now): the top eight of the
 * filtered gender get a Draft badge, with a cutoff line under the eighth.
 */
export const DraftCutoff: Story = {
  args: { genderFilter: "male", showDraftUi: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Draft cutoff · Top 8 qualify")).toBeVisible();
  },
};

/** A search that matches nobody. */
export const NoSearchResults: Story = {
  args: { search: "zzz" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("No players found")).toBeVisible();
    await expect(canvas.getByText("Try broadening your search or filters.")).toBeVisible();
  },
};

/** A league with no rated players yet. */
export const NoPlayers: Story = {
  parameters: { relay: { mocks: { Query: { ratings: page([]) } } } },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("No players found")).toBeVisible();
    await expect(canvas.queryByText("Try broadening your search or filters.")).toBeNull();
  },
};

/**
 * The first page of 20 with more to come. Scrolling to the bottom (or the
 * button) loads the rest in place; the mock answers the `after` page.
 */
export const MorePages: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          ratings: (_: unknown, args: { after?: string | null }) =>
            args.after
              ? page(RANKED.slice(20), { hasPreviousPage: true, startCursor: "cursor-21" })
              : page(RANKED.slice(0, 20), { hasNextPage: true, startCursor: "cursor-1", endCursor: "cursor-20" }),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("button", { name: /Load more players/ })).toBeVisible();
  },
};

/**
 * Opened on a later page (?after= in the URL): a link back up to the higher
 * rated players. Ranks count from the first loaded row, so they start at 1
 * again here.
 */
export const LaterPage: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          ratings: page(RANKED.slice(8), { hasPreviousPage: true, startCursor: "cursor-9", endCursor: "cursor-22" }),
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByRole("link", { name: "...load higher rated players" })).toBeVisible();
  },
};

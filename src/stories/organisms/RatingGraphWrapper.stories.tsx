import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, within } from "storybook/test";
import { make as RatingGraphWrapperStory, playerId, query } from "./RatingGraphWrapperStory.gen";

// The "Rating History" card on a player's league page: the player's rating
// (ordinal, mu - 3 sigma) after each match, with a band for the uncertainty.
// It reads the player's entry in each match's playerMetadata JSON (rating
// before the match plus the change) and renders nothing when there is none.
// The card is not dark-mode aware (white in both themes).
type Step = { at: string; muDiff: number };

/** Match nodes for a run of results, starting from `mu`/`sigma`. */
function matches(steps: Step[], start: { mu: number; sigma: number; sigmaFloor: number }) {
  let { mu, sigma } = start;
  return {
    edges: steps.map(({ at, muDiff }, i) => {
      const nextSigma = Math.max(start.sigmaFloor, sigma * 0.93);
      const metadata = {
        [playerId]: { mu, sigma, muDiff, sigmaDiff: nextSigma - sigma },
        // Partners and opponents are in the payload too; the graph ignores them.
        "user-aki": { mu: 40.1, sigma: 2.3, muDiff: muDiff / 2, sigmaDiff: -0.02 },
        "user-dan": { mu: 39.6, sigma: 2.4, muDiff: -muDiff / 2, sigmaDiff: -0.02 },
      };
      mu += muDiff;
      sigma = nextSigma;
      return { node: { id: `match-${i + 1}`, createdAt: at, playerMetadata: JSON.stringify(metadata) } };
    }),
  };
}

/** Weekly Saturday evenings (19:30 JST), from June into September 2026. */
const saturdays = (n: number) =>
  Array.from({ length: n }, (_, i) => new Date(Date.UTC(2026, 5, 6 + 7 * i, 10, 30)).toISOString());

const climb = [1.9, 1.4, -0.8, 1.6, 1.1, -0.6, 1.2, 0.9, 0.7, -0.9, 0.8, 0.6, 0.5, -0.4, 0.6, 0.3, 0.4, -0.3];
const swings = [0.5, -0.7, -0.6, 0.4, -0.8, -0.5, 0.3, 0.9, 0.7, -0.2, 0.6, 0.5, -0.4, 0.8, -0.3, 0.2];

const meta = {
  title: "Organisms/RatingGraphWrapper",
  component: RatingGraphWrapperStory,
  parameters: {
    relay: {
      query,
      mocks: {
        Query: {
          matches: matches(
            saturdays(climb.length).map((at, i) => ({ at, muDiff: climb[i] })),
            { mu: 25, sigma: 8.33, sigmaFloor: 2.4 },
          ),
        },
      },
    },
  },
  // Recharts draws the line in over 1.5s; wait it out so the story settles
  // (and screenshots show the whole line).
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Rating History")).toBeVisible();
    await new Promise((resolve) => setTimeout(resolve, 1700));
  },
} satisfies Meta<typeof RatingGraphWrapperStory>;

export default meta;
type Story = StoryObj<typeof meta>;

/** A new player's first season: the rating climbs as the band narrows. */
export const NewPlayerClimb: Story = {};

/** An established player: a slump and a recovery inside a narrow band. */
export const EstablishedSwings: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          matches: matches(
            saturdays(swings.length).map((at, i) => ({ at, muDiff: swings[i] })),
            { mu: 38.2, sigma: 2.4, sigmaFloor: 2.2 },
          ),
        },
      },
    },
  },
};

/** Only three rated matches so far. */
export const FewMatches: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          matches: matches(
            saturdays(3).map((at, i) => ({ at, muDiff: [1.8, -0.9, 1.2][i] })),
            { mu: 25, sigma: 8.33, sigmaFloor: 2.4 },
          ),
        },
      },
    },
  },
};

/** Matches without rating data for this player: the card is not rendered at all. */
export const NoRatedMatches: Story = {
  parameters: {
    relay: {
      mocks: {
        Query: {
          matches: {
            edges: saturdays(3).map((at, i) => ({ node: { id: `match-${i + 1}`, createdAt: at, playerMetadata: null } })),
          },
        },
      },
    },
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.queryByText("Rating History")).toBeNull();
  },
};

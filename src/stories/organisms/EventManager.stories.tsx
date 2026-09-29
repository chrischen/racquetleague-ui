import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { make as EventManagerStory, query } from "./EventManagerStory.gen";
import { eventMock } from "./StoryFixturesMatch.gen";

// The organiser's event-day tool (/events/:id/manage): a dark header with the
// save status, Help and the debug toggle; the check-in panel; the draw
// generator (courts, strategy, seed, Generate); then the rounds, each with its
// courts, any seed adjustments made before it and any rules the solver had to
// bend, an "Advance to Round N" button under the active one, and Print Draws /
// Sync Scores at the foot. The evening is restored from the tool's own store,
// which the wrapper fills before mounting: a Thursday night at Shibuya
// Pickleball Club, 20 RSVPs, 16 regulars and two walk-ins checked in, three
// courts, five players yet to pay (StoryFixturesMatch, StoryFixturesSession).
// Stories start from saved rounds rather than pressing Generate, which runs the
// HiGHS solver.
const EVENT = {
  ...eventMock,
  title: "Thursday Night Doubles",
  startDate: "2026-10-15T10:00:00.000Z",
  maxRsvps: null,
  tags: ["comp"],
  activity: { id: "act-pickleball", slug: "pickleball" },
  club: { id: "club-shibuya", name: "Shibuya Pickleball Club" },
};

const meta = {
  title: "Organisms/EventManager",
  component: EventManagerStory,
  parameters: { layout: "fullscreen", relay: { query, mocks: { Query: { event: EVENT } } } },
  argTypes: {
    state: {
      control: "inline-radio",
      options: ["beforeCheckIn", "readyToGenerate", "roundInProgress", "nightFinished"],
    },
  },
  args: { state: "roundInProgress", debug: false },
} satisfies Meta<typeof EventManagerStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// The manager mounts once its store has loaded from IndexedDB, a moment after
// the story renders.
const mounted = { timeout: 5000 };

/** Doors not open yet: nobody checked in, so the panel starts open and Generate waits for players. */
export const BeforeCheckIn: Story = {
  args: { state: "beforeCheckIn" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("0 of 20 checked in", {}, mounted)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Generate" })).toBeDisabled();
  },
};

/** Everyone is here and seeded: 18 checked in (two walk-ins), three courts, ready to generate.
    The check-ins are restored after the first render, and with 18 here the panel folds away. */
export const ReadyToGenerate: Story = {
  args: { state: "readyToGenerate" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("18 of 22 checked in", {}, mounted)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Generate" })).toBeEnabled();
    await waitFor(() => expect(canvas.queryByRole("button", { name: /Add guest/ })).toBeNull());
  },
};

/** Round 2 of 3 in play: round 1 synced, a score on court 1, seed adjustments
    between rounds, and round 3's warning that the walk-ins sit out twice. */
export const RoundInProgress: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("ACTIVE ROUND", {}, mounted)).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Advance to Round 3/ })).toBeVisible();
    await expect(canvas.getByText("Some rules had to be bent to fill the courts")).toBeVisible();
  },
};

/** The last round is in: every court scored, three results still to sync. */
export const NightFinished: Story = {
  args: { state: "nightFinished" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("ACTIVE ROUND", {}, mounted)).toBeVisible();
    await expect(canvas.getByText(/3 to sync/)).toBeVisible();
    await expect(canvas.queryByRole("button", { name: /Advance to Round/ })).toBeNull();
  },
};

/** Debug on: storage use and history export/import in the header, match quality across rounds, μ/σ on players. */
export const DebugView: Story = {
  args: { debug: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Overall Match Quality Across All Rounds", {}, mounted)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Export History" })).toBeEnabled();
  },
};

/** The active round's full-screen TV view, opened from the round header. */
export const FullScreenRound: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByTitle("Full Screen View", {}, mounted));
    // Court 1 already has a score, so two of three courts show who serves.
    await waitFor(() => expect(canvas.getAllByText("SERVING")).toHaveLength(2));
  },
};

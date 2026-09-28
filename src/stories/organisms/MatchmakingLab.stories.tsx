import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fireEvent, userEvent, waitFor, within } from "storybook/test";
import { make as MatchmakingLabStory } from "./MatchmakingLabStory.gen";
import { must } from "../support";

// The matchmaking convergence lab (/matchmaking-lab), a dev tool in its own
// paper-and-ink look (it ignores the app theme). Scenario buttons and sliders
// for players, courts, rounds, tournament squads and seeds sit above Run
// simulation; a strip offers the precomputed runs from public/matchmaking-lab/
// (one is committed: cold start, 24 players, 4 courts, 100 rounds, 7 seeds).
// Once a run is on screen: a transport bar (play, step, reset, round slider),
// the field picker, one button per strategy, then the truth ladder and the
// round's games beside five charts and the standings table. These stories load
// the saved run; none presses Run, which solves thousands of rounds with HiGHS.
const meta = {
  title: "Organisms/MatchmakingLab",
  component: MatchmakingLabStory,
  parameters: { layout: "fullscreen" },
} satisfies Meta<typeof MatchmakingLabStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// The saved run is 1.6 MB gzipped (about 6 MB of JSON), so give it a moment.
const loading = { timeout: 15000 };

const loadSavedRun = async (canvasElement: HTMLElement) => {
  const canvas = within(canvasElement);
  await userEvent.click(await canvas.findByRole("button", { name: /Cold start · 24p · 4 courts/ }, loading));
  await canvas.findByText(/showing a saved run/, {}, loading);
  return canvas;
};

// Moves the round slider (the transport bar's only range input with max = rounds).
const scrubTo = async (canvasElement: HTMLElement, round: number) => {
  const canvas = within(canvasElement);
  const slider = must(canvasElement.querySelector<HTMLInputElement>('input[type="range"][max="100"][min="0"]'), "round slider");
  fireEvent.change(slider, { target: { value: String(round) } });
  await canvas.findByText(`round ${round}/100`);
};

/** Before anything runs: the controls, the saved-runs strip and the prompt to press Run. */
export const BeforeRun: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("saved runs", {}, loading)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Run simulation" })).toBeEnabled();
  },
};

/** The saved run loaded, at round 0: the starting ladder (everyone at the default rating) and empty charts. */
export const SavedRunLoaded: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await loadSavedRun(canvasElement);
    await expect(canvas.getByText("No games yet — press play or step.")).toBeVisible();
  },
};

/** Round 60 of the typical field: games with blowouts and upsets, charts drawn so far, standings over the last 15 rounds. */
export const MidSession: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await loadSavedRun(canvasElement);
    await scrubTo(canvasElement, 60);
    await expect(canvas.getByText("Standings at round 60 · last 15 rounds")).toBeVisible();
  },
};

/** The varied field at round 100, comparing every strategy on the top band, with that band's session totals. */
export const TopBandComparison: Story = {
  play: async ({ canvasElement }) => {
    const canvas = await loadSavedRun(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "varied" }));
    await scrubTo(canvasElement, 100);
    await userEvent.click(canvas.getByRole("button", { name: "top" }));
    await waitFor(() => expect(canvas.getByText(/top players · every strategy/)).toBeVisible());
  },
};

/** A saved run that fails to download: the error line under the strip. The run's URL answers 404 here. */
export const SavedRunFailed: Story = {
  beforeEach: () => {
    const realFetch = window.fetch;
    window.fetch = ((input: RequestInfo | URL, init?: RequestInit) =>
      String(input instanceof Request ? input.url : input).endsWith(".json.gz")
        ? Promise.resolve(new Response("Not Found", { status: 404, statusText: "Not Found" }))
        : realFetch(input, init)) as typeof window.fetch;
    return () => {
      window.fetch = realFetch;
    };
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(await canvas.findByRole("button", { name: /Cold start · 24p · 4 courts/ }, loading));
    await expect(await canvas.findByText(/Could not load the saved run: 404 Not Found/)).toBeVisible();
  },
};

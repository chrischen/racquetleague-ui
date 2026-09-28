import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, waitFor, within } from "storybook/test";
import { make as MatchmakingReportStory } from "./MatchmakingReportStory.gen";
import { must, pending } from "../support";

// "Why you can't get better at rec play, quantified"
// (/why-you-cant-get-better-at-rec-play): an infographic article in serif prose
// with the matchmaking lab's charts inline, six numbered sections, stat rows,
// and a conclusion of five use cases, each with a # link that highlights it
// when the URL hash points at it. It reads the first precomputed run listed in
// public/matchmaking-lab/runs.json, which Storybook serves. The loading and
// failure stories answer that fetch themselves. Its own paper-and-ink look
// ignores the app theme.
const meta = {
  title: "Organisms/MatchmakingReport",
  component: MatchmakingReportStory,
  parameters: {
    layout: "fullscreen",
    router: { path: "why-you-cant-get-better-at-rec-play", url: "/why-you-cant-get-better-at-rec-play" },
  },
} satisfies Meta<typeof MatchmakingReportStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// The run is 1.6 MB gzipped (about 6 MB of JSON).
const loading = { timeout: 15000 };

// Replaces window.fetch for requests to the lab's files; restored afterwards.
const answerLabFetches = (answer: () => Promise<Response>) => () => {
  const realFetch = window.fetch;
  window.fetch = ((input: RequestInfo | URL, init?: RequestInit) =>
    String(input instanceof Request ? input.url : input).includes("/matchmaking-lab/")
      ? answer()
      : realFetch(input, init)) as typeof window.fetch;
  return () => {
    window.fetch = realFetch;
  };
};

/** The whole article, charts drawn from the saved run. */
export const Article: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(await canvas.findByText("Tight skill spread", {}, loading)).toBeVisible();
    await expect(canvas.getByText("Future improvements")).toBeVisible();
  },
};

/** Arriving from a shared link to one use case: that section is highlighted. */
export const LinkedUseCase: Story = {
  beforeEach: () => {
    const { pathname, search, hash } = window.location;
    window.history.replaceState(window.history.state, "", `${pathname}${search}#facility-owners`);
    return () => window.history.replaceState(window.history.state, "", `${pathname}${search}${hash}`);
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await canvas.findByText("Facility owners", {}, loading);
    const section = must(canvasElement.querySelector<HTMLElement>("#facility-owners"), "#facility-owners section");
    // The amber rule down its left edge, a tick after the article mounts.
    await waitFor(() => expect(section).toHaveStyle({ borderLeftColor: "rgb(201, 138, 5)" }));
    section.scrollIntoView({ block: "center" });
  },
};

/** Before the run arrives: the title, standfirst and fact strip, then a loading line. */
export const Loading: Story = {
  beforeEach: answerLabFetches(() => pending<Response>()),
  play: async ({ canvasElement }) => {
    await expect(within(canvasElement).getByText("loading the precomputed run…")).toBeVisible();
  },
};

/** The run could not be fetched: the article says so in place of its body. */
export const LoadFailed: Story = {
  beforeEach: answerLabFetches(() => Promise.resolve(new Response("Not Found", { status: 404, statusText: "Not Found" }))),
  play: async ({ canvasElement }) => {
    await expect(
      await within(canvasElement).findByText(/Could not load the data behind this article: 404 Not Found/),
    ).toBeVisible();
  },
};

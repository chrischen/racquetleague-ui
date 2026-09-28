import * as React from "react";
import type { Decorator, Meta, StoryObj } from "@storybook/react-vite";
import { expect, userEvent, waitFor, within } from "storybook/test";
import { make as KioskStory } from "./KioskStory.gen";

// COURTSIDE.AI, the full-screen courtside camera kiosk: pick a live game or
// an analysis mode, start the camera, then clip rallies, run a Challenge
// (bounce detection by the dinkhunt sidecar) or end an analysis for its
// result. The kiosk takes no props, so each story sets up its surroundings
// and clicks through to a state:
// - camera: "granted" hands out a synthetic court camera (a canvas stream,
//   never a real camera); "denied" and "absent" fail like a browser does;
// - sidecar: a stand-in for localhost:3003 (fixture bounces, or offline), so
//   no story reaches the real analysis server;
// - testMode / courtCalibrated: the kiosk's saved settings in localStorage.
const meta = {
  title: "Organisms/Kiosk",
  component: KioskStory,
  parameters: { layout: "fullscreen" },
  argTypes: {
    camera: { control: "inline-radio", options: ["granted", "denied", "absent"] },
    sidecar: { control: "inline-radio", options: ["online", "offline", "noTestClip", "noBounces"] },
  },
  args: { camera: "granted", sidecar: "online", testMode: false, courtCalibrated: true },
} satisfies Meta<typeof KioskStory>;

export default meta;
type Story = StoryObj<typeof meta>;

type Canvas = ReturnType<typeof within>;

const startLive = async (canvas: Canvas) =>
  userEvent.click(canvas.getByRole("button", { name: /Start live session/ }));

const startAnalysis = async (canvas: Canvas, mode: RegExp) => {
  await userEvent.click(canvas.getByRole("tab", { name: "Analysis" }));
  await userEvent.click(canvas.getByRole("button", { name: mode }));
  await userEvent.click(canvas.getByRole("button", { name: /Start analysis/ }));
  await canvas.findByText("Analysis capture active");
};

// The kiosk logs why a test-mode Challenge found no clip before showing its
// notice. Expected in that story, so exactly that message is muted there.
const muteTestClipLog: Decorator = (Story) => {
  const [restore] = React.useState(() => {
    const original = console.error;
    console.error = (...args: unknown[]) => {
      if (typeof args[0] === "string" && args[0].startsWith("[kiosk] test clip fetch failed")) return;
      original(...args);
    };
    return () => {
      console.error = original;
    };
  });
  React.useEffect(() => restore, [restore]);
  return <Story />;
};

/** The start screen: a live game with the two actions available while playing. */
export const LiveSetup: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("tab", { name: "Live game" })).toHaveAttribute("aria-selected", "true");
    await expect(canvas.getByRole("button", { name: /Start live session/ })).toBeVisible();
  },
};

/** YouTube streaming switched on before starting. */
export const StreamingOn: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    const toggle = canvas.getByRole("switch");
    await userEvent.click(toggle);
    await expect(toggle).toHaveAttribute("aria-checked", "true");
  },
};

/** The Analysis tab with serve speed picked. */
export const AnalysisSetup: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("tab", { name: "Analysis" }));
    const serve = canvas.getByRole("button", { name: /Serve speed analysis/ });
    await userEvent.click(serve);
    await expect(serve).toHaveAttribute("aria-pressed", "true");
  },
};

/** Settings with camera access granted: the connected cameras by name, the
 * processing mode, and test mode. */
export const Settings: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Open kiosk settings" }));
    await expect(await canvas.findByText("Logitech BRIO (046d:085e)")).toBeVisible();
    await expect(canvas.getByText("OBSBOT Tail Air (3564:fef8)")).toBeVisible();
  },
};

/** Before camera permission is granted the browser hides device names, so
 * the picker falls back to numbered cameras. */
export const SettingsBeforePermission: Story = {
  args: { camera: "denied" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Open kiosk settings" }));
    await expect(await canvas.findByText("Camera 1")).toBeVisible();
  },
};

/** No camera connected at all. */
export const SettingsNoCamera: Story = {
  args: { camera: "absent" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Open kiosk settings" }));
    await expect(await canvas.findByText(/No cameras detected/)).toBeVisible();
  },
};

/** Camera permission denied: starting a session only raises a notice. */
export const CameraDenied: Story = {
  args: { camera: "denied" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await expect(await canvas.findByRole("status")).toHaveTextContent(/Camera unavailable/);
  },
};

/** Starting a live session opens court setup over the feed, prefilled with
 * the calibration on file. */
export const CourtSetupOnStart: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await expect(await canvas.findByRole("button", { name: "Confirm court (6 anchored)" })).toBeVisible();
  },
};

/** The live session after court setup: the feed fills the screen and the
 * actions float over it while the rolling buffer fills. */
export const LiveSession: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Skip" }));
    await expect(await canvas.findByText("Rolling buffer active")).toBeVisible();
    // The actions unlock once the buffer holds a couple of seconds.
    const clip = canvas.getByRole("button", { name: /Clip last rally/ });
    await waitFor(() => expect(clip).toBeEnabled(), { timeout: 15000 });
  },
};

/** "Clip last rally" once the buffer holds a couple of seconds: the clip is
 * muxed on the device from the synthetic feed and lands in the history strip;
 * opening it shows the review with Delete, Save and Done. */
export const RallyClipReview: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Skip" }));
    const clip = canvas.getByRole("button", { name: /Clip last rally/ });
    await waitFor(() => expect(clip).toBeEnabled(), { timeout: 15000 });
    await userEvent.click(clip);
    await expect(await canvas.findByText("RECENT CLIPS", {}, { timeout: 15000 })).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: / s · \d\d:\d\d/ }));
    await expect(await canvas.findByRole("button", { name: /Delete clip/ })).toBeVisible();
  },
};

/** Streaming on: the viewer QR code sits beside the feed. */
export const LiveSessionStreaming: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("switch"));
    await startLive(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Skip" }));
    await expect(await canvas.findByText("Scan to watch")).toBeVisible();
  },
};

/** Test mode: no camera; the placeholder court stands in, clipping is off
 * and Challenge runs on the sidecar's fixed test clip. */
export const TestModeSession: Story = {
  args: { testMode: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await expect(await canvas.findByText("CLIPPING UNAVAILABLE")).toBeVisible();
    await expect(canvas.getByRole("button", { name: /Challenge/ })).toBeEnabled();
  },
};

/** A Challenge review: the clip with the shot paths and ground bounces the
 * sidecar found, a timeline marker and a chip per bounce. The clip is the
 * synthetic rally encoded on the fly; the bounces are fixture data. */
export const ChallengeReview: Story = {
  args: { testMode: true },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: /Challenge/ }));
    await expect(await canvas.findByText(/bounces detected/, {}, { timeout: 25000 })).toBeVisible();
    await userEvent.click(canvas.getByRole("button", { name: /^#3/ }));
  },
};

/** A Challenge from the live buffer with the sidecar not running: the
 * buffered clip is still there to review, with the reason analysis failed. */
export const ChallengeSidecarOffline: Story = {
  args: { sidecar: "offline" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: "Skip" }));
    const challenge = canvas.getByRole("button", { name: /Challenge/ });
    await waitFor(() => expect(challenge).toBeEnabled(), { timeout: 15000 });
    await userEvent.click(challenge);
    await expect(
      await canvas.findByText("dinkhunt server unreachable at http://localhost:3003", {}, { timeout: 20000 }),
    ).toBeVisible();
  },
};

/** The sidecar analyzed the clip and found no bounces. */
export const ChallengeNoBounces: Story = {
  args: { testMode: true, sidecar: "noBounces" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: /Challenge/ }));
    await expect(
      await canvas.findByText("No ground bounces were detected in the buffered footage.", {}, { timeout: 25000 }),
    ).toBeVisible();
  },
};

/** Test mode without test_challenge.mov on the sidecar: a notice, and the
 * session carries on. */
export const ChallengeTestClipMissing: Story = {
  args: { testMode: true, sidecar: "noTestClip" },
  decorators: [muteTestClipLog],
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startLive(canvas);
    await userEvent.click(await canvas.findByRole("button", { name: /Challenge/ }));
    await expect(await canvas.findByRole("status")).toHaveTextContent(/Test clip not found/);
  },
};

/** An analysis capture running: the feed with the mode's hint and End & analyze. */
export const AnalysisCapture: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startAnalysis(canvas, /Drop shot analysis/);
    await expect(canvas.getByRole("button", { name: /End & analyze/ })).toBeVisible();
  },
};

/** The drop shot result (still a design mock in the component). */
export const DropShotResult: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startAnalysis(canvas, /Drop shot analysis/);
    await userEvent.click(canvas.getByRole("button", { name: /End & analyze/ }));
    await expect(await canvas.findByText("Drop shot placement", {}, { timeout: 5000 })).toBeVisible();
  },
};

/** The serve speed result (still a design mock in the component). */
export const ServeSpeedResult: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await startAnalysis(canvas, /Serve speed analysis/);
    await userEvent.click(canvas.getByRole("button", { name: /End & analyze/ }));
    await expect(await canvas.findByText("Serve detected", {}, { timeout: 5000 })).toBeVisible();
    await waitFor(() => expect(canvas.getByText("42.8")).toBeVisible());
  },
};

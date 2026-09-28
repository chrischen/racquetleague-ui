import type { Meta, StoryObj } from "@storybook/react-vite";
import { expect, fireEvent, fn, userEvent, waitFor, within } from "storybook/test";
import { make as KioskCourtCalibStory } from "./KioskCourtCalibStory.gen";
import { must } from "../support";

// The kiosk's court-setup overlay: drag four or more reticles onto the court's
// painted marks, the court wireframe re-fits live, and Confirm sends the
// anchors to the analysis sidecar to solve the camera pose. The feed here is a
// synthetic court camera (a canvas stream; no real camera) and the sidecar is
// a stand-in, so Confirm never reaches a real localhost:3003. Anchors come
// from localStorage, as they do after a confirmed setup.
const meta = {
  title: "Organisms/KioskCourtCalib",
  component: KioskCourtCalibStory,
  parameters: { layout: "fullscreen" },
  argTypes: {
    anchors: { control: "inline-radio", options: ["none", "wholeCourt", "kitchenOnly"] },
    sidecar: { control: "inline-radio", options: ["online", "offline", "rejectsCourt"] },
  },
  args: { anchors: "none", sidecar: "online", onDone: fn() },
} satisfies Meta<typeof KioskCourtCalibStory>;

export default meta;
type Story = StoryObj<typeof meta>;

// The overlay's SVG works in native 1080p pixels over the letterboxed video.
const toClient = (svg: Element, x: number, y: number) => {
  const r = svg.getBoundingClientRect();
  const s = Math.min(r.width / 1920, r.height / 1080);
  return { clientX: r.left + (r.width - 1920 * s) / 2 + x * s, clientY: r.top + (r.height - 1080 * s) / 2 + y * s };
};

// A reticle's invisible touch target, found through its label ("FAR L").
const reticle = async (root: HTMLElement, label: string) =>
  waitFor(() => {
    const text = [...root.querySelectorAll("svg text")].find((t) => t.textContent === label);
    const target = text?.parentElement?.querySelector("circle.cursor-grab");
    if (!target) throw new Error(`no reticle ${label}`);
    return target;
  });

const drag = async (root: HTMLElement, label: string, x: number, y: number) => {
  const target = await reticle(root, label);
  const svg = must(root.querySelector("svg"), "calibration overlay");
  const surface = must(svg.parentElement, "overlay surface");
  fireEvent.pointerDown(target);
  fireEvent.pointerMove(surface, toClient(svg, x, y));
  fireEvent.pointerUp(surface);
};

/** First setup: nothing anchored, so every reticle rides the default fit
 * (dashed) and sits off the painted lines; Confirm needs four anchors. */
export const FirstSetup: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByRole("button", { name: "Anchor 4 more" })).toBeDisabled();
  },
};

/** Two far baseline corners dragged onto their painted marks: those two go
 * solid, the rest of the wireframe follows, and the magnifier stays up on the
 * last handle touched. */
export const DraggingHandles: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await drag(canvasElement, "FAR L", 735, 318);
    await drag(canvasElement, "FAR R", 1185, 318);
    await expect(await canvas.findByRole("button", { name: "Anchor 2 more" })).toBeDisabled();
    await expect(canvas.getByRole("button", { name: "Close magnifier" })).toBeVisible();
  },
};

/** A calibration on file (six anchors): the fit sits on the painted court,
 * the dashed box is the analysis region Challenge clips are cropped to, and
 * Confirm solves the pose (answered by the stand-in sidecar). */
export const WholeCourtAnchored: Story = {
  args: { anchors: "wholeCourt" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText("ANALYSIS REGION")).toBeInTheDocument();
    await userEvent.click(canvas.getByRole("button", { name: "Confirm court (6 anchored)" }));
    await waitFor(() => expect(args.onDone).toHaveBeenCalledTimes(1));
  },
};

/** Touching a reticle opens the magnifier: the live frame around the point,
 * pixelated, with the fitted lines and a crosshair; ± steps the zoom. */
export const Magnifier: Story = {
  args: { anchors: "wholeCourt" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    fireEvent.pointerDown(await reticle(canvasElement, "NET R"));
    fireEvent.pointerUp(must(must(canvasElement.querySelector("svg"), "calibration overlay").parentElement, "overlay surface"));
    await userEvent.click(await canvas.findByRole("button", { name: "Zoom in" }));
    await expect(await canvas.findByText(/×12/)).toBeVisible();
  },
};

/** Only the kitchen corners anchored from a close camera: the fit throws the
 * near baseline behind the camera, and the overlay warns before Confirm. */
export const UnstableFit: Story = {
  args: { anchors: "kitchenOnly" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await expect(canvas.getByText(/Fit is unstable/)).toBeVisible();
    await expect(canvas.getByRole("button", { name: "Confirm court (4 anchored)" })).toBeEnabled();
  },
};

/** The sidecar solved the pose and rejected it: its message shows in red and
 * the overlay stays open. */
export const PoseRejected: Story = {
  args: { anchors: "wholeCourt", sidecar: "rejectsCourt" },
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Confirm court (6 anchored)" }));
    await expect(await canvas.findByText(/Pose solve failed/)).toBeVisible();
    await expect(args.onDone).not.toHaveBeenCalled();
  },
};

/** Nothing listening on :3003 (the sidecar isn't running). */
export const SidecarOffline: Story = {
  args: { anchors: "wholeCourt", sidecar: "offline" },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.click(canvas.getByRole("button", { name: "Confirm court (6 anchored)" }));
    await expect(await canvas.findByText("dinkhunt server unreachable at http://localhost:3003")).toBeVisible();
  },
};

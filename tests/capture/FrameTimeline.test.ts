import { describe, expect, it } from "vitest";
import * as FrameTimeline from "../../src/lib/capture/FrameTimeline.re.mjs";

// Labeled args compile positionally: make(frameTimes, fps).

// A camera that runs 30 fps, dips to 20 fps (auto-exposure), then drops two
// frames, then recovers: exactly the shapes that make a uniform "frame/fps"
// clock disagree with the real playback timeline.
const times: number[] = [];
let t = 0;
for (let i = 0; i < 60; i++) { times.push(t); t += 1 / 30; }       // 2 s @30
for (let i = 0; i < 40; i++) { times.push(t); t += 1 / 20; }       // 2 s @20
t += 2 / 30;                                                       // two dropped frames
for (let i = 0; i < 60; i++) { times.push(t); t += 1 / 30; }       // 2 s @30
const fps = 30; // what the server's median-of-first-30 estimate yields
const tl = FrameTimeline.make(times, fps);

describe("FrameTimeline", () => {
  it("maps each real frame time to exactly its analysis time (k / fps)", () => {
    for (let k = 0; k < times.length; k++) {
      expect(FrameTimeline.toAnalysis(tl, times[k])).toBeCloseTo(k / fps, 9);
      expect(FrameTimeline.toVideo(tl, k / fps)).toBeCloseTo(times[k], 9);
      expect(FrameTimeline.frameIndexAt(tl, times[k])).toBe(k);
    }
  });

  it("interpolates between frames and round-trips", () => {
    for (const v of [0.01, 1.234, 2.5, 3.99, 4.3, 5.9]) {
      const a = FrameTimeline.toAnalysis(tl, v);
      expect(FrameTimeline.toVideo(tl, a)).toBeCloseTo(v, 9);
    }
  });

  it("shows the drift a naive overlay would have", () => {
    // During the 20 fps stretch real time runs ahead of frame count: the
    // naive "analysis t = video now" is AHEAD of the true ball.
    const v = times[80]; // 20 frames into the slow stretch
    const naive = v;
    const exact = FrameTimeline.toAnalysis(tl, v);
    expect(naive - exact).toBeGreaterThan(0.3); // > 9 frames of lead
  });

  it("steps land exactly on real frame timestamps", () => {
    const from = times[95] + 0.004; // slightly after frame 95
    expect(FrameTimeline.stepFrames(tl, from, 1)).toBeCloseTo(times[96], 12);
    expect(FrameTimeline.stepFrames(tl, from, -1)).toBeCloseTo(times[94], 12);
    // across the dropped-frame gap
    expect(FrameTimeline.stepFrames(tl, times[99], 1)).toBeCloseTo(times[100], 12);
    // clamps at the ends
    expect(FrameTimeline.stepFrames(tl, times[159], 5)).toBeCloseTo(times[159], 12);
    expect(FrameTimeline.stepFrames(tl, 0, -3)).toBeCloseTo(0, 12);
  });

  it("extrapolates past the last frame with the last interval", () => {
    const last = times[times.length - 1];
    const beyond = FrameTimeline.toAnalysis(tl, last + 1 / 30);
    expect(beyond).toBeCloseTo((times.length - 1 + 1) / fps, 9);
  });

  it("is the identity with no frame table (test clips)", () => {
    const id = FrameTimeline.make([], 30);
    expect(FrameTimeline.toAnalysis(id, 1.234)).toBe(1.234);
    expect(FrameTimeline.toVideo(id, 1.234)).toBe(1.234);
    expect(FrameTimeline.frameIndexAt(id, 1.0)).toBe(30);
    expect(FrameTimeline.stepFrames(id, 1.0, 1)).toBeCloseTo(1 + 1 / 30, 12);
  });
});

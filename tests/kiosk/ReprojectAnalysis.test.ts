import { describe, expect, it } from "vitest";
import * as Kiosk from "../../src/components/organisms/Kiosk.re.mjs";

// reprojectAnalysis(analysis, crop | undefined): shifts server results from
// the cropped clip's pixel space back into the full frame.
const analysis = {
  width: 1430, height: 826, fps: 30,
  bounces: [{ i: 0, t: 1.2, frame: 36, world: [1, 2, 0], pixel: [100.5, 200.25], footprint: [[90, 200], [110, 200], [100, 210]] }],
  paths: [[{ t: 0, x: 10, y: 20 }, { t: 0.033, x: 12, y: 19 }]],
};

describe("Kiosk.reprojectAnalysis", () => {
  it("adds the crop origin to every pixel-space coordinate", () => {
    const out = Kiosk.reprojectAnalysis(analysis, { x: 244, y: 140, width: 1430, height: 826 });
    expect(out.bounces[0].pixel).toEqual([344.5, 340.25]);
    expect(out.bounces[0].footprint).toEqual([[334, 340], [354, 340], [344, 350]]);
    expect(out.paths[0][1]).toEqual({ t: 0.033, x: 256, y: 159 });
    // untouched: times, world metres, frame index
    expect(out.bounces[0].t).toBe(1.2);
    expect(out.bounces[0].world).toEqual([1, 2, 0]);
    expect(out.bounces[0].frame).toBe(36);
  });
  it("is the identity without a crop", () => {
    expect(Kiosk.reprojectAnalysis(analysis, undefined)).toBe(analysis);
  });
});

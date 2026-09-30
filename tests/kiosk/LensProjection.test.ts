import { describe, expect, it } from "vitest";
import * as Calib from "../../src/components/organisms/KioskCourtCalib.re.mjs";
import { readFileSync } from "node:fs";
import { join } from "node:path";

type Camera = { k: number[]; m: number[]; t: number[]; lensK: number[]; k1: number; rmsPx: number };
type Case = {
  label: string;
  camera: Camera;
  anchored: string[];
  expected: Record<string, number[] | null>;
  truth: Record<string, number[]>;
};
const fixture: { width: number; height: number; cases: Case[] } = JSON.parse(
  readFileSync(join(process.cwd(), "tests/kiosk/fixtures/kioskCamera.json"), "utf8"),
);

// lensProject(camera, [x, y]) -> [u, v] | undefined
// lensPolylines(camera, offset, [[ax, ay], [bx, by]]) -> [[u, v], ...][]
// lensSuggestions(fit, placed, nativeW, nativeH) -> string[]
// solvePayload(placed, nativeW, nativeH) -> {width, height, corners, offset}
//
// The fixture's cameras were solved by the analysis server's own code
// (previewKioskCourt, in-process) from a synthetic wide-angle camera with
// barrel distortion; `expected` is the server-side reprojection of every
// landmark and `truth` where that camera really shows them.

const names = Object.keys(fixture.cases[0].truth);

describe("KioskCourtCalib.lensProject (server parity)", () => {
  for (const c of fixture.cases) {
    it(`${c.label}: matches the server's reprojection of every landmark`, () => {
      for (const name of names) {
        const got = Calib.lensProject(c.camera, Calib.worldOf(name));
        const want = c.expected[name];
        if (want === null) {
          expect(got).toBeUndefined();
        } else {
          expect(got[0]).toBeCloseTo(want[0], 6);
          expect(got[1]).toBeCloseTo(want[1], 6);
        }
      }
    });

    it(`${c.label}: inferred (un-anchored) corners land on the real ones`, () => {
      const inferred = names.filter((n) => !c.anchored.includes(n));
      expect(inferred.length).toBeGreaterThan(0);
      for (const name of inferred) {
        const [tx, ty] = c.truth[name];
        if (tx < 0 || ty < 0 || tx >= fixture.width || ty >= fixture.height) continue;
        const [x, y] = Calib.lensProject(c.camera, Calib.worldOf(name));
        expect(Math.hypot(x - tx, y - ty)).toBeLessThan(6);
      }
    });
  }

  it("bends straight court lines (the visual proof of correction)", () => {
    const cam = fixture.cases[0].camera;
    // the near baseline, sampled: its midpoint is off the chord between its ends
    const [run] = Calib.lensPolylines(cam, [0, 0], [[-3.05, 6.705], [3.05, 6.705]]);
    const a = run[0], b = run[run.length - 1], m = run[Math.floor(run.length / 2)];
    const chordDist =
      Math.abs((b[0] - a[0]) * (a[1] - m[1]) - (a[0] - m[0]) * (b[1] - a[1])) / Math.hypot(b[0] - a[0], b[1] - a[1]);
    expect(chordDist).toBeGreaterThan(3);
  });

  it("hides points past barrel fold-back instead of folding them into the frame", () => {
    const cam = { ...fixture.cases[0].camera, k1: -0.3 };
    // far off to the side of the court: well beyond the model's valid radius
    expect(Calib.lensProject(cam, [-60, 0])).toBeUndefined();
    // and a sampled line through that region splits into visible runs only
    const runs = Calib.lensPolylines(cam, [0, 0], [[-60, 0], [0, 0]]);
    for (const run of runs) for (const [x] of run) expect(Number.isFinite(x)).toBe(true);
  });

  it("shifts polylines by the crop offset into the native frame", () => {
    const cam = fixture.cases[0].camera;
    const [plain] = Calib.lensPolylines(cam, [0, 0], [[-3.05, 0], [3.05, 0]]);
    const [shifted] = Calib.lensPolylines(cam, [100, 40], [[-3.05, 0], [3.05, 0]]);
    expect(shifted[0][0] - plain[0][0]).toBeCloseTo(100, 9);
    expect(shifted[0][1] - plain[0][1]).toBeCloseTo(40, 9);
  });
});

describe("KioskCourtCalib lens guidance", () => {
  const W = 1920, H = 1080;
  const truth = fixture.cases[0].truth;
  const place = (...ns: string[]) => ns.map((name) => ({ name, x: truth[name][0], y: truth[name][1] }));
  const corners4 = place("near_baseline_left", "near_baseline_right", "far_baseline_left", "far_baseline_right");

  it("suggests exactly the missing points toward 6, visible and edge-first", () => {
    const fit = Calib.courtFit(corners4, W, H);
    expect(fit.stage).toBe("Perspective");
    const s = Calib.lensSuggestions(fit, corners4, W, H);
    expect(s.length).toBe(Calib.lensAnchorsNeeded - corners4.length);
    for (const name of s) {
      expect(corners4.some((a) => a.name === name)).toBe(false);
      const [x, y] = Calib.handlePosition(fit, corners4, name);
      expect(x).toBeGreaterThan(0.04 * W); expect(x).toBeLessThan(0.96 * W);
      expect(y).toBeGreaterThan(0.04 * H); expect(y).toBeLessThan(0.96 * H);
    }
  });

  it("stops suggesting at 6 anchors and before the full fit", () => {
    const six = place("near_baseline_left", "near_baseline_right", "far_baseline_left", "far_baseline_right", "net_left", "near_kitchen_centre");
    expect(Calib.lensSuggestions(Calib.courtFit(six, W, H), six, W, H)).toEqual([]);
    const three = corners4.slice(0, 3);
    expect(Calib.lensSuggestions(Calib.courtFit(three, W, H), three, W, H)).toEqual([]);
  });

  it("previews exactly what Confirm persists (crop-space payload + offset)", () => {
    const p = Calib.solvePayload(corners4, W, H);
    const crop = Calib.cropRegion(corners4, W, H);
    if (crop) {
      expect([p.width, p.height]).toEqual([crop.width, crop.height]);
      expect(p.offset).toEqual([crop.x, crop.y]);
      expect(p.corners[0].x).toBeCloseTo(corners4[0].x - crop.x, 9);
    } else {
      expect([p.width, p.height, p.offset]).toEqual([W, H, [0, 0]]);
    }
    // the key changes when (and only when) the anchors move
    expect(Calib.payloadKey(p)).toBe(Calib.payloadKey(Calib.solvePayload(corners4, W, H)));
    const moved = corners4.map((a, i) => (i === 0 ? { ...a, x: a.x + 1 } : a));
    expect(Calib.payloadKey(Calib.solvePayload(moved, W, H))).not.toBe(Calib.payloadKey(p));
  });
});

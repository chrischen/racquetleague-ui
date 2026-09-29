import { describe, expect, it } from "vitest";
import * as Calib from "../../src/components/organisms/KioskCourtCalib.re.mjs";

// courtFit(placed, nativeW, nativeH) -> {stage: "Unfitted"|"Affine"|"Perspective", h}
// handlePosition(fit, placed, name) -> [x, y] | undefined

const W = 1920, H = 1080;
const fit = (placed: any[]) => Calib.courtFit(placed, W, H);
const at = (placed: any[], name: string) => Calib.handlePosition(fit(placed), placed, name);

// Where the default (untouched) court puts every handle.
const defaults = Object.fromEntries(
  Calib.anchors.map(([name]: [string]) => [name, at([], name)]),
) as Record<string, [number, number] | undefined>;

// A real-looking placement: an oblique view of the whole court.
const truth: Record<string, [number, number]> = {
  near_baseline_left: [420, 940],
  near_baseline_right: [1480, 930],
  far_baseline_left: [760, 380],
  far_baseline_right: [1190, 376],
  net_left: [600, 560],
  near_kitchen_left: [540, 650],
  near_kitchen_centre: [980, 648],
  near_kitchen_right: [1420, 640],
};
const place = (...names: string[]) => names.map((name) => ({ name, x: truth[name][0], y: truth[name][1] }));

const others = (placed: any[]) =>
  Calib.anchors.map(([n]: [string]) => n).filter((n: string) => !placed.some((a: any) => a.name === n));

describe("KioskCourtCalib staged court fit", () => {
  it("with no anchors, uses the default court", () => {
    expect(fit([]).stage).toBe("Unfitted");
  });

  it("moving the first 1-2 points moves ONLY those points", () => {
    for (const placed of [place("near_baseline_left"), place("near_baseline_left", "far_baseline_right")]) {
      expect(fit(placed).stage).toBe("Unfitted");
      for (const a of placed) expect(at(placed, a.name)).toEqual([a.x, a.y]);
      for (const n of others(placed)) expect(at(placed, n)).toEqual(defaults[n]);
    }
  });

  it("3 points on one court line (a sideline) still move only themselves", () => {
    const placed = place("near_baseline_left", "near_kitchen_left", "net_left");
    expect(fit(placed).stage).toBe("Unfitted");
    for (const n of others(placed)) expect(at(placed, n)).toEqual(defaults[n]);
  });

  it("3 points on one kitchen line also count as colinear", () => {
    const placed = place("near_kitchen_left", "near_kitchen_centre", "near_kitchen_right");
    expect(fit(placed).stage).toBe("Unfitted");
  });

  it("3 non-colinear points establish a (rough) affine fit that moves the rest", () => {
    const placed = place("near_baseline_left", "near_baseline_right", "far_baseline_left");
    const f = fit(placed);
    expect(f.stage).toBe("Affine");
    // an affine fit through 3 points reproduces them exactly
    const project = (name: string) => {
      const p = Calib.projectVisible(f.h, Calib.worldOf(name));
      return p;
    };
    for (const a of placed) {
      const [x, y] = project(a.name);
      expect(x).toBeCloseTo(a.x, 6);
      expect(y).toBeCloseTo(a.y, 6);
    }
    // and the un-anchored handles now ride the fit, not the default court
    expect(at(placed, "far_baseline_right")).not.toEqual(defaults.far_baseline_right);
  });

  it("points that are non-colinear on court but squashed onto a line in the image do not fit", () => {
    const placed = [
      { name: "near_baseline_left", x: 400, y: 900 },
      { name: "near_baseline_right", x: 1400, y: 900 },
      { name: "far_baseline_left", x: 900, y: 902 }, // dragged onto the same image line
    ];
    expect(fit(placed).stage).toBe("Unfitted");
  });

  it("4 points with 3 on one line are only affine (cannot be confirmed)", () => {
    const placed = place("near_kitchen_left", "near_kitchen_centre", "near_kitchen_right", "net_left");
    expect(fit(placed).stage).toBe("Affine");
    expect(Calib.cropRegion(placed, W, H)).toBeUndefined();
  });

  it("4 points in general position give the full perspective fit", () => {
    const placed = place("near_baseline_left", "near_baseline_right", "far_baseline_left", "far_baseline_right");
    const f = fit(placed);
    expect(f.stage).toBe("Perspective");
    for (const a of placed) {
      const [x, y] = Calib.projectVisible(f.h, Calib.worldOf(a.name));
      expect(x).toBeCloseTo(a.x, 3);
      expect(y).toBeCloseTo(a.y, 3);
    }
    expect(Calib.cropRegion(placed, W, H)).toBeDefined();
  });

  it("a mirrored (twisted) quad is not accepted as a perspective fit", () => {
    const placed = place("near_baseline_left", "near_baseline_right", "far_baseline_left", "far_baseline_right");
    // swap the two far corners in the image: the quad is now self-intersecting
    placed[2] = { ...placed[2], x: truth.far_baseline_right[0] };
    placed[3] = { ...placed[3], x: truth.far_baseline_left[0] };
    expect(fit(placed).stage).not.toBe("Perspective");
  });
});

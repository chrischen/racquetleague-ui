import { describe, expect, it } from "vitest";
import * as Calib from "../../src/components/organisms/KioskCourtCalib.re.mjs";

// cropRegion(placed, nativeW, nativeH) -> {x,y,width,height} | undefined

const W = 1920, H = 1080;
// A plausible side-ish view: baselines as a trapezoid well inside the frame.
const trapezoid = [
  { name: "near_baseline_left", x: 400, y: 900 },
  { name: "near_baseline_right", x: 1500, y: 900 },
  { name: "far_baseline_left", x: 700, y: 420 },
  { name: "far_baseline_right", x: 1220, y: 420 },
];

describe("KioskCourtCalib.cropRegion", () => {
  it("wraps the fitted court with headroom, sides and foot margins, even-aligned", () => {
    const r = Calib.cropRegion(trapezoid, W, H);
    expect(r).toBeDefined();
    // even alignment (4:2:0 crop)
    for (const v of [r.x, r.y, r.width, r.height]) expect(v % 2).toBe(0);
    // inside the frame
    expect(r.x).toBeGreaterThanOrEqual(0); expect(r.y).toBeGreaterThanOrEqual(0);
    expect(r.x + r.width).toBeLessThanOrEqual(W); expect(r.y + r.height).toBeLessThanOrEqual(H);
    // contains the court bbox (400..1500 x 420..900) with margins on every side
    expect(r.x).toBeLessThan(400); expect(r.x + r.width).toBeGreaterThan(1500);
    expect(r.y).toBeLessThan(420); expect(r.y + r.height).toBeGreaterThan(900);
    // headroom above is the big margin: at least 40% of the court's height
    expect(420 - r.y).toBeGreaterThanOrEqual(0.4 * 480);
    // and it actually crops something meaningful
    expect(r.width * r.height).toBeLessThan(0.9 * W * H);
  });

  it("needs a full perspective fit (>= 4 anchors)", () => {
    expect(Calib.cropRegion(trapezoid.slice(0, 3), W, H)).toBeUndefined();
  });

  it("skips the crop when the court already fills the frame", () => {
    const full = [
      { name: "near_baseline_left", x: 2, y: 1078 },
      { name: "near_baseline_right", x: 1918, y: 1078 },
      { name: "far_baseline_left", x: 300, y: 2 },
      { name: "far_baseline_right", x: 1620, y: 2 },
    ];
    expect(Calib.cropRegion(full, W, H)).toBeUndefined();
  });

  it("is a pure function of anchors + frame size (calibration and Challenge agree)", () => {
    const a = Calib.cropRegion(trapezoid, W, H);
    const b = Calib.cropRegion([...trapezoid].reverse(), W, H);
    expect(b).toEqual(a);
  });
});

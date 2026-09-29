// The rating graph's Y axis. It used to pad the data by a fixed 50 points
// either side, which on a scale where ratings run 0 to 40 squeezed the line
// into a thin strip. Padding is now a tenth of the data's range, with a
// minimum span so a flat history isn't magnified into noise.
import { describe, expect, it } from "vitest";
import * as RatingGraph from "../../src/components/molecules/RatingGraph.re.mjs";

const { yDomain, minYSpan } = RatingGraph;

const point = (rating: number, sigma: number) => ({
  date: "",
  rating,
  uncertainty: sigma,
  upperBound: rating + 3 * sigma,
  lowerBound: rating,
});

describe("rating graph Y domain", () => {
  it("covers the band and the line with a tenth of the range either side", () => {
    const [lo, hi] = yDomain([point(28, 2.4), point(31, 2.3), point(33, 2.2)]);
    // Data runs 28 (lowest rating) to 33 + 6.6 (highest upper bound).
    const span = 39.6 - 28;
    expect(lo).toBeCloseTo(28 - span / 10);
    expect(hi).toBeCloseTo(39.6 + span / 10);
  });

  it("gives the data most of the chart", () => {
    const data = [point(3.6, 7.7), point(12, 5), point(27, 2.6)];
    const [lo, hi] = yDomain(data);
    const dataSpan = 27 + 7.8 - 3.6;
    expect(dataSpan / (hi - lo)).toBeGreaterThan(0.8);
  });

  it("keeps a minimum span for a flat history", () => {
    const [lo, hi] = yDomain([point(30, 0), point(30, 0)]);
    expect(hi - lo).toBeCloseTo(minYSpan);
    expect((lo + hi) / 2).toBeCloseTo(30);
  });

  it("has a range with no data", () => {
    const [lo, hi] = yDomain([]);
    expect(hi).toBeGreaterThan(lo);
  });
});

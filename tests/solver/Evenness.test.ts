// Match quality is shown as evenness: openskill's draw likelihood over the
// likelihood of a perfectly even game. The raw number's scale has moved once
// already (the 4.1 pin), so everything user-facing goes through this.
import { describe, expect, it } from "vitest";
import * as Rating from "../../src/lib/Rating.re.mjs";
import * as SimLab from "../../src/lib/rating/SimLab.re.mjs";

describe("evenness", () => {
  it("reads 100% for a perfectly even game and less for a stacked one", () => {
    const team = (ids: number[]) => ids.map((i) => ({ intId: i, rating: { mu: 25, sigma: 1 } }));
    const even = SimLab.drawProbability([team([0, 1]), team([2, 3])], [25, 25, 25, 25]);
    expect(SimLab.evenness(even)).toBeCloseTo(1, 9);
    const stacked = SimLab.drawProbability([team([0, 1]), team([2, 3])], [35, 35, 15, 15]);
    expect(SimLab.evenness(stacked)).toBeLessThan(0.5);
  });

  it("never exceeds 100% even when a rating is surer than the draw sigma", () => {
    expect(Rating.evenness(Rating.evenGameDraw * 1.2)).toBe(1);
  });
});

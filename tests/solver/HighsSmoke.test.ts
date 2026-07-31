import { describe, expect, it } from "vitest";
import * as HighsBindings from "../../src/lib/rating/solver/HighsBindings.re.mjs";

describe("HiGHS wasm", () => {
  it("reports availability in this runtime", () => {
    expect(HighsBindings.isAvailable()).toBe(true);
  });

  it("loads and solves a trivial MILP", async () => {
    const highs = await HighsBindings.load();
    expect(highs).not.toBeUndefined();

    const lp = [
      "Minimize",
      " obj: 3 x0 + 5 x1",
      "Subject To",
      " c0: x0 + x1 = 1",
      "Binary",
      " x0 x1",
      "End",
    ].join("\n");

    const result = await HighsBindings.solve(
      highs,
      lp,
      HighsBindings.defaultOptions(1.0, 0),
    );

    expect(result).toBeDefined();
    expect(result.Status).toBe("Optimal");
    expect(result.ObjectiveValue).toBeCloseTo(3, 6);
    expect(result.Columns["x0"].Primal).toBeCloseTo(1, 6);
    expect(result.Columns["x1"].Primal).toBeCloseTo(0, 6);
  }, 30_000);
});

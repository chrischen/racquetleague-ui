import { describe, expect, it } from "vitest";
import * as SolverPrng from "../../src/lib/rating/solver/SolverPrng.re.mjs";

describe("SolverPrng.hashString", () => {
  it("is deterministic", () => {
    expect(SolverPrng.hashString("abc")).toBe(SolverPrng.hashString("abc"));
    expect(SolverPrng.hashString("abc")).not.toBe(SolverPrng.hashString("abd"));
  });

  it("splits UUID-shaped keys roughly evenly by parity", () => {
    // The service indicator derives its side from `hash(entityId) & 1`, so the
    // low bit must be usable as a fair coin over UUID-like inputs.
    let left = 0;
    const total = 400;
    for (let i = 0; i < total; i++) {
      const key = `a1b2c3d4-e5f6-47a8-9b0c-${String(i).padStart(12, "0")}`;
      if ((SolverPrng.hashString(key) & 1) === 0) left += 1;
    }
    expect(left / total).toBeGreaterThan(0.4);
    expect(left / total).toBeLessThan(0.6);
  });
});

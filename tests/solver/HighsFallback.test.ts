// The optimizer must never be a single point of failure: if the wasm cannot be
// loaded, a solver strategy still produces a full set of rounds via the greedy
// engine, and says so.

import { describe, expect, it, vi } from "vitest";

vi.mock("../../src/lib/rating/solver/highsLoader", () => ({
  isAvailable: () => true,
  isLoaded: () => false,
  loadHighs: () => Promise.reject(new Error("simulated wasm load failure")),
}));

const HighsBindings = await import(
  "../../src/lib/rating/solver/HighsBindings.re.mjs"
);
const SolverRounds = await import(
  "../../src/lib/rating/solver/SolverRounds.re.mjs"
);
const SolverRound = await import(
  "../../src/lib/rating/solver/SolverRound.re.mjs"
);
const CostModel = await import("../../src/lib/rating/solver/CostModel.re.mjs");
const SolverPrng = await import("../../src/lib/rating/solver/SolverPrng.re.mjs");
const { makePool, playerIds } = await import("./fixtures");

describe("wasm load failure", () => {
  it("reports the loader as unavailable rather than throwing", async () => {
    expect(await HighsBindings.load()).toBeUndefined();
  });

  it("returns no solver round instead of crashing", async () => {
    const result = await SolverRound.generateRound(
      makePool(8),
      [],
      CostModel.weightsForStrategy("SolverRoundRobin"),
      2,
      SolverPrng.make(1),
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      1.0,
      undefined,
      undefined,
    );
    expect(result).toBeUndefined();
  });

  it("falls back to the greedy engine and flags it", async () => {
    const players = makePool(12, (i) => 20 + i);
    const result = await SolverRounds.generateRounds(
      3,
      players,
      [],
      "SolverRandomBalanced",
      3,
      new Date(0),
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      "fallback",
      1.0,
      undefined,
    );

    expect(result.fellBackToGreedy).toBe(true);
    expect(result.rounds).toHaveLength(3);
    result.rounds.forEach((round: { matches: unknown[]; usedSolver: boolean }) => {
      expect(round.usedSolver).toBe(false);
      expect(round.matches).toHaveLength(3);
    });

    // The greedy rounds are still well-formed: no player double-booked.
    result.rounds.forEach((round: { matches: { match: never }[] }) => {
      const ids = round.matches.flatMap((m) => playerIds(m.match));
      expect(new Set(ids).size).toBe(ids.length);
    });
  }, 60_000);
});

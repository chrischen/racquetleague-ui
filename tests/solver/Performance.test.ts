// Perf characterisation. Timings are logged rather than hard-asserted — CI
// machines vary too much for wall-clock thresholds to be anything but flaky —
// but the shape of the model (candidate count, variable count) is asserted,
// since that is what actually drives solve time.

import { beforeAll, describe, expect, it } from "vitest";
import * as CostModel from "../../src/lib/rating/solver/CostModel.re.mjs";
import * as HighsBindings from "../../src/lib/rating/solver/HighsBindings.re.mjs";
import * as SolverPrng from "../../src/lib/rating/solver/SolverPrng.re.mjs";
import * as SolverRound from "../../src/lib/rating/solver/SolverRound.re.mjs";
import { makePool, playerIds, toRound, type Match, type Round } from "./fixtures";

let highs: unknown;

beforeAll(async () => {
  highs = await HighsBindings.load();
}, 60_000);

// One round of history so the cost model is not trivially uniform.
function seedHistory(players: ReturnType<typeof makePool>, courts: number): Round[] {
  const matches: Match[] = [];
  for (let c = 0; c < courts; c++) {
    const quad = players.slice(c * 4, c * 4 + 4);
    if (quad.length < 4) break;
    matches.push([
      [quad[0], quad[1]],
      [quad[2], quad[3]],
    ]);
  }
  return [toRound(matches)];
}

async function measure(numPlayers: number, courts: number) {
  const players = makePool(numPlayers, (i) => 18 + i * 0.8);
  const rounds = seedHistory(players, courts);
  const args = [
    players,
    rounds,
    CostModel.weightsForStrategy("SolverRandomBalanced"),
    courts,
    SolverPrng.make(1),
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
  ] as const;

  const buildStart = Date.now();
  const prepared = SolverRound.prepare(...args, false, undefined);
  const buildMs = Date.now() - buildStart;

  const start = Date.now();
  const result = await SolverRound.generateRound(...args, 5.0, highs, undefined);
  const totalMs = Date.now() - start;

  return { prepared, result, buildMs, totalMs };
}

describe("solver performance", () => {
  it("stays within the enumeration budget as the pool grows", async () => {
    const rows: string[] = [];
    for (const [numPlayers, courts] of [
      [16, 4],
      [20, 4],
      [24, 6],
      [32, 6],
    ] as const) {
      const { prepared, result, buildMs, totalMs } = await measure(
        numPlayers,
        courts,
      );

      expect(result, `${numPlayers} players produced no round`).toBeDefined();
      expect(result.matches).toHaveLength(Math.min(courts, numPlayers >> 2));

      // No player double-booked, whatever the pruning did.
      const ids = result.matches.flatMap((m: { match: Match }) =>
        playerIds(m.match),
      );
      expect(new Set(ids).size).toBe(ids.length);

      rows.push(
        `  n=${numPlayers} courts=${courts}: ` +
          `${prepared.model.candidates.length} candidates, ` +
          `${prepared.model.numVariables} vars, ` +
          `build ${buildMs}ms, solve ${Math.round(result.solveMs)}ms, ` +
          `total ${totalMs}ms${prepared.pruned ? " (pruned)" : ""}`,
      );
    }
    // eslint-disable-next-line no-console
    console.log(`\n[SolverPerf]\n${rows.join("\n")}\n`);
  }, 300_000);

  it("prunes the enumeration above the threshold and keeps everyone placeable", async () => {
    const { prepared } = await measure(36, 8);
    expect(prepared.pruned).toBe(true);

    // Full enumeration would be C(36,4) * 3 = 176,715 candidates.
    expect(prepared.model.candidates.length).toBeLessThan(100_000);

    // Every player must still appear in enough candidates to be placeable.
    const counts = new Map<string, number>();
    prepared.model.candidates.forEach((c: { match: Match }) =>
      playerIds(c.match).forEach((id) =>
        counts.set(id, (counts.get(id) ?? 0) + 1),
      ),
    );
    expect(counts.size).toBe(36);
    expect(Math.min(...counts.values())).toBeGreaterThanOrEqual(20);
  }, 300_000);

  it("enumerates in full below the threshold, then shortlists the columns", async () => {
    const players = makePool(24, (i) => 18 + i * 0.8);
    const rounds = seedHistory(players, 6);
    const args = [
      players,
      rounds,
      CostModel.weightsForStrategy("SolverRandomBalanced"),
      6,
      SolverPrng.make(1),
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      false,
    ] as const;

    // Enumeration is complete at 24 players — C(24,4) = 10,626 foursomes,
    // three splits each — and the balance toggle then reduces every foursome
    // to its most balanced split(s). So the unfiltered column count sits
    // between one and three per quad, and crucially *every* foursome is still
    // represented: the filter decides how a quad divides, never whether it can
    // play.
    const full = SolverRound.prepare(...args, 0, undefined);
    expect(full.pruned).toBe(false);
    expect(full.model.candidates.length).toBeGreaterThanOrEqual(10626);
    expect(full.model.candidates.length).toBeLessThan(31878);
    const quads = new Set(
      full.model.candidates.map((c: { match: Match }) =>
        playerIds(c.match).sort().join("-"),
      ),
    );
    expect(quads.size).toBe(10626);

    // The solved model is a small shortlist of those columns.
    const shortlisted = SolverRound.prepare(...args, undefined, undefined);
    expect(shortlisted.model.candidates.length).toBeLessThan(2000);
  }, 300_000);

  it("shortlisting does not move the optimum", async () => {
    // The whole justification for shortlisting is that it is free: the reduced
    // model must reach the same optimal objective as the full one.
    for (const [numPlayers, courts] of [
      [16, 4],
      [20, 4],
      [24, 6],
    ] as const) {
      const players = makePool(numPlayers, (i) => 18 + i * 0.8);
      const rounds = seedHistory(players, courts);
      // A fresh PRNG per prepare: the profile carries tie-breaking noise, and a
      // shared stateful PRNG would price the two models differently.
      const args = (prng: unknown) =>
        [
          players,
          rounds,
          CostModel.weightsForStrategy("SolverRandomBalanced"),
          courts,
          prng,
          undefined,
          undefined,
          undefined,
          undefined,
          undefined,
          false,
        ] as const;

      const opts = HighsBindings.defaultOptions(60.0, 0);
      const full = SolverRound.prepare(...args(SolverPrng.make(1)), 0, undefined);
      const short = SolverRound.prepare(...args(SolverPrng.make(1)), undefined, undefined);

      const fullResult = await HighsBindings.solve(highs, full.model.lp, opts);
      const shortResult = await HighsBindings.solve(highs, short.model.lp, opts);

      expect(fullResult.Status).toBe("Optimal");
      expect(shortResult.Status).toBe("Optimal");
      // Both models share the same cost/benefit offsets, because the shortlist
      // always retains each player's cheapest candidate.
      expect(full.model.costOffset).toBe(short.model.costOffset);
      expect(shortResult.ObjectiveValue).toBeCloseTo(
        fullResult.ObjectiveValue,
        6,
      );
    }
  }, 600_000);
});

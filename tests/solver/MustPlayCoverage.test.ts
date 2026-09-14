// The seed round is what keeps the exact-fill model feasible over the
// shortlist, and its guarantee has a hard case: when the players owed a seat
// nearly fill the seats. 23 players on 3 courts is the plain instance — 11 sat
// out last round, 12 seats — and a seed built cheapest-first there could leave
// the model infeasible, sending the round through the slow relaxed model whose
// time budget then decided how many courts were filled.
import { describe, expect, it, beforeAll } from "vitest";
import * as SolverRound from "../../src/lib/rating/solver/SolverRound.re.mjs";
import * as SolverRounds from "../../src/lib/rating/solver/SolverRounds.re.mjs";
import * as SolverPrng from "../../src/lib/rating/solver/SolverPrng.re.mjs";
import * as HighsBindings from "../../src/lib/rating/solver/HighsBindings.re.mjs";
import * as Rating from "../../src/lib/Rating.re.mjs";
import { makePool, playerIds, type Match } from "./fixtures";
import { runSession } from "./sessionSim";

let highs: unknown;
beforeAll(async () => {
  highs = await HighsBindings.load();
});

describe("seed round covers every must-play player", () => {
  it("seats 11 must-plays into 12 seats even when cheap candidates carry few of them", () => {
    const players = makePool(23);
    const mustPlay = players.slice(0, 11).map((p) => p.id);
    const mustSet = new Set(mustPlay);
    const { matches } = SolverRound.enumerateCandidates(players);

    // Adversarial pricing: a candidate costs one per must-play it carries, so
    // the cheapest candidates are exactly the ones that waste seats on others.
    const candidates = matches.map((match: Match) => ({
      match,
      cost: playerIds(match).filter((id) => mustSet.has(id)).length,
      surcharge: 0,
      violations: [],
    }));
    const order = candidates.map((_: unknown, i: number) => i).sort((a: number, b: number) => candidates[a].cost - candidates[b].cost);

    const picked: number[] = SolverRound.seedRound(candidates, order, mustPlay, 3);
    const seated = new Set(picked.flatMap((i) => playerIds(candidates[i].match)));

    expect(picked).toHaveLength(3);
    expect(mustPlay.every((id) => seated.has(id))).toBe(true);
  });

  it("still fills the remaining courts cheapest-first", () => {
    const players = makePool(16);
    const { matches } = SolverRound.enumerateCandidates(players);
    const candidates = matches.map((match: Match, i: number) => ({ match, cost: i, surcharge: 0, violations: [] }));
    const order = candidates.map((_: unknown, i: number) => i);

    const picked: number[] = SolverRound.seedRound(candidates, order, [], 4);

    expect(picked).toHaveLength(4);
    expect(picked[0]).toBe(0);
  });
});

describe("23 players on 3 courts, Competitive+", () => {
  it("fills every court in every round, and never needs the relaxed model", async () => {
    const sim = await runSession({
      numRounds: 24,
      courts: 3,
      strategy: "SolverCompetitivePlus",
      seed: 3,
      numPlayers: 23,
      theta: (i) => 25 + (11 - i) * 0.6,
    });

    expect(sim.fellBackToGreedy).toBe(false);
    expect(sim.rounds.map((r) => r.length)).toEqual(Array(24).fill(3));

    // The exact-fill model must be feasible over the shortlist every round:
    // that is what keeps the time budget out of the court count.
    for (let r = 1; r < sim.rounds.length; r++) {
      const history = sim.rounds.slice(0, r);
      const state = Rating.toPlayerStateWithAdjustments(history, sim.initialPlayers, []);
      const weights = SolverRounds.effectiveWeights("SolverCompetitivePlus", undefined, state, 3);
      const prepared = SolverRound.prepare(
        state, history, weights, 3, SolverPrng.make(7), [], [], [], undefined, undefined, false, undefined,
      );
      expect(prepared.mustPlayIds.length, `round ${r + 1}`).toBe(11);
      const result = await HighsBindings.solve(highs, prepared.model.lp, HighsBindings.defaultOptions(10.0, 0));
      expect(result?.Status, `round ${r + 1}`).not.toBe("Infeasible");
    }
  }, 600_000);
});

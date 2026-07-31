// The key correctness test: for pools small enough to brute-force, the round
// HiGHS returns must be the true argmin of the objective the LP encodes.
//
// The brute force scores selections with `SolverRound.objectiveOfSelection`,
// which reads the very same (already rounded) coefficients the LP carries. So
// this checks the encode/solve/decode chain, not the cost model's taste.

import { beforeAll, describe, expect, it } from "vitest";
import * as CostModel from "../../src/lib/rating/solver/CostModel.re.mjs";
import * as HighsBindings from "../../src/lib/rating/solver/HighsBindings.re.mjs";
import * as SolverPrng from "../../src/lib/rating/solver/SolverPrng.re.mjs";
import * as SolverRound from "../../src/lib/rating/solver/SolverRound.re.mjs";
import {
  makePool,
  playerIds,
  toRound,
  type Match,
  type Player,
  type Round,
} from "./fixtures";

let highs: unknown;

beforeAll(async () => {
  highs = await HighsBindings.load();
}, 60_000);

// Small deterministic RNG so the randomised histories are reproducible.
function rng(seed: number) {
  let s = seed >>> 0 || 1;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

// A few rounds of arbitrary (not necessarily sensible) history, so the cost
// model has partner/opponent/bye state to work with.
function randomHistory(
  players: Player[],
  courts: number,
  numRounds: number,
  next: () => number,
): { rounds: Round[]; players: Player[] } {
  const rounds: Round[] = [];
  let current = players;
  for (let r = 0; r < numRounds; r++) {
    const shuffled = [...current];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(next() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    const matches: Match[] = [];
    for (let c = 0; c < courts; c++) {
      const quad = shuffled.slice(c * 4, c * 4 + 4);
      if (quad.length < 4) break;
      matches.push([
        [quad[0], quad[1]],
        [quad[2], quad[3]],
      ]);
    }
    const round = toRound(matches, r);
    rounds.push(round);
    const played = new Set(round.flatMap(({ match }) => playerIds(match)));
    current = current.map((p) =>
      played.has(p.id) ? { ...p, count: p.count + 1 } : p,
    );
  }
  return { rounds, players: current };
}

// Exhaustive search over every *feasible* set of pairwise-disjoint candidates:
// exactly `matchTarget` of them, covering every player the model hard-constrains
// to play. Anything else is not a solution the LP would accept either.
function bruteForceOptimum(prepared: any): number {
  const candidateIds: string[][] = prepared.model.candidates.map(
    (c: { match: Match }) => playerIds(c.match),
  );
  const target: number = prepared.matchTarget;
  const mustPlay: string[] = prepared.mustPlayIds;
  const used = new Set<string>();
  const selection: number[] = [];
  let best = Infinity;

  const visit = (start: number) => {
    if (selection.length === target) {
      if (mustPlay.every((id) => used.has(id))) {
        const objective = SolverRound.objectiveOfSelection(prepared, [
          ...selection,
        ]);
        if (objective < best) best = objective;
      }
      return;
    }
    for (let i = start; i < candidateIds.length; i++) {
      if (candidateIds[i].some((id) => used.has(id))) continue;
      candidateIds[i].forEach((id) => used.add(id));
      selection.push(i);
      visit(i + 1);
      selection.pop();
      candidateIds[i].forEach((id) => used.delete(id));
    }
  };
  visit(0);
  return best;
}

type Case = {
  players: Player[];
  rounds: Round[];
  courts: number;
  strategy: string;
  requiredPlayerIds?: string[];
  avoidAllPlayers?: Player[][];
  teamConstraints?: Set<string>[];
};

async function assertOptimal(testCase: Case, label: string) {
  // Noise off: this suite checks that encode -> solve -> decode reproduces the
  // brute-force optimum of the *same* coefficients. The test's own `prepare`
  // and the one inside `generateRound` draw from PRNGs in different states, so
  // a noisy profile would give the two models different (equally valid)
  // objectives and the comparison would be meaningless.
  const weights = { ...CostModel.weightsForStrategy(testCase.strategy), wNoise: 0 };
  const args = [
    testCase.players,
    testCase.rounds,
    weights,
    testCase.courts,
    SolverPrng.make(11),
    testCase.avoidAllPlayers,
    testCase.teamConstraints,
    testCase.requiredPlayerIds,
    undefined,
    undefined,
  ] as const;

  const prepared = SolverRound.prepare(...args, false, undefined);
  const result = await SolverRound.generateRound(
    ...args,
    5.0,
    highs,
    undefined,
  );

  expect(result, `${label}: no solution`).toBeDefined();
  expect(result.status).toBe("Optimal");

  const optimum = bruteForceOptimum(prepared);
  expect(result.objective, `${label}: not the brute-force optimum`).toBeCloseTo(
    optimum,
    6,
  );
}

describe("solver exactness", () => {
  it("matches the brute-force optimum across 50 randomised histories", async () => {
    for (let seed = 1; seed <= 50; seed++) {
      const next = rng(seed);
      const base = makePool(8, () => 20 + Math.floor(next() * 20));
      const { rounds, players } = randomHistory(
        base,
        2,
        1 + Math.floor(next() * 3),
        next,
      );
      const strategy = ["SolverRoundRobin", "SolverRandomBalanced", "SolverCompetitivePlus"][
        seed % 3
      ];
      await assertOptimal(
        { players, rounds, courts: 2, strategy },
        `seed ${seed} (${strategy})`,
      );
    }
  }, 300_000);

  it("matches the brute-force optimum with constraints active", async () => {
    const players = makePool(8, (i) => 20 + i * 2);
    const { rounds } = randomHistory(players, 2, 2, rng(99));

    await assertOptimal(
      {
        players,
        rounds,
        courts: 2,
        strategy: "SolverRandomBalanced",
        // Deliberately over-constrained: p0 and p1 cannot share a court, and
        // p2/p3/p4 may only partner within their own pool.
        avoidAllPlayers: [[players[0], players[1]]],
        teamConstraints: [new Set(["p2", "p3", "p4"])],
        requiredPlayerIds: ["p7"],
      },
      "constrained",
    );
  }, 120_000);

  it("matches the brute-force optimum on 12 players and 3 courts", async () => {
    for (const seed of [3, 17]) {
      const next = rng(seed);
      const base = makePool(12, () => 18 + Math.floor(next() * 24));
      const { rounds, players } = randomHistory(base, 3, 2, next);
      await assertOptimal(
        { players, rounds, courts: 3, strategy: "SolverCompetitivePlus" },
        `12p seed ${seed}`,
      );
    }
  }, 300_000);
});

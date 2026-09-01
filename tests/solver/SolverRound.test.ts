import { beforeAll, describe, expect, it } from "vitest";
import * as CostModel from "../../src/lib/rating/solver/CostModel.re.mjs";
import * as HighsBindings from "../../src/lib/rating/solver/HighsBindings.re.mjs";
import * as SolverPrng from "../../src/lib/rating/solver/SolverPrng.re.mjs";
import * as SolverRound from "../../src/lib/rating/solver/SolverRound.re.mjs";
import {
  applyRound,
  makePool,
  matchPlayers,
  pairKey,
  playerIds,
  teamKey,
  toRound,
  type Match,
  type Player,
  type Round,
} from "./fixtures";

let highs: unknown;

beforeAll(async () => {
  highs = await HighsBindings.load();
}, 60_000);

type SolveOpts = {
  players: Player[];
  rounds?: Round[];
  strategy?: string;
  courts: number;
  seed?: number;
  avoidAllPlayers?: Player[][];
  teamConstraints?: Set<string>[];
  requiredPlayerIds?: string[];
  priorityPlayerIds?: string[];
  genderMixed?: boolean;
};

async function solveRound(opts: SolveOpts) {
  const weights = CostModel.weightsForStrategy(opts.strategy ?? "SolverRoundRobin");
  const prng = SolverPrng.make(opts.seed ?? 1);
  return await SolverRound.generateRound(
    opts.players,
    opts.rounds ?? [],
    weights,
    opts.courts,
    prng,
    opts.avoidAllPlayers,
    opts.teamConstraints,
    opts.requiredPlayerIds,
    opts.priorityPlayerIds,
    opts.genderMixed,
    5.0,
    highs,
    undefined,
  );
}

// Play out `n` rounds, feeding each result back in as history.
async function playSession(
  opts: SolveOpts & { numRounds: number },
): Promise<{ rounds: Round[]; results: any[] }> {
  let players = opts.players;
  const rounds: Round[] = [];
  const results: any[] = [];
  for (let r = 0; r < opts.numRounds; r++) {
    const result = await solveRound({ ...opts, players, rounds, seed: r + 1 });
    expect(result, `round ${r} produced no solution`).toBeDefined();
    results.push(result);
    const round = toRound(
      result.matches.map((m: { match: Match }) => m.match),
      r,
    );
    rounds.push(round);
    players = applyRound(players, round);
  }
  return { rounds, results };
}

describe("SolverRound", () => {
  it("fills every court with disjoint matches", async () => {
    const result = await solveRound({ players: makePool(16), courts: 4 });

    expect(result.matches).toHaveLength(4);
    const ids = result.matches.flatMap((m: { match: Match }) =>
      playerIds(m.match),
    );
    expect(new Set(ids).size).toBe(16);
    expect(result.byePlayerIds).toHaveLength(0);
    expect(result.roundViolations).toHaveLength(0);
    result.matches.forEach((m: { fallbackReasons: unknown[] }) =>
      expect(m.fallbackReasons).toHaveLength(0),
    );
  });

  it("leaves courts unfilled only when fewer than 4 players remain", async () => {
    // 7 players, 2 courts: one court can be filled, the other cannot.
    const result = await solveRound({ players: makePool(7), courts: 2 });
    expect(result.matches).toHaveLength(1);
    expect(result.byePlayerIds).toHaveLength(3);
  });

  it("returns no round when the pool is too small", async () => {
    expect(await solveRound({ players: makePool(3), courts: 1 })).toBeUndefined();
  });

  it("is deterministic for identical inputs", async () => {
    const players = makePool(12, (i) => 20 + i);
    const a = await solveRound({ players, courts: 3, seed: 42 });
    const b = await solveRound({ players, courts: 3, seed: 42 });
    expect(a.matches.map((m: { match: Match }) => teamKey(m.match[0]))).toEqual(
      b.matches.map((m: { match: Match }) => teamKey(m.match[0])),
    );
  });

  it("produces no repeated partners over a whist-bound session with rated players", async () => {
    // The flat-pool whist test below masks a starvation bug: with real
    // ratings, "the two strongest together" is almost never a foursome's most
    // balanced split, so a balance rule that outranks novelty makes some
    // partnerships permanently unreachable and forces repeats while fresh
    // pairs remain. Balance must yield to variety, then break ties.
    const { rounds } = await playSession({
      players: makePool(8, (i) => 20 + i * 2),
      courts: 2,
      numRounds: 7,
      strategy: "SolverRoundRobin",
    });

    const partnerCounts = new Map<string, number>();
    rounds.forEach((round) =>
      round.forEach(({ match }) =>
        [match[0], match[1]].forEach((team) => {
          const key = pairKey(team[0].id, team[1].id);
          partnerCounts.set(key, (partnerCounts.get(key) ?? 0) + 1);
        }),
      ),
    );
    expect(partnerCounts.size).toBe(28);
    expect([...partnerCounts.values()].every((c) => c === 1)).toBe(true);
  }, 180_000);

  it("produces no repeated partners over a whist-bound session", async () => {
    // 8 players / 2 courts: each player has 7 possible partners, so 7 rounds
    // can be played with zero repeats.
    const { rounds } = await playSession({
      players: makePool(8),
      courts: 2,
      numRounds: 7,
    });

    const partnerCounts = new Map<string, number>();
    rounds.forEach((round) =>
      round.forEach(({ match }) =>
        [match[0], match[1]].forEach((team) => {
          const key = pairKey(team[0].id, team[1].id);
          partnerCounts.set(key, (partnerCounts.get(key) ?? 0) + 1);
        }),
      ),
    );

    expect(partnerCounts.size).toBe(28);
    expect([...partnerCounts.values()].every((c) => c === 1)).toBe(true);
  }, 120_000);

  it("rotates byes so play counts stay within one game", async () => {
    const players = makePool(12);
    const { rounds } = await playSession({ players, courts: 2, numRounds: 6 });

    const counts = new Map<string, number>(players.map((p) => [p.id, 0]));
    rounds.forEach((round) =>
      round.forEach(({ match }) =>
        playerIds(match).forEach((id) => counts.set(id, counts.get(id)! + 1)),
      ),
    );
    const values = [...counts.values()];
    expect(Math.max(...values) - Math.min(...values)).toBeLessThanOrEqual(1);
  }, 120_000);

  it("never gives a back-to-back bye when seats allow", async () => {
    // 12 players / 2 courts: 4 sit each round, and 4 <= 8 seats, so nobody
    // ever needs to sit twice running.
    const players = makePool(12);
    const { rounds } = await playSession({ players, courts: 2, numRounds: 8 });

    let backToBack = 0;
    for (let r = 1; r < rounds.length; r++) {
      const prev = new Set(rounds[r - 1].flatMap(({ match }) => playerIds(match)));
      const curr = new Set(rounds[r].flatMap(({ match }) => playerIds(match)));
      players.forEach((p) => {
        if (!prev.has(p.id) && !curr.has(p.id)) backToBack++;
      });
    }
    expect(backToBack).toBe(0);
  }, 120_000);

  it("reports every forced back-to-back bye when seats do not allow", async () => {
    // 20 players / 2 courts: 12 sit each round but only 8 can play, so at
    // least 4 players must sit twice running.
    const players = makePool(20);
    const first = await solveRound({ players, courts: 2 });
    const round0 = toRound(
      first.matches.map((m: { match: Match }) => m.match),
      0,
    );
    const second = await solveRound({
      players: applyRound(players, round0),
      rounds: [round0],
      courts: 2,
      seed: 2,
    });

    const played = new Set(
      second.matches.flatMap((m: { match: Match }) => playerIds(m.match)),
    );
    const satBoth = players.filter(
      (p) =>
        !round0.some(({ match }) => playerIds(match).includes(p.id)) &&
        !played.has(p.id),
    );
    expect(satBoth.length).toBeGreaterThan(0);

    const reported = new Set(
      second.roundViolations
        .filter((v: { TAG: string }) => v.TAG === "BackToBackBye")
        .map((v: { playerId: string }) => v.playerId),
    );
    satBoth.forEach((p) => expect(reported.has(p.id)).toBe(true));
  }, 60_000);

  it("avoids pairing the strongest player with the weakest", async () => {
    // Sum-balance alone would love [40, 20] vs [30, 30]; the spread term is
    // what stops it. A zero-spread alternative round exists here.
    const mus = [40, 30, 30, 20, 30, 30, 30, 30];
    const players = makePool(8, (i) => mus[i]);

    for (const strategy of [
      "SolverRoundRobin",
      "SolverRandomBalanced",
      "SolverCompetitivePlusStatic",
    ]) {
      const result = await solveRound({ players, courts: 2, strategy });
      result.matches.forEach((m: { match: Match }) => {
        const ids = playerIds(m.match);
        expect(
          ids.includes("p0") && ids.includes("p3"),
          `${strategy} put the strongest and weakest on the same court`,
        ).toBe(false);
      });
    }
  }, 60_000);

  // The three presets are use cases, not points on one slider axis:
  //   Round Robin      — novelty first; ties break like Competitive+ ("start
  //                      competitive until variety forces mixing"); splits
  //                      balanced.
  //   Random Balanced  — novelty first; skill-blind composition with jitter;
  //                      splits balanced.
  //   Competitive+     — quality first: spread tuned to max (tight bands),
  //                      splits balanced.
  const rankedPool = () => makePool(20, (i) => 40 - i * 1.2); // p0 strongest
  const rankOf = (id: string) => Number(id.slice(1));
  const meanCourtSpan = (matches: { match: Match }[]) =>
    matches
      .map((m) => playerIds(m.match).map(rankOf))
      .reduce((a, ranks) => a + (Math.max(...ranks) - Math.min(...ranks)), 0) /
    matches.length;
  // With the balance toggle on, every match's split must be the most balanced
  // of its foursome's three — exactly, since the filter is hard.
  const expectBalancedSplits = (matches: { match: Match }[]) =>
    matches.forEach((m) => {
      const quad = matchPlayers(m.match);
      const sum = (xs: Player[]) => xs.reduce((a, p) => a + p.rating.mu, 0);
      const [a, b, c, d] = quad;
      const gaps = [
        Math.abs(sum([a, b]) - sum([c, d])),
        Math.abs(sum([a, c]) - sum([b, d])),
        Math.abs(sum([a, d]) - sum([b, c])),
      ];
      const chosen = Math.abs(sum(m.match[0]) - sum(m.match[1]));
      expect(chosen).toBeLessThanOrEqual(Math.min(...gaps) + 1e-6);
    });

  it("Round Robin starts competitive and mixes as the bands exhaust", async () => {
    const players = rankedPool();
    const { rounds } = await playSession({
      players,
      courts: 5,
      strategy: "SolverRoundRobin",
      numRounds: 6,
    });
    const spanOf = (round: Round) =>
      meanCourtSpan(round.map(({ match }) => ({ match })));

    // No novelty pressure yet, so the first draw is banded like Competitive+.
    expect(spanOf(rounds[0])).toBeLessThan(8);
    // A band of four exhausts its partner combinations in three rounds, so
    // later rounds are forced to mix across bands.
    const late = (spanOf(rounds[4]) + spanOf(rounds[5])) / 2;
    expect(late).toBeGreaterThan(spanOf(rounds[0]));

    // Throughout: the round-robin contract (no repeated partnerships) and
    // balanced splits (the toggle is a hard filter).
    // Splits are variety-first: fresh partnerships beat balance, and balance
    // breaks ties among the freshest splits. Verify against the running
    // partnership history.
    const partnerCounts = new Map<string, number>();
    const pairCount = (a: Player, b: Player) =>
      partnerCounts.get(pairKey(a.id, b.id)) ?? 0;
    rounds.forEach((round) => {
      round.forEach(({ match }) => {
        const [a, b, c, d] = [...match[0], ...match[1]];
        const sum = (xs: Player[]) => xs.reduce((x, p) => x + p.rating.mu, 0);
        const splits: [Player[], Player[]][] = [
          [[a, b], [c, d]],
          [[a, c], [b, d]],
          [[a, d], [b, c]],
        ];
        const repeats = splits.map(
          ([t1, t2]) => pairCount(t1[0], t1[1]) + pairCount(t2[0], t2[1]),
        );
        const minRepeats = Math.min(...repeats);
        const bestGap = Math.min(
          ...splits
            .filter((_, i) => repeats[i] === minRepeats)
            .map(([t1, t2]) => Math.abs(sum(t1) - sum(t2))),
        );
        expect(pairCount(match[0][0], match[0][1]) + pairCount(match[1][0], match[1][1])).toBe(
          minRepeats,
        );
        expect(Math.abs(sum(match[0]) - sum(match[1]))).toBeLessThanOrEqual(bestGap + 1e-6);
      });
      round.forEach(({ match }) =>
        [match[0], match[1]].forEach((team) => {
          const key = pairKey(team[0].id, team[1].id);
          partnerCounts.set(key, (partnerCounts.get(key) ?? 0) + 1);
        }),
      );
    });
    expect(Math.max(...partnerCounts.values())).toBe(1);
  }, 180_000);

  it("Random Balanced mixes the courts and balances each match's split", async () => {
    const players = rankedPool();
    const result = await solveRound({
      players,
      courts: 5,
      strategy: "SolverRandomBalanced",
    });
    expect(meanCourtSpan(result.matches)).toBeGreaterThan(8);
    expectBalancedSplits(result.matches);
  }, 60_000);

  it("Competitive+ bands the courts by skill", async () => {
    const result = await solveRound({
      players: rankedPool(),
      courts: 5,
      strategy: "SolverCompetitivePlusStatic",
    });
    expect(meanCourtSpan(result.matches)).toBeLessThan(8);
    expectBalancedSplits(result.matches);
  }, 60_000);

  it("randomizes Random Balanced matchups across seeds", async () => {
    // "Random means random": composition must vary with the seed. (Court
    // *order* per strategy is covered in SolverRounds tests, where the
    // dispatch lives.)
    const players = makePool(16, (i) => 40 - i * 1.5);
    const partitions = new Set<string>();
    for (let seed = 1; seed <= 6; seed++) {
      const result = await solveRound({
        players,
        courts: 4,
        strategy: "SolverRandomBalanced",
        seed,
      });
      partitions.add(
        result.matches
          .map((m: { match: Match }) => playerIds(m.match).sort().join(","))
          .sort()
          .join("/"),
      );
    }
    expect(partitions.size).toBeGreaterThan(1);
  }, 120_000);

  it("rotates Competitive+ byes as skill cohorts", async () => {
    // Legacy behaviour, restored: the strongest players go onto the court
    // first among fairness ties, so each round's bye set is the bottom band
    // of the eligible cohort — bands play together and break together,
    // instead of individuals alternating out of phase with their band.
    const players = makePool(20, (i) => 40 - i * 1.2); // p0 strongest
    const rankOf = (id: string) => Number(id.slice(1));
    const { rounds } = await playSession({
      players,
      courts: 4,
      strategy: "SolverCompetitivePlusStatic",
      numRounds: 5,
    });

    const byeRanges: number[] = [];
    rounds.forEach((round) => {
      const playing = new Set(round.flatMap(({ match }) => playerIds(match)));
      const byeRanks = players
        .filter((p) => !playing.has(p.id))
        .map((p) => rankOf(p.id));
      expect(byeRanks).toHaveLength(4);
      byeRanges.push(Math.max(...byeRanks) - Math.min(...byeRanks));
    });
    // Skill-coherent byes: a band of four spans 3 ranks; a skill-blind draw
    // averages ~12 of 20. Allow slack for fairness constraints interleaving.
    const meanRange = byeRanges.reduce((a, b) => a + b, 0) / byeRanges.length;
    expect(meanRange).toBeLessThanOrEqual(6);

    // And cohort ordering never traded a game: counts stay within one.
    const counts = new Map(players.map((p) => [p.id, 0]));
    rounds.forEach((round) =>
      round.forEach(({ match }) =>
        playerIds(match).forEach((id) => counts.set(id, counts.get(id)! + 1)),
      ),
    );
    const values = [...counts.values()];
    expect(Math.max(...values) - Math.min(...values)).toBeLessThanOrEqual(1);
  }, 180_000);

  it("seats a required player", async () => {
    const players = makePool(12);
    const result = await solveRound({
      players,
      courts: 2,
      requiredPlayerIds: ["p11"],
    });
    const seated = new Set(
      result.matches.flatMap((m: { match: Match }) => playerIds(m.match)),
    );
    expect(seated.has("p11")).toBe(true);
    expect(result.roundViolations).toHaveLength(0);
  });
});

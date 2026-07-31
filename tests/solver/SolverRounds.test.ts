import { describe, expect, it } from "vitest";
import * as SolverRounds from "../../src/lib/rating/solver/SolverRounds.re.mjs";
import { applyRound, makePool, playerIds, type Match, type Player } from "./fixtures";

type Outcome = {
  matches: { id: string; match: Match }[];
  matchViolations: Record<string, unknown[]>;
  roundViolations: unknown[];
  byePlayerIds: string[];
  usedSolver: boolean;
};

function generate(opts: {
  numberOfRounds: number;
  players: Player[];
  courts: number;
  strategy: string;
  seed?: string;
  weightConfig?: unknown;
}): Promise<{ rounds: Outcome[]; fellBackToGreedy: boolean }> {
  return SolverRounds.generateRounds(
    opts.numberOfRounds,
    opts.players,
    [],
    opts.strategy,
    opts.courts,
    new Date(0),
    opts.weightConfig,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    opts.seed ?? "test",
    5.0,
    undefined,
  );
}

describe("SolverRounds", () => {
  it("generates solver rounds for a solver strategy", async () => {
    const result = await generate({
      numberOfRounds: 4,
      players: makePool(12, (i) => 20 + i),
      courts: 3,
      strategy: "SolverRandomBalanced",
    });

    expect(result.fellBackToGreedy).toBe(false);
    expect(result.rounds).toHaveLength(4);
    result.rounds.forEach((round) => {
      expect(round.usedSolver).toBe(true);
      expect(round.matches).toHaveLength(3);
      // Distinct ids, so match-level violations can be keyed on them.
      expect(new Set(round.matches.map((m) => m.id)).size).toBe(3);
    });
  }, 120_000);

  it("carries play counts forward between rounds", async () => {
    const players = makePool(10);
    const result = await generate({
      numberOfRounds: 5,
      players,
      courts: 2,
      strategy: "SolverRoundRobin",
    });

    const counts = new Map(players.map((p) => [p.id, 0]));
    result.rounds.forEach((round) =>
      round.matches.forEach(({ match }) =>
        playerIds(match).forEach((id) => counts.set(id, counts.get(id)! + 1)),
      ),
    );
    const values = [...counts.values()];
    expect(values.reduce((a, b) => a + b, 0)).toBe(5 * 8);
    expect(Math.max(...values) - Math.min(...values)).toBeLessThanOrEqual(1);
  }, 120_000);

  it("embeds play counts that include the current match, like the greedy engine", async () => {
    // The play-count chip on a match card renders the count *stored in the
    // match entity*. The greedy engine stores players with the current match
    // already counted (`incrementPlayCounts`); the solver path must match, or
    // solver rounds display one game behind — and a legacy-path rebalance of a
    // single court then "fixes" just that court, which is how the discrepancy
    // was spotted.
    for (const strategy of ["SolverRoundRobin", "NoveltyRoundRobin"]) {
      const result = await generate({
        numberOfRounds: 2,
        players: makePool(8),
        courts: 2,
        strategy,
      });
      result.rounds.forEach((round, roundIndex) =>
        round.matches.forEach(({ match }) =>
          [...match[0], ...match[1]].forEach((p: { count: number }) =>
            // Pool entered round r with r games played; stored count adds one.
            expect(p.count).toBe(roundIndex + 1),
          ),
        ),
      );
    }
  }, 120_000);

  it("reproduces the same draw for the same seed", async () => {
    const players = makePool(12, (i) => 20 + i);
    const key = (r: { rounds: Outcome[] }) =>
      r.rounds.map((round) =>
        round.matches
          .map(({ match }) => playerIds(match).sort().join())
          .sort()
          .join("|"),
      );

    const a = await generate({
      numberOfRounds: 3,
      players,
      courts: 3,
      strategy: "SolverRoundRobin",
      seed: "abc",
    });
    const b = await generate({
      numberOfRounds: 3,
      players,
      courts: 3,
      strategy: "SolverRoundRobin",
      seed: "abc",
    });
    expect(key(a)).toEqual(key(b));
  }, 120_000);

  it("single-round regeneration reproduces the round the block generated", async () => {
    // The canonical-reset property: with a shared seed string (free of the
    // block's starting index), resetting round r against the same state feeds
    // the identical PRNG stream and reproduces the block's round r exactly.
    const players = makePool(12, (i) => 20 + i);
    const seed = "evt:7";
    const block = await generate({
      numberOfRounds: 3,
      players,
      courts: 3,
      strategy: "SolverRoundRobin",
      seed,
    });
    const target = 2;
    const stored = block.rounds.map((r) => r.matches);

    // Player state as it stood when the block generated round 2: counts
    // advanced through rounds 0 and 1.
    let advanced = players;
    for (let r = 0; r < target; r++) {
      advanced = applyRound(advanced, stored[r]);
    }

    const reset = await SolverRounds.generateSingleRound(
      target,
      stored,
      advanced,
      "SolverRoundRobin",
      3,
      new Date(0),
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      seed,
      5.0,
      undefined,
    );

    const key = (matches: { match: Match }[]) =>
      matches
        .map(({ match }) =>
          [match[0], match[1]]
            .map((t) => t.map((p) => p.id).sort().join("-"))
            .sort()
            .join("|"),
        )
        .sort()
        .join(" / ");
    expect(key(reset.matches)).toBe(key(stored[target]));

    // Idempotent: a second reset changes nothing.
    const again = await SolverRounds.generateSingleRound(
      target,
      stored,
      advanced,
      "SolverRoundRobin",
      3,
      new Date(0),
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      seed,
      5.0,
      undefined,
    );
    expect(key(again.matches)).toBe(key(stored[target]));
  }, 120_000);

  it("orders courts strongest-first for Round Robin and Competitive+", async () => {
    // Round Robin bands first and Competitive+ is leveled by definition, so
    // for both, court numbers mean something: court 1 is the strongest court.
    const players = makePool(20, (i) => 40 - i * 1.2);
    const strength = (m: { match: Match }) =>
      [...m.match[0], ...m.match[1]].reduce((a, p) => a + p.rating.mu, 0);

    for (const strategy of ["SolverRoundRobin", "SolverCompetitivePlus"]) {
      const result = await generate({
        numberOfRounds: 1,
        players,
        courts: 5,
        strategy,
      });
      const strengths = result.rounds[0].matches.map(strength);
      for (let i = 1; i < strengths.length; i++) {
        expect(strengths[i]).toBeLessThanOrEqual(strengths[i - 1]);
      }
    }
  }, 120_000);

  it("shuffles Random Balanced court order per seed", async () => {
    // The one mode that must *look* random: the strongest court must not sit
    // at court 1 on every seed (candidate decode order pinned the first-listed
    // player there before the seeded arrangement existed).
    const players = makePool(20, (i) => 40 - i * 1.2);
    const strength = (m: { match: Match }) =>
      [...m.match[0], ...m.match[1]].reduce((a, p) => a + p.rating.mu, 0);

    const topCourtIndex: number[] = [];
    for (const seed of ["a", "b", "c", "d", "e", "f"]) {
      const result = await generate({
        numberOfRounds: 1,
        players,
        courts: 5,
        strategy: "SolverRandomBalanced",
        seed,
      });
      const strengths = result.rounds[0].matches.map(strength);
      topCourtIndex.push(strengths.indexOf(Math.max(...strengths)));
    }
    expect(new Set(topCourtIndex).size).toBeGreaterThan(1);
  }, 120_000);

  it("delegates legacy strategies to the greedy engine untouched", async () => {
    const result = await generate({
      numberOfRounds: 3,
      players: makePool(12, (i) => 20 + i),
      courts: 3,
      strategy: "NoveltyRoundRobin",
    });

    expect(result.fellBackToGreedy).toBe(false);
    expect(result.rounds).toHaveLength(3);
    result.rounds.forEach((round) => {
      expect(round.usedSolver).toBe(false);
      expect(round.matches).toHaveLength(3);
      expect(round.matchViolations).toEqual({});
    });
  }, 60_000);

  it("applies a stored weight config over the preset", async () => {
    const players = makePool(16, (i) => 18 + i * 1.5);
    const muGap = (m: Match) =>
      Math.abs(
        m[0].reduce((a, p) => a + p.rating.mu, 0) -
          m[1].reduce((a, p) => a + p.rating.mu, 0),
      );
    const meanGap = (r: { rounds: Outcome[] }) => {
      const gaps = r.rounds.flatMap((round) =>
        round.matches.map(({ match }) => muGap(match)),
      );
      return gaps.reduce((a, b) => a + b, 0) / gaps.length;
    };

    // Same strategy, opposite slider positions.
    const quality = await generate({
      numberOfRounds: 2,
      players,
      courts: 4,
      strategy: "SolverRoundRobin",
      weightConfig: { qualityVsVariety: 1, advanced: undefined },
    });
    const variety = await generate({
      numberOfRounds: 2,
      players,
      courts: 4,
      strategy: "SolverCompetitivePlus",
      weightConfig: { qualityVsVariety: 0, advanced: undefined },
    });

    expect(meanGap(quality)).toBeLessThanOrEqual(meanGap(variety));
  }, 120_000);

  it("stops early when the pool cannot fill the courts", async () => {
    const result = await generate({
      numberOfRounds: 3,
      players: makePool(6),
      courts: 2,
      strategy: "SolverRandomBalanced",
    });
    expect(result.rounds).toHaveLength(0);
  }, 60_000);
});

// Whole-session behaviour: fair play time, good variety, sane match quality.
//
// Every threshold below is a starting value, tuned against simulated play
// rather than real sessions. They live in one table so they can be revised as
// data from real events comes in.

import { describe, expect, it } from "vitest";
import * as SessionMetrics from "../../src/lib/rating/solver/SessionMetrics.re.mjs";
import {
  blowoutFraction,
  meanTrueWinProbGap,
  mismatchFraction,
  playerCounts,
  rankCorrelation,
  runSession,
  type Scenario,
  type SimResult,
} from "./sessionSim";
import { type Player } from "./fixtures";

// Assertions are on aggregates over several seeds so a single unlucky session
// cannot flake the suite. Raise this when investigating a regression; it is
// kept low here purely for CI wall-clock.
const SEEDS = [1, 2, 3];

const THRESHOLDS = {
  gamesSpread: 1, // max - min games played, fixed roster
  gamesSpreadWithChurn: 2,
  competitiveWinProbGap: 0.45, // mean |2p - 1| from ground truth
  mismatchRate: 0.05, // share of games with a >0.9 favourite
  blowoutRate: 0.2, // share of 9+ point margins
  opponentCoverage: 0.6, // share of the pool each player has faced
  // Lowered from 0.75 when Round Robin gained its competitive tiebreak, and
  // again when its splits became variety-first: alternation now only steers
  // among equally-novel splits, so it nudges rather than dictates. Guards the
  // term staying meaningfully above a side-blind baseline (~0.5), not
  // perfection.
  alternationRate: 0.55,
  // Share of competitive-preset matches inside the favoured/underdog dead zone.
  // The dead zone is deliberately narrow (predicted win probability within
  // 0.5 +/- 0.05) and narrows further as sigma converges, so this is well below
  // 1 even for a well-banded session; it is here to catch the term going inert
  // for the wrong reason, not to demand perfection. Measured 0.76-0.84 across
  // sample realignments (e.g. the seeded team-side swap changing simulated
  // score streams); per-match evenness itself is pinned deterministically by
  // the balance filter, so this aggregate only guards the banding side.
  competitiveEvenFraction: 0.7,
  rankCorrelation: 0.7,
};

const SOLVER_PRESETS = ["SolverRoundRobin", "SolverRandomBalanced", "SolverCompetitivePlusStatic"];

const flatSkill = (i: number) => 20 + (i % 8) * 1.5;

const baseScenario = (overrides: Partial<Scenario> = {}): Scenario => ({
  numRounds: 8,
  courts: 4,
  strategy: "SolverRandomBalanced",
  seed: 1,
  numPlayers: 16,
  theta: flatSkill,
  // Pre-seed visible ratings near the truth unless a scenario wants cold start,
  // so quality assertions are not dominated by early rating noise.
  startMu: (_i, theta) => theta,
  ...overrides,
});

async function runSeeds(
  scenario: Partial<Scenario>,
): Promise<SimResult[]> {
  const results: SimResult[] = [];
  for (const seed of SEEDS) {
    results.push(await runSession(baseScenario({ ...scenario, seed })));
  }
  return results;
}

const analyze = (result: SimResult, players?: Player[]) =>
  SessionMetrics.analyze(result.rounds, players ?? result.initialPlayers);

const meanOf = (values: number[]) =>
  values.reduce((a, b) => a + b, 0) / values.length;

describe("simulated sessions", () => {
  it("scenario 1: fixed roster, no byes — every player plays every round", async () => {
    for (const strategy of SOLVER_PRESETS) {
      const results = await runSeeds({ strategy, numPlayers: 16, courts: 4 });
      results.forEach((result) => {
        expect(result.fellBackToGreedy).toBe(false);
        const counts = [...playerCounts(result.rounds, result.initialPlayers).values()];
        expect(Math.max(...counts)).toBe(8);
        expect(Math.min(...counts)).toBe(8);
      });
    }
  }, 600_000);

  it("scenario 2: byes every round — play time stays even and byes never repeat", async () => {
    // 20 players, 4 courts: 4 sit each round, and 4 <= 16 seats, so a
    // back-to-back bye is never arithmetically forced.
    const results = await runSeeds({ numPlayers: 20, courts: 4, numRounds: 10 });
    results.forEach((result) => {
      const metrics = analyze(result);
      expect(metrics.maxGames - metrics.minGames).toBeLessThanOrEqual(
        THRESHOLDS.gamesSpread,
      );
      expect(metrics.backToBackByes).toBe(0);
    });
  }, 600_000);

  it("scenario 3: heavy byes — forced back-to-back byes are minimal and reported", async () => {
    // 13 players, 2 courts: 5 sit each round out of 8 seats, still avoidable.
    const gentle = await runSeeds({ numPlayers: 13, courts: 2, numRounds: 8 });
    gentle.forEach((result) => {
      expect(analyze(result).backToBackByes).toBe(0);
    });

    // 20 players, 2 courts: 12 sit but only 8 can play, so at least 4 must sit
    // twice running. Every occurrence has to appear in the round violations.
    const stressed = await runSeeds({ numPlayers: 20, courts: 2, numRounds: 6 });
    stressed.forEach((result) => {
      const metrics = analyze(result);
      expect(metrics.backToBackByes).toBeGreaterThan(0);
      const reported = result.roundViolations
        .flat()
        .filter((v: any) => v.TAG === "BackToBackBye").length;
      expect(reported).toBe(metrics.backToBackByes);
    });
  }, 600_000);

  it("scenario 4: churn — late joiners catch up without starving anyone", async () => {
    const results = await runSeeds({
      numPlayers: 20,
      courts: 4,
      numRounds: 10,
      // Four players leave after round 3; three more join at round 5.
      roster: (roundIndex, all) => {
        let roster = all.slice(0, 16);
        if (roundIndex >= 3) roster = roster.slice(0, 12);
        if (roundIndex >= 5) roster = roster.concat(all.slice(16, 19));
        return roster;
      },
    });

    results.forEach((result) => {
      // Only judge fairness among players who were present throughout.
      const stayers = result.initialPlayers.slice(0, 12);
      const counts = [...playerCounts(result.rounds, stayers).values()];
      expect(Math.max(...counts) - Math.min(...counts)).toBeLessThanOrEqual(
        THRESHOLDS.gamesSpreadWithChurn,
      );
    });
  }, 600_000);

  it("scenario 5: skewed skills — the outlier is not parked with the weakest", async () => {
    const results = await runSeeds({
      strategy: "SolverCompetitivePlusStatic",
      numPlayers: 16,
      courts: 4,
      // One player far above the pool, plus two clusters.
      theta: (i) => (i === 0 ? 45 : i < 8 ? 30 : 20),
      numRounds: 8,
    });

    results.forEach((result) => {
      // Rank by hidden truth: player slots no longer carry skill order (the
      // harness deals the ladder out in a seeded permutation), so slice(0)
      // and slice(8) would pick arbitrary players.
      const byTruth = [...result.initialPlayers].sort(
        (a, b) => result.theta[b.id] - result.theta[a.id],
      );
      const strongest = byTruth[0].id;
      const weakest = new Set(byTruth.slice(8).map((p) => p.id));
      const carries = result.rounds
        .flatMap((round) => round)
        .filter(({ match }) => {
          const ids = [...match[0], ...match[1]].map((p) => p.id);
          return (
            ids.includes(strongest) && ids.filter((id) => weakest.has(id)).length >= 2
          );
        });
      // Some contact is unavoidable in a 16-player pool; parking the outlier
      // with a majority of the bottom cluster should stay rare.
      expect(carries.length / result.rounds.length).toBeLessThanOrEqual(0.5);
    });
  }, 600_000);

  it("scenario 6: constraints — nothing is violated without being reported", async () => {
    const results = await runSeeds({
      numPlayers: 16,
      courts: 4,
      numRounds: 6,
      avoidAllPlayers: (players) => [
        [players[0], players[1]],
        [players[2], players[3]],
      ],
      teamConstraints: [new Set(["p4", "p5"])],
      requiredPlayerIds: ["p15"],
    });

    results.forEach((result) => {
      // The reported violations are the only ones present.
      result.rounds.forEach((round) =>
        round.forEach(({ id, match }) => {
          const ids = [...match[0], ...match[1]].map((p) => p.id);
          const breaksAvoid =
            (ids.includes("p0") && ids.includes("p1")) ||
            (ids.includes("p2") && ids.includes("p3"));
          if (breaksAvoid) {
            expect(result.matchViolations[id]).toBeDefined();
          }
        }),
      );
      // p15 is required and the pool is large enough to always seat them.
      expect(
        result.roundViolations.flat().filter((v: any) => v.TAG === "RequiredPlayerUnseated"),
      ).toHaveLength(0);
    });
  }, 600_000);

  it("scenario 6b: over-constrained — courts still fill and every breach is flagged", async () => {
    const results = await runSeeds({
      numPlayers: 8,
      courts: 2,
      numRounds: 4,
      // Five mutually-avoiding players on two courts cannot be separated.
      avoidAllPlayers: (players) => [players.slice(0, 5)],
    });

    results.forEach((result) => {
      result.rounds.forEach((round) => {
        expect(round).toHaveLength(2);
        const flagged = round.filter(({ id }) => result.matchViolations[id]);
        expect(flagged.length).toBeGreaterThan(0);
      });
    });
  }, 600_000);

  it("scenario 7: cold start — rounds are still well formed before ratings separate", async () => {
    const results = await runSeeds({
      numPlayers: 16,
      courts: 4,
      numRounds: 6,
      startMu: () => 25,
    });

    results.forEach((result) => {
      const metrics = analyze(result);
      expect(metrics.maxGames - metrics.minGames).toBe(0);
      // Nothing to balance yet: with identical cold-start ratings, every
      // first-round match is inside the dead zone by construction. (Whole-
      // session even-fractions are no longer asserted here — Random Balanced's
      // composition is deliberately random, so once ratings separate its
      // matches may legitimately have favourites.)
      const firstRound = SessionMetrics.analyze(
        result.rounds.slice(0, 1),
        result.initialPlayers,
      );
      expect(firstRound.evenMatchFraction).toBe(1);
    });
  }, 600_000);

  it("delivers variety on the variety preset", async () => {
    // 16 players / 4 courts over 8 rounds: 15 possible partners each, so a
    // repeat-free session exists.
    const results = await runSeeds({
      strategy: "SolverRoundRobin",
      numPlayers: 16,
      courts: 4,
      numRounds: 8,
    });
    results.forEach((result) => {
      const metrics = analyze(result);
      expect(metrics.excessPartnerRepeats).toBe(0);
      expect(metrics.opponentCoverage).toBeGreaterThanOrEqual(
        THRESHOLDS.opponentCoverage,
      );
    });

    // With byes in play, no pair should partner three times.
    const withByes = await runSeeds({
      strategy: "SolverRoundRobin",
      numPlayers: 20,
      courts: 4,
      numRounds: 10,
    });
    withByes.forEach((result) => {
      expect(analyze(result).maxPartnerRepeat).toBeLessThan(3);
    });
  }, 900_000);

  it("delivers match quality on the competitive preset", async () => {
    const results = await runSeeds({
      strategy: "SolverCompetitivePlusStatic",
      numPlayers: 16,
      courts: 4,
      numRounds: 8,
      theta: (i) => 18 + i * 1.5,
      startMu: (_i, theta) => theta,
    });

    const gaps = results.map((r) => meanTrueWinProbGap(r.rounds, r.theta));
    const mismatches = results.map((r) => mismatchFraction(r.rounds, r.theta));
    const blowouts = results.map((r) => blowoutFraction(r.rounds));

    expect(meanOf(gaps)).toBeLessThanOrEqual(THRESHOLDS.competitiveWinProbGap);
    expect(meanOf(mismatches)).toBeLessThanOrEqual(THRESHOLDS.mismatchRate);
    expect(meanOf(blowouts)).toBeLessThanOrEqual(THRESHOLDS.blowoutRate);
    // The competitive preset drives matches into the dead zone, which is why
    // the alternation term is inert for it by design.
    expect(
      meanOf(results.map((r) => analyze(r).evenMatchFraction)),
    ).toBeGreaterThanOrEqual(THRESHOLDS.competitiveEvenFraction);
  }, 900_000);

  it("alternates favourite and underdog roles where matches have a favourite", async () => {
    // A spread-out pool on the variety preset leaves real favourites around.
    const results = await runSeeds({
      strategy: "SolverRoundRobin",
      numPlayers: 16,
      courts: 4,
      numRounds: 8,
      theta: (i) => 15 + i * 2,
      startMu: (_i, theta) => theta,
    });

    const rates = results
      .map((r) => analyze(r))
      .filter((m) => m.alternationOpportunities > 0)
      .map((m) => m.alternationRate);
    expect(rates.length).toBeGreaterThan(0);
    expect(meanOf(rates)).toBeGreaterThanOrEqual(THRESHOLDS.alternationRate);
  }, 900_000);

  it("expresses the three preset use cases over a session", async () => {
    const scenario = {
      numPlayers: 16,
      courts: 4,
      numRounds: 8,
      theta: (i: number) => 15 + i * 2,
      startMu: (_i: number, theta: number) => theta,
    };
    const runPreset = async (strategy: string, weightConfig?: unknown) =>
      (await runSeeds({ ...scenario, strategy, weightConfig })).map((r) =>
        analyze(r),
      );

    // Round Robin: the variety contract is absolute — no repeated partnerships
    // in a session where a repeat-free schedule exists.
    const roundRobin = await runPreset("SolverRoundRobin");
    roundRobin.forEach((m) => expect(m.excessPartnerRepeats).toBe(0));

    // Random Balanced: balancing each match beats not balancing it. Paired
    // estimator: compare every played match's gap against the mean gap of its
    // own foursome's three possible splits (what a split-blind draw would
    // yield in expectation). Paired because an unpaired baseline session
    // diverges from round 1 and the comparison drowns in sampling noise.
    const rbResults: SimResult[] = [];
    for (const seed of SEEDS) {
      rbResults.push(
        await runSession(
          baseScenario({
            ...scenario,
            strategy: "SolverRandomBalanced",
            seed,
          }),
        ),
      );
    }
    let chosenTotal = 0;
    let blindTotal = 0;
    let matchCount = 0;
    rbResults.forEach((result) =>
      result.rounds.forEach((round) =>
        round.forEach(({ match }) => {
          const quad = [...match[0], ...match[1]];
          const sum = (xs: Player[]) => xs.reduce((a, p) => a + p.rating.mu, 0);
          const [a, b, c, d] = quad;
          const gaps = [
            Math.abs(sum([a, b]) - sum([c, d])),
            Math.abs(sum([a, c]) - sum([b, d])),
            Math.abs(sum([a, d]) - sum([b, c])),
          ];
          chosenTotal += Math.abs(sum(match[0]) - sum(match[1]));
          blindTotal += gaps.reduce((x, y) => x + y, 0) / 3;
          matchCount += 1;
        }),
      ),
    );
    expect(matchCount).toBeGreaterThan(0);
    expect(chosenTotal / matchCount).toBeLessThan((blindTotal / matchCount) * 0.75);

    const randomBalanced = rbResults.map((r) => analyze(r));
    // ...and it balances without banding the courts.
    expect(meanOf(randomBalanced.map((m) => m.meanSpread))).toBeGreaterThan(
      meanOf((await runPreset("SolverCompetitivePlusStatic")).map((m) => m.meanSpread)),
    );
  }, 1_200_000);

  it("beats the legacy greedy engine on its own terms", async () => {
    const compare = async (solver: string, legacy: string) => {
      const solverRuns = await runSeeds({
        strategy: solver,
        numPlayers: 16,
        courts: 4,
        numRounds: 8,
        theta: (i) => 15 + i * 2,
        startMu: (_i, theta) => theta,
      });
      const legacyRuns = await runSeeds({
        strategy: legacy,
        numPlayers: 16,
        courts: 4,
        numRounds: 8,
        theta: (i) => 15 + i * 2,
        startMu: (_i, theta) => theta,
      });
      return {
        solver: solverRuns.map((r) => analyze(r)),
        legacy: legacyRuns.map((r) => analyze(r)),
      };
    };

    const variety = await compare("SolverRoundRobin", "NoveltyRoundRobin");
    expect(
      meanOf(variety.solver.map((m) => m.excessPartnerRepeats)),
    ).toBeLessThanOrEqual(
      meanOf(variety.legacy.map((m) => m.excessPartnerRepeats)),
    );
    expect(
      meanOf(variety.solver.map((m) => m.maxGames - m.minGames)),
    ).toBeLessThanOrEqual(
      meanOf(variety.legacy.map((m) => m.maxGames - m.minGames)),
    );

    const competitive = await compare("SolverCompetitivePlusStatic", "Competitive");
    expect(meanOf(competitive.solver.map((m) => m.meanMuGap))).toBeLessThanOrEqual(
      meanOf(competitive.legacy.map((m) => m.meanMuGap)),
    );
  }, 1_200_000);

  it("converges visible ratings towards the hidden truth", async () => {
    const results = await runSeeds({
      strategy: "SolverRandomBalanced",
      numPlayers: 16,
      courts: 4,
      numRounds: 10,
      theta: (i) => 15 + i * 2,
      startMu: () => 25,
    });

    const correlations = results.map((r) =>
      rankCorrelation(r.finalPlayers, r.theta),
    );
    // Logged as much as asserted: this is about the closed loop producing
    // informative matches, not about the rating maths itself.
    // eslint-disable-next-line no-console
    console.log(
      `[SessionSim] rank correlation after 10 rounds: ${correlations
        .map((c) => c.toFixed(2))
        .join(", ")}`,
    );
    expect(meanOf(correlations)).toBeGreaterThanOrEqual(
      THRESHOLDS.rankCorrelation,
    );
  }, 900_000);

  it("prints a readable report for one canonical session", async () => {
    const result = await runSession(
      baseScenario({
        strategy: "SolverRandomBalanced",
        numPlayers: 20,
        courts: 4,
        numRounds: 8,
        theta: (i) => 15 + i * 1.5,
        startMu: () => 25,
      }),
    );
    const metrics = analyze(result);
    const counts = playerCounts(result.rounds, result.initialPlayers);

    const lines: string[] = [];
    result.rounds.forEach((round, r) => {
      lines.push(`Round ${r + 1}`);
      round.forEach(({ match, score }) => {
        const name = (team: Player[]) => team.map((p) => p.name).join(" + ");
        lines.push(
          `  ${name(match[0])} vs ${name(match[1])}  ${score?.join("-") ?? ""}`,
        );
      });
    });
    lines.push("");
    lines.push(
      `games played: ${metrics.minGames}-${metrics.maxGames} ` +
        `(per player: ${[...counts.values()].join(",")})`,
    );
    lines.push(
      `partner repeats: ${metrics.excessPartnerRepeats} (max ${metrics.maxPartnerRepeat})`,
    );
    lines.push(`opponent coverage: ${metrics.opponentCoverage.toFixed(2)}`);
    lines.push(`back-to-back byes: ${metrics.backToBackByes}`);
    lines.push(
      `mean skill gap: ${metrics.meanMuGap.toFixed(2)} mu ` +
        `(${metrics.meanDuprGap.toFixed(3)} DUPR), spread ${metrics.meanSpread.toFixed(2)}`,
    );
    lines.push(`alternation rate: ${metrics.alternationRate.toFixed(2)}`);
    lines.push(
      `round generation ms: ${result.roundMs.map((ms) => Math.round(ms)).join(", ")}`,
    );

    // eslint-disable-next-line no-console
    console.log(`\n[SessionSim] canonical session\n${lines.join("\n")}\n`);
    expect(result.rounds).toHaveLength(8);
  }, 600_000);
});

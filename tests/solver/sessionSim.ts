// Simulated-session harness.
//
// Runs the real pipeline end to end — generate a round, simulate results from
// hidden ground-truth skill, feed them through the actual rating update, then
// generate the next round — so the assertions are about how a *session* feels,
// not whether a single round was optimal.

import * as Rating from "../../src/lib/Rating.re.mjs";
import * as SolverRounds from "../../src/lib/rating/solver/SolverRounds.re.mjs";
import { makePlayer, playerIds, type Match, type Player, type Round } from "./fixtures";

export function rng(seed: number) {
  let s = seed >>> 0 || 1;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

// Hidden true skill, on the same scale as mu.
export type Truth = Record<string, number>;

export type Scenario = {
  numRounds: number;
  courts: number;
  strategy: string;
  seed: number;
  // Ground-truth skill for player i.
  theta: (i: number, next: () => number) => number;
  numPlayers: number;
  // Visible starting mu. Defaults to the cold-start 25 for everyone.
  startMu?: (i: number, theta: number) => number;
  // Visible starting sigma, for settled-but-wrong priors (e.g. an inverted
  // ladder carried in from earlier sessions). Defaults to the cold-start 25/3.
  startSigma?: (i: number, theta: number) => number;
  gender?: (i: number) => "Male" | "Female";
  weightConfig?: unknown;
  teamConstraints?: Set<string>[];
  avoidAllPlayers?: (players: Player[]) => Player[][];
  requiredPlayerIds?: string[];
  // Roster changes: return the ids present at the start of the given round.
  roster?: (roundIndex: number, all: Player[]) => Player[];
  // Mid-session strategy changes (e.g. calibrate, then switch to competitive).
  strategyByRound?: (roundIndex: number) => string;
};

export type SimResult = {
  rounds: Round[];
  finalPlayers: Player[];
  initialPlayers: Player[];
  theta: Truth;
  matchViolations: Record<string, unknown[]>;
  roundViolations: unknown[][];
  fellBackToGreedy: boolean;
  roundMs: number[];
};

// Win probability for team1 from ground truth. The scale is chosen so a
// 10-point team-sum edge is a ~0.75 favourite, roughly matching how mu maps to
// win probability in openskill.
const THETA_SCALE = 8;

export const trueWinProbability = (match: Match, theta: Truth): number => {
  const sum = (team: Player[]) => team.reduce((a, p) => a + theta[p.id], 0);
  return 1 / (1 + Math.exp(-(sum(match[0]) - sum(match[1])) / THETA_SCALE));
};

const MAX_SCORE = 11;

// A score line consistent with the win probability: the more lopsided the
// matchup, the further the loser falls short.
function simulateScore(
  match: Match,
  theta: Truth,
  next: () => number,
): [number, number] {
  const p1 = trueWinProbability(match, theta);
  const team1Wins = next() < p1;
  const dominance = Math.abs(p1 - 0.5) * 2;
  const expectedLoserScore = (MAX_SCORE - 2) * (1 - dominance);
  const jitter = (next() - 0.5) * 4;
  const loserScore = Math.max(
    0,
    Math.min(MAX_SCORE - 2, Math.round(expectedLoserScore + jitter)),
  );
  return team1Wins ? [MAX_SCORE, loserScore] : [loserScore, MAX_SCORE];
}

export async function runSession(scenario: Scenario): Promise<SimResult> {
  const next = rng(scenario.seed);

  const theta: Truth = {};
  const initialPlayers: Player[] = [];
  for (let i = 0; i < scenario.numPlayers; i++) {
    const t = scenario.theta(i, next);
    const player = makePlayer(i, {
      mu: scenario.startMu?.(i, t) ?? 25,
      sigma: scenario.startSigma?.(i, t),
      gender: scenario.gender?.(i),
    });
    theta[player.id] = t;
    initialPlayers.push(player);
  }

  const scoredRounds: Round[] = [];
  const matchViolations: Record<string, unknown[]> = {};
  const roundViolations: unknown[][] = [];
  const roundMs: number[] = [];
  let fellBackToGreedy = false;

  for (let r = 0; r < scenario.numRounds; r++) {
    const roster = scenario.roster?.(r, initialPlayers) ?? initialPlayers;
    const rosterIds = new Set(roster.map((p) => p.id));

    // Visible state derived by replaying the scored history, exactly as the
    // app does.
    const state: Player[] = Rating.toPlayerStateWithAdjustments(
      scoredRounds,
      initialPlayers,
      [],
    );
    const available = state.filter((p) => rosterIds.has(p.id));

    const startedAt = Date.now();
    const result = await SolverRounds.generateRounds(
      1,
      available,
      scoredRounds,
      scenario.strategyByRound?.(r) ?? scenario.strategy,
      scenario.courts,
      new Date(0),
      scenario.weightConfig,
      scenario.teamConstraints,
      scenario.avoidAllPlayers?.(available),
      scenario.requiredPlayerIds,
      undefined,
      undefined,
      r,
      `sim-${scenario.seed}`,
      5.0,
      undefined,
    );
    roundMs.push(Date.now() - startedAt);

    if (result.fellBackToGreedy) fellBackToGreedy = true;
    const outcome = result.rounds[0];
    if (!outcome) break;

    Object.entries(outcome.matchViolations).forEach(([id, reasons]) => {
      matchViolations[id] = reasons as unknown[];
    });
    roundViolations.push(outcome.roundViolations);

    const scored: Round = outcome.matches.map(
      (entity: { id: string; match: Match; createdAt: Date }) => ({
        ...entity,
        score: simulateScore(entity.match, theta, next),
      }),
    );
    scoredRounds.push(scored);
  }

  return {
    rounds: scoredRounds,
    finalPlayers: Rating.toPlayerStateWithAdjustments(
      scoredRounds,
      initialPlayers,
      [],
    ),
    initialPlayers,
    theta,
    matchViolations,
    roundViolations,
    fellBackToGreedy,
    roundMs,
  };
}

// ---------------------------------------------------------------------------
// Ground-truth flavoured metrics (the visible-rating ones live in
// SessionMetrics.res, shared with the UI)
// ---------------------------------------------------------------------------

export const allMatches = (rounds: Round[]): Match[] =>
  rounds.flatMap((round) => round.map((m) => m.match));

export const meanTrueWinProbGap = (rounds: Round[], theta: Truth): number => {
  const matches = allMatches(rounds);
  if (matches.length === 0) return 0;
  return (
    matches.reduce(
      (a, m) => a + Math.abs(trueWinProbability(m, theta) - 0.5) * 2,
      0,
    ) / matches.length
  );
};

export const mismatchFraction = (rounds: Round[], theta: Truth): number => {
  const matches = allMatches(rounds);
  if (matches.length === 0) return 0;
  const bad = matches.filter((m) => {
    const p = trueWinProbability(m, theta);
    return p > 0.9 || p < 0.1;
  });
  return bad.length / matches.length;
};

// Fraction of games decided by 9 or more points out of 11.
export const blowoutFraction = (rounds: Round[]): number => {
  const scored = rounds.flatMap((r) => r).filter((m) => m.score);
  if (scored.length === 0) return 0;
  const count = scored.filter((m) => {
    const [a, b] = m.score!;
    return Math.abs(a - b) >= 9;
  }).length;
  return count / scored.length;
};

// Spearman rank correlation between visible ordinal and hidden truth.
export function rankCorrelation(players: Player[], theta: Truth): number {
  const n = players.length;
  if (n < 2) return 1;
  const rank = (values: { id: string; v: number }[]) => {
    const sorted = [...values].sort((a, b) => a.v - b.v);
    const out: Record<string, number> = {};
    sorted.forEach((entry, i) => (out[entry.id] = i));
    return out;
  };
  const visible = rank(players.map((p) => ({ id: p.id, v: p.rating.mu })));
  const truth = rank(players.map((p) => ({ id: p.id, v: theta[p.id] })));
  const d2 = players.reduce(
    (a, p) => a + (visible[p.id] - truth[p.id]) ** 2,
    0,
  );
  return 1 - (6 * d2) / (n * (n * n - 1));
}

export const playerCounts = (rounds: Round[], players: Player[]) => {
  const counts = new Map(players.map((p) => [p.id, 0]));
  rounds.forEach((round) =>
    round.forEach(({ match }) =>
      playerIds(match).forEach((id) =>
        counts.set(id, (counts.get(id) ?? 0) + 1),
      ),
    ),
  );
  return counts;
};

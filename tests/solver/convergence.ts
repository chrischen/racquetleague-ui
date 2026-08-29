// Convergence measurement harness.
//
// Runs cold-start simulated sessions (hidden ground-truth skill, real
// generation + rating pipeline) and derives the metrics we use to judge how
// fast a matchmaking configuration teaches the rating system the truth:
//
//   spearmanByRound  mean rank correlation between visible ratings and hidden
//                    truth after each round (the convergence curve)
//   ratioByRound     mean pool signal-to-noise, std(mu) / mean(sigma) — the
//                    "ratings have settled" readiness signal
//   r1PartnersKeptR2 round-1 partnerships surviving into round 2, summed over
//                    seeds — cold-start mu-degeneracy should split ~all
//
// Everything is deterministic per seed (seeded sim PRNG, seeded solver), so
// measured values are exact across runs on unchanged code. The committed
// assertions in Convergence.test.ts are deliberately looser floors/orderings,
// to catch regressions without blocking intentional tuning.
//
// For ad-hoc tuning probes, import `measureConvergence` and console.log the
// curves — that is exactly how the committed baselines were produced.

import * as Rating from "../../src/lib/Rating.re.mjs";
import {
  runSession,
  rankCorrelation,
  trueWinProbability,
  type SimResult,
} from "./sessionSim";
import { pairKey } from "./fixtures";

export type ConvergenceOpts = {
  strategy: string;
  weightConfig?: unknown;
  seeds?: number[];
  numRounds?: number;
  numPlayers?: number;
  courts?: number;
  // Hidden truth; default linear spread, clearly separable.
  theta?: (i: number) => number;
  // Visible prior. Defaults to cold start (mu 25, default sigma); override for
  // settled-but-wrong priors such as an inverted ladder.
  startMu?: (i: number) => number;
  startSigma?: (i: number) => number;
  // Mid-session strategy changes, for calibrate-then-switch scenarios.
  strategyByRound?: (roundIndex: number) => string;
};

export type ConvergenceMeasurement = {
  spearmanByRound: number[]; // index k = after round k+1, mean over seeds
  ratioByRound: number[];
  r1PartnersKeptR2: number;
  partnershipsPerSeed: number; // denominator per seed for the above
  sessions: SimResult[];
};

const stateAfter = (result: SimResult, k: number) =>
  Rating.toPlayerStateWithAdjustments(
    result.rounds.slice(0, k),
    result.initialPlayers,
    [],
  );

const signalToNoise = (state: any[]): number => {
  const mus = state.map((p) => p.rating.mu);
  const mean = mus.reduce((a, b) => a + b, 0) / mus.length;
  const spread = Math.sqrt(
    mus.reduce((a, m) => a + (m - mean) ** 2, 0) / mus.length,
  );
  const meanSigma =
    state.reduce((a, p) => a + p.rating.sigma, 0) / state.length;
  return spread / meanSigma;
};

const partnershipsOf = (round: any): Set<string> =>
  new Set(
    round.flatMap(({ match }: any) =>
      [match[0], match[1]].map((t: any) => pairKey(t[0].id, t[1].id)),
    ),
  );

// ---------------------------------------------------------------------------
// Session post-processing metrics (embedded ratings = ratings at generation)
// ---------------------------------------------------------------------------

const quadOf = (m: any): any[] => [...m.match[0], ...m.match[1]];
const teamMu = (team: any[]): number => team.reduce((a, p) => a + p.rating.mu, 0);

// The three team-sum gaps a foursome can split into.
const splitGaps = (quad: any[]): number[] => {
  const mu = quad.map((p) => p.rating.mu);
  return [
    Math.abs(mu[0] + mu[1] - mu[2] - mu[3]),
    Math.abs(mu[0] + mu[2] - mu[1] - mu[3]),
    Math.abs(mu[0] + mu[3] - mu[1] - mu[2]),
  ];
};

// Banding curve: MEDIAN quad mu-range as a fraction of the pool's mu-range,
// per round over all seeds. ~0.3 = courts tightly grouped by skill
// (Competitive+), ~0.6 = freely mixed (Random Balanced). The median rather
// than the mean on purpose: Auto injects one deliberately pool-spanning
// stacked probe per round (the rating-aligned blind-spot corrective), and the
// claim this metric guards is about the *typical* court, which the single
// intentional outlier must not be able to drag. Rounds where the pool's range
// is degenerate (cold start) contribute nothing.
export const bandingByRound = (m: ConvergenceMeasurement): number[] => {
  const rounds = m.sessions[0]?.rounds.length ?? 0;
  return Array.from({ length: rounds }, (_, k) => {
    const ratios: number[] = [];
    for (const s of m.sessions) {
      const state = stateAfter(s, k);
      const mus = state.map((p: any) => p.rating.mu);
      const poolRange = Math.max(...mus) - Math.min(...mus);
      if (poolRange <= 1e-9) continue;
      for (const match of s.rounds[k]) {
        const qmus = quadOf(match).map((p: any) => p.rating.mu);
        ratios.push((Math.max(...qmus) - Math.min(...qmus)) / poolRange);
      }
    }
    if (ratios.length === 0) return 0;
    ratios.sort((a, b) => a - b);
    const mid = ratios.length >> 1;
    return ratios.length % 2 ? ratios[mid] : (ratios[mid - 1] + ratios[mid]) / 2;
  });
};

// Match quality, as the players experience it: the mean true-win-probability
// gap |p - 0.5| * 2 over the matches of each round (0 = every game a genuine
// coin flip, 1 = every game a foregone conclusion), measured against hidden
// truth rather than visible ratings. The MEAN on purpose, unlike the banding
// metric: quality cost is an account of all games played, and a deliberately
// sacrificed probe match belongs in the bill.
export const qualityByRound = (m: ConvergenceMeasurement): number[] => {
  const rounds = m.sessions[0]?.rounds.length ?? 0;
  return Array.from({ length: rounds }, (_, k) => {
    let acc = 0;
    let n = 0;
    for (const s of m.sessions) {
      for (const match of s.rounds[k]) {
        acc += Math.abs(trueWinProbability(match.match, s.theta) - 0.5) * 2;
        n++;
      }
    }
    return n ? acc / n : 0;
  });
};

// Session-level quality summary: mean gap over every match played, plus the
// fraction of true blowouts (win probability beyond 90/10).
export const sessionQuality = (
  m: ConvergenceMeasurement,
): { meanGap: number; blowoutFraction: number } => {
  let acc = 0;
  let blowouts = 0;
  let n = 0;
  for (const s of m.sessions) {
    for (const round of s.rounds) {
      for (const match of round) {
        const p = trueWinProbability(match.match, s.theta);
        acc += Math.abs(p - 0.5) * 2;
        if (p > 0.9 || p < 0.1) blowouts++;
        n++;
      }
    }
  }
  return { meanGap: n ? acc / n : 0, blowoutFraction: n ? blowouts / n : 0 };
};

// ---------------------------------------------------------------------------
// Outcome metrics — what players and organisers actually experience, in
// absolute terms rather than relative to another strategy.
// ---------------------------------------------------------------------------

const BETA = 25 / 6; // openskill default

// Win probability the RATINGS predicted for team1, from the values embedded at
// match time (not current ratings).
const predictedWinProb = (match: any): number => {
  const muSum = (t: any[]) => t.reduce((a, p) => a + p.rating.mu, 0);
  const varSum = (t: any[]) =>
    t.reduce((a, p) => a + p.rating.sigma ** 2 + BETA ** 2, 0);
  const c = Math.sqrt(varSum(match[0]) + varSum(match[1]));
  return 1 / (1 + Math.exp(-(muSum(match[0]) - muSum(match[1])) / c));
};

// How well the ratings predicted the results they produced.
//   brier          mean (p - outcome)^2; 0.25 = coin flip, lower is better
//   favouriteRate  share of decided games the rated favourite won
//   meanConfidence mean |p - 0.5| * 2 — how strong a call the ratings made
export const predictionQuality = (
  m: ConvergenceMeasurement,
  fromRound = 0,
): { brier: number; favouriteRate: number; meanConfidence: number; n: number } => {
  let brier = 0;
  let conf = 0;
  let n = 0;
  let favWins = 0;
  let decided = 0;
  for (const s of m.sessions) {
    for (const round of s.rounds.slice(fromRound)) {
      for (const { match, score } of round as any[]) {
        if (!score) continue;
        const p = predictedWinProb(match);
        const outcome = score[0] > score[1] ? 1 : score[0] < score[1] ? 0 : 0.5;
        brier += (p - outcome) ** 2;
        conf += Math.abs(p - 0.5) * 2;
        n++;
        if (outcome !== 0.5 && p !== 0.5) {
          decided++;
          if ((p > 0.5) === (outcome === 1)) favWins++;
        }
      }
    }
  }
  return {
    brier: n ? brier / n : 0,
    favouriteRate: decided ? favWins / decided : 0,
    meanConfidence: n ? conf / n : 0,
    n,
  };
};

// Distance from the truth, in units an organiser can read.
//   rankError  mean |visible rank - true rank|, in ladder positions
//   muError    RMSE of visible mu vs hidden truth, both standardised, so the
//              arbitrary scale/offset of each cancels
export const ratingErrorByRound = (
  m: ConvergenceMeasurement,
): { rankError: number[]; muError: number[] } => {
  const rounds = m.sessions[0]?.rounds.length ?? 0;
  const rankError: number[] = [];
  const muError: number[] = [];
  const standardise = (xs: number[]) => {
    const mean = xs.reduce((a, b) => a + b, 0) / xs.length;
    const sd = Math.sqrt(xs.reduce((a, x) => a + (x - mean) ** 2, 0) / xs.length);
    return xs.map((x) => (sd > 1e-9 ? (x - mean) / sd : 0));
  };
  for (let k = 1; k <= rounds; k++) {
    let rankAcc = 0;
    let muAcc = 0;
    let players = 0;
    for (const s of m.sessions) {
      const state = stateAfter(s, k);
      const rankOf = (vals: { id: string; v: number }[]) => {
        const out: Record<string, number> = {};
        [...vals].sort((a, b) => a.v - b.v).forEach((e, i) => (out[e.id] = i));
        return out;
      };
      const visRank = rankOf(state.map((p: any) => ({ id: p.id, v: p.rating.mu })));
      const trueRank = rankOf(state.map((p: any) => ({ id: p.id, v: s.theta[p.id] })));
      const zMu = standardise(state.map((p: any) => p.rating.mu));
      const zTheta = standardise(state.map((p: any) => s.theta[p.id]));
      state.forEach((p: any, i: number) => {
        rankAcc += Math.abs(visRank[p.id] - trueRank[p.id]);
        muAcc += (zMu[i] - zTheta[i]) ** 2;
        players++;
      });
    }
    rankError.push(players ? rankAcc / players : 0);
    muError.push(players ? Math.sqrt(muAcc / players) : 0);
  }
  return { rankError, muError };
};

// How each match's chosen split compares with the most balanced split its
// foursome allows. `atMin === total` is the balanced-split contract;
// `meanGap` is the residual imbalance that composition alone forces.
export const splitBalanceStats = (
  m: ConvergenceMeasurement,
): { atMin: number; total: number; meanGap: number } => {
  let atMin = 0;
  let total = 0;
  let gapSum = 0;
  for (const s of m.sessions) {
    for (const round of s.rounds) {
      for (const match of round) {
        const actual = Math.abs(teamMu(match.match[0]) - teamMu(match.match[1]));
        const min = Math.min(...splitGaps(quadOf(match)));
        total++;
        gapSum += actual;
        if (actual <= min + 1e-6) atMin++;
      }
    }
  }
  return { atMin, total, meanGap: total ? gapSum / total : 0 };
};

export async function measureConvergence(
  opts: ConvergenceOpts,
): Promise<ConvergenceMeasurement> {
  const seeds = opts.seeds ?? [1, 2, 3, 4, 5, 6];
  const numRounds = opts.numRounds ?? 10;
  const numPlayers = opts.numPlayers ?? 16;
  const courts = opts.courts ?? 4;
  const theta = opts.theta ?? ((i: number) => 15 + i * 2);

  const spearman = Array.from({ length: numRounds }, () => 0);
  const ratio = Array.from({ length: numRounds }, () => 0);
  let kept = 0;
  const sessions: SimResult[] = [];

  for (const seed of seeds) {
    const result = await runSession({
      numRounds,
      courts,
      numPlayers,
      seed,
      strategy: opts.strategy,
      weightConfig: opts.weightConfig,
      theta,
      startMu: opts.startMu ?? (() => 25), // cold start unless a prior is given
      startSigma: opts.startSigma,
      strategyByRound: opts.strategyByRound,
    } as any);
    sessions.push(result);

    for (let k = 1; k <= numRounds; k++) {
      const state = stateAfter(result, k);
      spearman[k - 1] += rankCorrelation(state, result.theta);
      ratio[k - 1] += signalToNoise(state);
    }
    if (result.rounds.length >= 2) {
      const first = partnershipsOf(result.rounds[0]);
      partnershipsOf(result.rounds[1]).forEach((key) => {
        if (first.has(key)) kept++;
      });
    }
  }

  return {
    spearmanByRound: spearman.map((v) => v / seeds.length),
    ratioByRound: ratio.map((v) => v / seeds.length),
    r1PartnersKeptR2: kept,
    partnershipsPerSeed: courts * 2,
    sessions,
  };
}

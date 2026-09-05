// Rating.ScoreModel: the rally model read in reverse. A final score is
// evidence — its rally split is the MLE of the per-rally probability, and
// pushing that through the game-win function says how decisive the result
// really was. `rateWithScore` uses that to ACCELERATE convergence: the
// openskill update iterates, as repeated wins, until the ratings believe what
// the score implied — capped, and never less than one full update.
import { describe, expect, it } from "vitest";
import * as RatingMod from "../../src/lib/Rating.re.mjs";

const R = RatingMod.Rating;
const SM = RatingMod.ScoreModel;

const team = (mu: number, sigma: number) => [
  { mu, sigma },
  { mu, sigma },
];
const fresh = () => [team(25, 25 / 3), team(25, 25 / 3)];

const iterate = (ratings: any, rank: number[], n: number) => {
  let r = ratings;
  for (let i = 0; i < n; i++) r = R.rate(r, { rank });
  return r;
};

describe("ScoreModel", () => {
  it("reads a score as implied win probability, monotone in margin", () => {
    expect(SM.impliedWinProb(11, 0)).toBeCloseTo(1, 9);
    for (const p of [0.6, 0.8, 0.95])
      expect(SM.gameWinProb(SM.rallyProbFor(p))).toBeCloseTo(p, 6);
    const ladder = [0, 2, 5, 7, 9].map((l) => SM.impliedWinProb(11, l));
    for (let i = 1; i < ladder.length; i++) expect(ladder[i]).toBeLessThan(ladder[i - 1]);
    expect(SM.impliedWinProb(11, 9)).toBeLessThan(0.7);
    expect(SM.impliedWinProb(11, 9)).toBeGreaterThan(0.5);
  });

  it("margin fixes the step count: a squeaker is one win, a shutout is four", () => {
    // The mapping is belief-free — evidence is worth what it is worth — so
    // each scored update equals an exact number of plain rate() applications.
    const equalTo = (score: [number, number], steps: number) => {
      const scored = SM.rateScored(fresh(), score);
      const plain = iterate(fresh(), [0, 1], steps);
      for (let t = 0; t < 2; t++)
        for (let p = 0; p < 2; p++) {
          expect(scored[t][p].mu).toBeCloseTo(plain[t][p].mu, 9);
          expect(scored[t][p].sigma).toBeCloseTo(plain[t][p].sigma, 9);
        }
    };
    equalTo([11, 9], 1); // implied ~0.68: just a win
    equalTo([11, 8], 1); // implied ~0.77: still just a win
    equalTo([11, 7], 2); // implied ~0.85
    equalTo([11, 5], 3); // implied ~0.97
    equalTo([11, 3], 4); // implied ~0.998: several wins running
    equalTo([11, 0], 4); // implied 1.0

    // The cap is a real cap: maxSteps=1 makes any score an ordinary win.
    const one = iterate(fresh(), [0, 1], 1);
    const capped = SM.rateWithScore(R.rate, fresh(), [11, 0], 1);
    expect(capped[0][0].mu).toBeCloseTo(one[0][0].mu, 9);
  });

  it("accelerates hardest on wide-margin upsets, and passes ties through", () => {
    // Team 1 is rated far above team 2, then loses 0-11: the underdog's
    // rating jumps as if they had won four times running — far beyond a
    // single win's worth, which is the cold-start and inversion accelerator.
    const skewed = () => [team(32, 4), team(18, 4)];
    const upsetOnce = iterate(skewed(), [1, 0], 1);
    const upsetScored = SM.rateScored(skewed(), [0, 11]);
    const gain = (r: any) => r[1][0].mu - 18;
    expect(gain(upsetScored)).toBeGreaterThan(gain(upsetOnce) * 2);
    // The same margin from the favourite is also four steps, but each step is
    // tiny — openskill already expected the result — so the accelerator stays
    // asymmetric in effect without being asymmetric in rule.
    const expectedWin = SM.rateScored(skewed(), [11, 0]);
    expect(expectedWin[0][0].mu - 32).toBeLessThan(gain(upsetScored) / 4);

    // A tie carries no ordering information: ratings pass through untouched.
    const tie = SM.rateScored(fresh(), [7, 7]);
    expect(tie[0][0].mu).toBe(25);
    expect(tie[1][1].sigma).toBeCloseTo(25 / 3, 9);
  });
});

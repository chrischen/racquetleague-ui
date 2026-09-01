// The lab's ladder panel used to read `labResult.truth` — where the session
// STARTED — so a drifting player's red truth bar sat frozen at round 0 and
// their rank never moved, while the ↑/↓ mark next to their name promised
// otherwise. Every metric in `SimLab` already took truth at the current round;
// only the view did not. These pin the view to the same clock.
import { describe, expect, it } from "vitest";
import * as SimLab from "../../src/lib/rating/SimLab.re.mjs";
import * as MatchmakingLab from "../../src/components/organisms/MatchmakingLab.re.mjs";

const PLAYERS = 18;
const ROUNDS = 40;

const fixture = async () => {
  const result = await SimLab.run(
    "AccuratePrior", 1, PLAYERS, 3, ROUNDS, SimLab.typicalField, false, undefined,
  );
  const run = result.runs[0];
  const rows = (round: number) =>
    MatchmakingLab.ladderRows(result, run.frames[round], round);
  return { result, run, rows };
};

describe("the lab's truth ladder", () => {
  it("moves a drifting player's truth bar as the session runs", async () => {
    const { result, rows } = await fixture();
    const roles: string[] = result.driftRoles;
    const fast = roles.indexOf("ImprovingFast");
    const slipping = roles.indexOf("Slipping");
    const steady = roles.indexOf("Steady");
    expect(fast).toBeGreaterThanOrEqual(0);
    expect(slipping).toBeGreaterThanOrEqual(0);

    const truthAt = (round: number, player: number) =>
      rows(round).find((r: any) => r.index === player)!.truthNorm;

    // The whole point: the bar tracks true skill, and true skill has changed.
    expect(truthAt(ROUNDS, fast)).toBeGreaterThan(truthAt(0, fast) + 0.05);
    expect(truthAt(ROUNDS, slipping)).toBeLessThan(truthAt(0, slipping));
    // A steady player is not dragged around by someone else's drift: the bar
    // scale is fixed for the run rather than renormalised each round.
    expect(truthAt(ROUNDS, steady)).toBeCloseTo(truthAt(0, steady), 6);
  }, 300_000);

  it("re-ranks as drifting players pass each other", async () => {
    const { result, rows } = await fixture();
    const fast = (result.driftRoles as string[]).indexOf("ImprovingFast");
    const rankOf = (round: number, player: number) =>
      rows(round).find((r: any) => r.index === player)!.rank;
    // The fast improver's tapered arc has made ~63% of its half-DUPR move by
    // round 40 — about 8 mu, several places in a typical field. Rows are
    // ordered by truth, so it must climb.
    expect(rankOf(ROUNDS, fast)).toBeLessThan(rankOf(0, fast));
  }, 300_000);

  it("agrees with the truth the metrics are scored against", async () => {
    const { result, rows } = await fixture();
    // Ordering by `truthNorm` at a round must reproduce the ladder `truthAt`
    // gives for that round — the same function `rankError` and `spearman` are
    // measured against. If these ever disagree, the panel is telling a
    // different story from the charts above it.
    for (const round of [0, 1, ROUNDS / 2, ROUNDS]) {
      const truth = SimLab.truthAt(result.truth, result.driftRoles, round);
      const expected = Array.from({ length: PLAYERS }, (_, i) => i).sort((a, b) => truth[b] - truth[a]);
      expect(rows(round).map((r: any) => r.index)).toEqual(expected);
    }
  }, 300_000);

  it("centres the rating bars when nothing is known yet", async () => {
    // A cold start has every mu identical, so the spread is zero. The bars
    // must not divide by it.
    const cold = await SimLab.run(
      "ColdStart", 1, 8, 2, 1, SimLab.typicalField, false, undefined,
    );
    for (const row of MatchmakingLab.ladderRows(cold, cold.runs[0].frames[0], 0)) {
      expect(row.ratingNorm).toBe(0.5);
      expect(Number.isFinite(row.truthNorm)).toBe(true);
      expect(Number.isFinite(row.sigmaNorm)).toBe(true);
    }
  }, 300_000);
});

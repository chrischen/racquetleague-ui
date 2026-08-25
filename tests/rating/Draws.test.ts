import { describe, expect, it } from "vitest";
import * as Rating from "../../src/lib/Rating.re.mjs";

const player = (id: string, mu: number) => ({
  data: undefined, id, intId: 0, name: id,
  rating: { mu, sigma: 25 / 3 },
  ratingOrdinal: 0, paid: false, gender: "Male", count: 0,
});

// Drawn (tied) scores, entered via the round-robin score UIs and rated with
// OpenSkill's rank option. Before this feature, a tie silently rated as a
// team2 victory — the third test pins that regression.
describe("draw (tie) rating", () => {
  it("rates a draw between unequal teams toward each other", () => {
    const strong = [player("a", 30), player("b", 30)];
    const weak = [player("c", 20), player("d", 20)];
    const result = Rating.CompletedMatch.rate([[strong, weak], [11, 11]]);
    const [newStrong, newWeak] = result;
    // Favourite drops, underdog rises — a draw is information.
    expect(newStrong[0].rating.mu).toBeLessThan(30);
    expect(newWeak[0].rating.mu).toBeGreaterThan(20);
  });

  it("leaves equal teams nearly unchanged on a draw, but tightens sigma", () => {
    const t1 = [player("a", 25), player("b", 25)];
    const t2 = [player("c", 25), player("d", 25)];
    const [n1, n2] = Rating.CompletedMatch.rate([[t1, t2], [7, 7]]);
    expect(n1[0].rating.mu).toBeCloseTo(25, 5);
    expect(n2[0].rating.mu).toBeCloseTo(25, 5);
    expect(n1[0].rating.sigma).toBeLessThan(25 / 3);
  });

  // The sharpest check that OpenSkill is really being given a draw rather than
  // a win in disguise: a draw is symmetric, so which team was passed first
  // cannot matter. Any win-shaped rating would flip when the teams swap.
  it("is independent of which team is passed first", () => {
    const strong = () => [player("a", 30), player("b", 30)];
    const weak = () => [player("c", 20), player("d", 20)];
    const muOf = (r: any[][], id: string) =>
      r.flat().find((p) => p.id === id).rating.mu;

    const asGiven = Rating.CompletedMatch.rate([[strong(), weak()], [11, 11]]);
    const swapped = Rating.CompletedMatch.rate([[weak(), strong()], [11, 11]]);

    expect(muOf(asGiven, "a")).toBe(muOf(swapped, "a"));
    expect(muOf(asGiven, "c")).toBe(muOf(swapped, "c"));
  });

  it("conserves total mu and lands between the two win outcomes", () => {
    const t1 = () => [player("a", 30), player("b", 30)];
    const t2 = () => [player("c", 20), player("d", 20)];
    const muOf = (r: any[][], id: string) =>
      r.flat().find((p) => p.id === id).rating.mu;
    const sumMu = (r: any[][]) =>
      r.flat().reduce((s: number, p: any) => s + p.rating.mu, 0);

    const draw = Rating.CompletedMatch.rate([[t1(), t2()], [11, 11]]);
    const team1Win = Rating.CompletedMatch.rate([[t1(), t2()], [11, 5]]);
    const team2Win = Rating.CompletedMatch.rate([[t1(), t2()], [5, 11]]);

    // Plackett-Luce moves rating between the teams, it does not create it.
    expect(sumMu(draw)).toBeCloseTo(100, 9);
    // A draw is a weaker result than winning and a better one than losing.
    expect(muOf(draw, "a")).toBeGreaterThan(muOf(team2Win, "a"));
    expect(muOf(draw, "a")).toBeLessThan(muOf(team1Win, "a"));
  });

  // 1/-1 is the "team tapped, no score entered" encoding the match card writes.
  // It differs by 2, so it must rate as an ordinary team1 win — if it ever fell
  // into the tie branch, every unscored-but-decided match would rate as a draw.
  it("does not treat the 1/-1 winner-only encoding as a draw", () => {
    const t1 = () => [player("a", 25), player("b", 25)];
    const t2 = () => [player("c", 25), player("d", 25)];
    const muOf = (r: any[][], id: string) =>
      r.flat().find((p) => p.id === id).rating.mu;

    const winnerOnly = Rating.CompletedMatch.rate([[t1(), t2()], [1, -1]]);
    const drawn = Rating.CompletedMatch.rate([[t1(), t2()], [11, 11]]);

    expect(muOf(winnerOnly, "a")).toBeGreaterThan(25);
    expect(muOf(winnerOnly, "a")).not.toBeCloseTo(muOf(drawn, "a"), 5);
  });

  it("does not treat a tie as a team2 win (the old silent behaviour)", () => {
    const t1 = [player("a", 25), player("b", 25)];
    const t2 = [player("c", 25), player("d", 25)];
    // rate() returns winner-first, so locate player "a" by id, the same way
    // the timeline replay consumes the result.
    const muOfA = (result: any[][]) =>
      result.flat().find((p) => p.id === "a").rating.mu;
    const tie = Rating.CompletedMatch.rate([[t1, t2], [9, 9]]);
    const team2win = Rating.CompletedMatch.rate([[t1, t2], [9, 11]]);
    // Under the old code these were identical; team1 must not lose mu on a tie.
    expect(muOfA(tie)).toBeGreaterThan(muOfA(team2win));
  });
});

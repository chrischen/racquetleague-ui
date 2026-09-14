// The timeline replay is a fold: each scored match is rated from the ratings
// the fold has reached, and a synced match is left out for any player whose
// base already carries it. Both are pinned here because both failed silently
// before — the replay rated from the ratings embedded at draw time, which go
// stale, and it folded synced matches onto a base the server had already moved.
import { describe, expect, it } from "vitest";
import * as Rating from "../../src/lib/Rating.re.mjs";
import { makePlayer, type Player } from "../solver/fixtures";

const pool = () => Array.from({ length: 4 }, (_, i) => makePlayer(i, { id: `p${i}` }));

const scored = (
  players: Player[],
  score: [number, number],
  opts: { synced?: boolean; id?: string } = {},
) => ({
  id: opts.id ?? "m",
  match: [
    [players[0], players[1]],
    [players[2], players[3]],
  ],
  score,
  createdAt: new Date(0),
  synced: opts.synced ?? false,
});

const replay = (rounds: any[][], players: Player[], baseIncludesSynced?: (id: string) => boolean) =>
  Rating.toPlayerStateWithAdjustments(rounds, players, [], baseIncludesSynced);

const mu = (players: Player[], id: string) => players.find((p) => p.id === id)!.rating.mu;

describe("rating from the fold's own state", () => {
  it("ignores the ratings embedded in the match when they have gone stale", () => {
    // The draw embedded everyone at 25, but by the time the match is replayed
    // p0 has been adjusted to 35. A favourite winning moves less than an
    // even match would — which is only visible if the fold used its own state.
    const drawn = pool();
    const round = [scored(drawn, [11, 5])];

    const base = pool().map((p) => (p.id === "p0" ? { ...p, rating: { mu: 35, sigma: p.rating.sigma } } : p));
    const fromRunning = replay([round], base);
    const fromSnapshot = Rating.CompletedMatch.rate([round[0].match, [11, 5]]);

    expect(mu(fromRunning, "p0")).toBeGreaterThan(35);
    expect(mu(fromRunning, "p0") - 35).toBeLessThan(fromSnapshot[0][0].rating.mu - 25);
  });

  it("carries a player's result from one round into the next", () => {
    const drawn = pool();
    const r1 = [scored(drawn, [11, 5], { id: "a" })];
    const r2 = [scored(drawn, [11, 5], { id: "b" })];

    const afterOne = replay([r1], pool());
    const afterTwo = replay([r1, r2], pool());

    // Two wins in a row: the second is rated from the post-first-win state, so
    // the total gain is not simply double the first.
    expect(mu(afterTwo, "p0")).toBeGreaterThan(mu(afterOne, "p0"));
    expect(mu(afterTwo, "p0") - 25).not.toBeCloseTo(2 * (mu(afterOne, "p0") - 25), 3);
  });
});

describe("leaving synced matches out for players the server already reached", () => {
  it("skips a synced match for flagged players only, and still counts the game", () => {
    const round = [scored(pool(), [11, 5], { synced: true })];
    const flagged = new Set(["p0", "p1"]);

    const state = replay([round], pool(), (id) => flagged.has(id));

    // Winners flagged: their base is trusted as-is. Losers not flagged: rated.
    expect(mu(state, "p0")).toBe(25);
    expect(mu(state, "p1")).toBe(25);
    expect(mu(state, "p2")).toBeLessThan(25);
    expect(state.every((p: Player) => p.count === 1)).toBe(true);
  });

  it("still folds an unsynced match for a flagged player", () => {
    const round = [scored(pool(), [11, 5], { synced: false })];

    const state = replay([round], pool(), () => true);

    expect(mu(state, "p0")).toBeGreaterThan(25);
  });

  it("folds everything when no predicate is given", () => {
    const round = [scored(pool(), [11, 5], { synced: true })];

    const state = replay([round], pool());

    expect(mu(state, "p0")).toBeGreaterThan(25);
  });
});

describe("seed adjustments tighten sigma", () => {
  const adjust = (playerId: string, differential: number, sigmaDifferential: number) => ({
    playerId, differential, sigmaDifferential, appliedAtRound: -1, timestamp: 1,
  });
  const state = (adjustments: any[]) =>
    Rating.toPlayerStateWithAdjustments([], pool(), adjustments);
  const sigma = (players: Player[], id: string) => players.find((p) => p.id === id)!.rating.sigma;

  it("moves mu and sigma together", () => {
    const after = state([adjust("p0", 3, -4)]);
    expect(mu(after, "p0")).toBe(28);
    expect(sigma(after, "p0")).toBeCloseTo(25 / 3 - 4, 9);
    expect(sigma(after, "p1")).toBeCloseTo(25 / 3, 9);
  });

  it("tightens even when mu is left alone, and never below the floor", () => {
    const after = state([adjust("p0", 0, -4), adjust("p0", 0, -20)]);
    expect(mu(after, "p0")).toBe(25);
    expect(sigma(after, "p0")).toBe(Rating.RatingAdjustment.minSigma);
  });

  it("records a tightening to the seeded sigma and never a loosening", () => {
    const d = Rating.RatingAdjustment.sigmaDifferentialFor;
    expect(25 / 3 + d(25 / 3)).toBeCloseTo(Rating.RatingAdjustment.seededSigma, 9);
    expect(d(2)).toBe(0);
  });

  it("makes a seeded player move less on their next result than an unseeded one", () => {
    // The point of the change: the seed survives the first game.
    const seeded = state([adjust("p0", 0, Rating.RatingAdjustment.sigmaDifferentialFor(25 / 3))]);
    const round = [scored(pool(), [11, 5])];
    const seededAfter = Rating.toPlayerStateWithAdjustments([round], seeded, []);
    const plainAfter = Rating.toPlayerStateWithAdjustments([round], pool(), []);
    expect(mu(seededAfter, "p0") - 25).toBeLessThan(mu(plainAfter, "p0") - 25);
    expect(mu(seededAfter, "p0")).toBeGreaterThan(25);
  });

  it("reads history written before the field existed as no sigma change", () => {
    const legacy = { playerId: "p0", differential: 1.5, appliedAtRound: 0, timestamp: 9 };
    const decoded = Rating.RatingAdjustment.fromJson(legacy);
    expect(decoded.sigmaDifferential).toBe(0);
    const json = JSON.parse(JSON.stringify(Rating.RatingAdjustment.toJson(adjust("p0", 1, -2))));
    expect(Rating.RatingAdjustment.fromJson(json)).toEqual(adjust("p0", 1, -2));
  });
});

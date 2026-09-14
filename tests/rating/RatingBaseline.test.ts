// Where each player started, kept per pool so the manager can tell a base the
// server has moved from one it has not. The awkward cases are the ones that
// matter: an event that predates the record, a late arrival, and a pool switch.
import { describe, expect, it } from "vitest";
import * as Baseline from "../../src/lib/rating/RatingBaseline.re.mjs";
import { makePlayer, type Player } from "../solver/fixtures";

const players = (mu: (i: number) => number = () => 25) =>
  Array.from({ length: 4 }, (_, i) => makePlayer(i, { id: `p${i}`, mu: mu(i) }));

const round = (drawn: Player[], score: [number, number] | undefined) => [
  {
    id: "m",
    match: [
      [drawn[0], drawn[1]],
      [drawn[2], drawn[3]],
    ],
    score,
    createdAt: new Date(0),
    synced: false,
  },
];

describe("tracking", () => {
  it("follows the base for unplayed players and freezes the rest", () => {
    const base = players((i) => 30 + i);
    const played = new Set(["p0"]);
    const existing = { p0: [25, 8], p1: [25, 8] };

    const next = Baseline.track(existing, base, played);

    expect(next).toBeDefined();
    expect(next!.p0).toEqual([25, 8]); // played: untouched
    expect(next!.p1).toEqual([31, 25 / 3]); // unplayed: moved with the base
    expect(next!.p2).toEqual([32, 25 / 3]); // newcomer: added
  });

  it("reports nothing to save when the base has not moved", () => {
    const base = players();
    const existing = Object.fromEntries(base.map((p) => [p.id, [25, 25 / 3]]));

    expect(Baseline.track(existing, base, new Set())).toBeUndefined();
  });
});

describe("recovering a baseline from an older event", () => {
  it("takes each player's rating at their earliest scored match, net of prior seed adjustments", () => {
    const drawnAt30 = players(() => 30);
    const drawnAt40 = players(() => 40);
    const rounds = [round(drawnAt30, [11, 5]), round(drawnAt40, [11, 5])];
    const adjustments = [
      { playerId: "p0", differential: 2, sigmaDifferential: 0, appliedAtRound: -1, timestamp: 1 },
      { playerId: "p0", differential: 5, sigmaDifferential: 0, appliedAtRound: 1, timestamp: 2 }, // after round 0: not subtracted
    ];

    const recovered = Baseline.reconstruct(rounds, adjustments);

    expect(recovered.p0).toEqual([28, 25 / 3]);
    expect(recovered.p1).toEqual([30, 25 / 3]);
  });

  it("gives back the sigma a seed adjustment tightened", () => {
    // The draw embedded the player at sigma 4 because a seed had tightened
    // them from the default; the pre-session sigma is the default.
    const drawn = players().map((p) => (p.id === "p0" ? { ...p, rating: { mu: 27, sigma: 4 } } : p));
    const recovered = Baseline.reconstruct(
      [round(drawn, [11, 5])],
      [{ playerId: "p0", differential: 2, sigmaDifferential: 4 - 25 / 3, appliedAtRound: -1, timestamp: 1 }],
    );
    expect(recovered.p0[0]).toBeCloseTo(25, 9);
    expect(recovered.p0[1]).toBeCloseTo(25 / 3, 9);
  });

  it("ignores unscored draws", () => {
    const recovered = Baseline.reconstruct([round(players(), undefined)], []);
    expect(Object.keys(recovered)).toHaveLength(0);
  });
});

describe("deciding whether the base already carries synced results", () => {
  it("says yes exactly when the base has moved off the baseline", () => {
    const base = players((i) => (i === 0 ? 27.3 : 25));
    const baseline = { p0: [25, 25 / 3], p1: [25, 25 / 3] };

    const includes = Baseline.baseIncludesSynced(baseline, base, false);

    expect(includes("p0")).toBe(true);
    expect(includes("p1")).toBe(false);
  });

  it("falls back to the pool's nature when there is nothing to compare", () => {
    const base = players();
    expect(Baseline.baseIncludesSynced({}, base, true)("p0")).toBe(true);
    expect(Baseline.baseIncludesSynced({}, base, false)("p0")).toBe(false);
  });
});

describe("codec", () => {
  it("round-trips per pool", () => {
    const store = { global: { p0: [25, 8], p1: [30.5, 7.25] }, club: { p0: [22, 8] } };
    const json = JSON.parse(JSON.stringify(Baseline.toJson(store)));
    expect(Baseline.fromJson(json)).toEqual(store);
  });

  it("drops entries it cannot read and survives garbage", () => {
    expect(Baseline.fromJson({ global: { p0: [25], p1: "x", p2: [1, 2] } })).toEqual({
      global: { p2: [1, 2] },
    });
    expect(Baseline.fromJson(42)).toEqual({});
  });
});

describe("applying the baseline for display", () => {
  it("substitutes the starting rating where one is known", () => {
    const shown = Baseline.applyTo({ p0: [20, 5] }, players());
    expect(shown[0].rating).toEqual({ mu: 20, sigma: 5 });
    expect(shown[1].rating.mu).toBe(25);
  });
});

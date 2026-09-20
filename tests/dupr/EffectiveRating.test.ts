// Which of a player's ratings the UI shows.
//
// A player can carry a pkuru rating earned here, a DUPR rating synced from
// their account, and a self-report. Every surface has to agree on which one
// it shows, and on the server the same order decides who may join a
// rating-gated event — so the precedence is pinned here.
import { describe, expect, it } from "vitest";
import * as EffectiveRating from "../../src/lib/EffectiveRating.re.mjs";
import * as RatingMod from "../../src/lib/Rating.re.mjs";

const { resolve, ofPkuru, ofDupr, ofSelf, mu, dupr, source, reliable } = EffectiveRating;

const pick = (
  pkuruMu?: number,
  duprDoubles?: number,
  duprReliable = true,
  selfMu?: number,
) => resolve(pkuruMu, duprDoubles, duprReliable, selfMu);

describe("resolve — the precedence order", () => {
  it("prefers the pkuru rating, which the player earned here", () => {
    const r = pick(30, 4.5, true, 20);
    expect(source(r)).toBe("Pkuru");
    expect(mu(r)).toBe(30);
    expect(dupr(r)).toBeCloseTo(RatingMod.guessDupr(30), 10);
  });

  it("falls back to DUPR, which is at least externally verified", () => {
    const r = pick(undefined, 4.5, true, 20);
    expect(source(r)).toBe("Dupr");
    expect(dupr(r)).toBe(4.5);
    expect(mu(r)).toBeCloseTo(RatingMod.duprToMu(4.5), 10);
  });

  it("falls back to the self-report only when nothing else is known", () => {
    const r = pick(undefined, undefined, true, 20);
    expect(source(r)).toBe("Self");
    expect(mu(r)).toBe(20);
  });

  it("reports nothing for a player with no rating at all", () => {
    expect(pick()).toBeUndefined();
  });

  it("carries DUPR's provisional flag through", () => {
    expect(reliable(pick(undefined, 4.5, false, undefined))).toBe(false);
    expect(reliable(pick(undefined, 4.5, true, undefined))).toBe(true);
  });

  it("treats a pkuru rating as reliable and a self-report as not", () => {
    expect(reliable(pick(30))).toBe(true);
    expect(reliable(pick(undefined, undefined, true, 20))).toBe(false);
  });
});

describe("constructors reject what is not a rating", () => {
  // These arrive from GraphQL, where a Float can be null. A rating that is
  // not a finite number must be absent, not a 0.0 player who would sort to
  // the bottom of every list and read as the weakest person there.
  it.each([["NaN", NaN], ["undefined", undefined], ["null", null]])(
    "rejects a pkuru rating of %s",
    (_l, v) => expect(ofPkuru(v as number)).toBeUndefined(),
  );

  it.each([["NaN", NaN], ["undefined", undefined], ["zero", 0], ["negative", -3]])(
    "rejects a DUPR rating of %s",
    (_l, v) => expect(ofDupr(v as number, true)).toBeUndefined(),
  );

  it("skips an unusable DUPR rating and keeps looking", () => {
    expect(source(pick(undefined, 0, true, 20))).toBe("Self");
  });

  it("keeps a self-rating of zero, a real point on the internal scale", () => {
    expect(mu(ofSelf(0))).toBe(0);
  });
});

describe("agreement with the server", () => {
  it("converts between scales exactly as the server does", () => {
    // Both sides carry the same calibration constants; a drift here would
    // show one number on the profile and gate on another.
    const r = pick(undefined, 4.25, true, undefined);
    expect(mu(r)).toBeCloseTo(RatingMod.duprToMu(4.25), 10);
    expect(dupr(r)).toBeCloseTo(4.25, 10);
  });
});

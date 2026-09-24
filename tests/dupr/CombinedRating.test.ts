// Which of a player's ratings the UI shows and seeds with.
//
// A player can carry a pkuru rating earned here, a DUPR rating synced from
// their account, and a self-report. The Round Robin tool seeds from this and
// every RSVP display shows it, so they have to agree — the rule is pinned
// here, and it mirrors the server's: between pkuru and DUPR, the one we are
// more sure of wins; the self-report only when neither exists. It is not the
// gate: the server's EffectiveRating decides who may join a rating-gated
// event, and that one ignores the self-report.
import { describe, expect, it } from "vitest";
import * as CombinedRating from "../../src/lib/CombinedRating.re.mjs";
import * as RatingMod from "../../src/lib/Rating.re.mjs";

const { resolve, ofPkuru, ofDupr, ofSelf, duprEstablished, mu, dupr, source, established, Policy } =
  CombinedRating;

// ReScript compiles labelled arguments positionally, in declaration order:
// pkuruMu, pkuruSigma, duprDoubles, duprReliability, duprReliable, selfMu.
const pick = (o: {
  pkuruMu?: number; pkuruSigma?: number; duprDoubles?: number;
  duprReliability?: number; duprReliable?: boolean; selfMu?: number;
}) => resolve(o.pkuruMu, o.pkuruSigma, o.duprDoubles, o.duprReliability, o.duprReliable ?? false, o.selfMu);

const CONFIDENT = 4.0; // sigma below the bar
const THIN = 8.0; // sigma above the bar

describe("resolve — when a player has both pkuru and DUPR", () => {
  it("keeps a currently confident pkuru rating over any DUPR rating", () => {
    const r = pick({ pkuruMu: 30, pkuruSigma: CONFIDENT, duprDoubles: 4.5, duprReliability: 40 });
    expect(source(r)).toBe("Pkuru");
    expect(mu(r)).toBe(30);
    expect(established(r)).toBe(true);
  });

  it("lets an established DUPR rating beat a pkuru rating that is not currently confident", () => {
    const r = pick({ pkuruMu: 30, pkuruSigma: THIN, duprDoubles: 4.5, duprReliability: 40 });
    expect(source(r)).toBe("Dupr");
    expect(dupr(r)).toBe(4.5);
    expect(established(r)).toBe(true);
  });

  it("falls back to the thin pkuru rating when DUPR is not established either", () => {
    const r = pick({ pkuruMu: 30, pkuruSigma: THIN, duprDoubles: 4.5, duprReliability: 5 });
    expect(source(r)).toBe("Pkuru");
    expect(established(r)).toBe(false);
  });

  it("treats a pkuru rating of unknown sigma as not currently confident", () => {
    // A caller without sigma to hand cannot vouch for the rating's currency.
    const r = pick({ pkuruMu: 30, duprDoubles: 4.5, duprReliability: 40 });
    expect(source(r)).toBe("Dupr");
  });

  it("uses DUPR's own reliable flag only when no score came", () => {
    expect(source(pick({ pkuruMu: 30, pkuruSigma: THIN, duprDoubles: 4.5, duprReliable: true }))).toBe("Dupr");
    expect(source(pick({ pkuruMu: 30, pkuruSigma: THIN, duprDoubles: 4.5, duprReliable: false }))).toBe("Pkuru");
    expect(source(pick({ pkuruMu: 30, pkuruSigma: THIN, duprDoubles: 4.5, duprReliability: 5, duprReliable: true }))).toBe("Pkuru");
  });
});

describe("resolve — the fallbacks", () => {
  it("uses whichever of pkuru or DUPR exists, however thin", () => {
    expect(source(pick({ pkuruMu: 30, pkuruSigma: THIN, selfMu: 20 }))).toBe("Pkuru");
    expect(source(pick({ duprDoubles: 4.5, duprReliability: 5, selfMu: 20 }))).toBe("Dupr");
  });

  it("falls back to the self-report only when nothing else is known", () => {
    const r = pick({ selfMu: 20 });
    expect(source(r)).toBe("Self");
    expect(mu(r)).toBe(20);
    expect(established(r)).toBe(false);
  });

  it("reports nothing for a player with no rating at all", () => {
    expect(pick({})).toBeUndefined();
  });

  it("skips an unusable DUPR rating and keeps looking", () => {
    expect(source(pick({ duprDoubles: 0, duprReliability: 99, selfMu: 20 }))).toBe("Self");
  });
});

describe("the bars", () => {
  it("match the server's: twice the certainty of a fresh rating, and the twenty-match mark", () => {
    expect(Policy.standard.establishedSigma).toBeCloseTo((25 / 3) / Math.SQRT2, 10);
    expect(Policy.standard.reliableScore).toBe(20);
  });

  it("are inclusive", () => {
    expect(established(ofPkuru(30, Policy.standard.establishedSigma))).toBe(true);
    expect(established(ofPkuru(30, Policy.standard.establishedSigma + 0.01))).toBe(false);
    expect(duprEstablished(20, false)).toBe(true);
    expect(duprEstablished(19.99, true)).toBe(false);
  });
});

describe("constructors reject what is not a rating", () => {
  it.each([["NaN", NaN], ["undefined", undefined], ["null", null]])(
    "rejects a pkuru rating of %s",
    (_l, v) => expect(ofPkuru(v as number, 4)).toBeUndefined(),
  );

  it.each([["NaN", NaN], ["undefined", undefined], ["zero", 0], ["negative", -3]])(
    "rejects a DUPR rating of %s",
    (_l, v) => expect(ofDupr(v as number, 50, true)).toBeUndefined(),
  );

  it("keeps a self-rating of zero, a real point on the internal scale", () => {
    expect(mu(ofSelf(0))).toBe(0);
  });
});

describe("agreement with the server", () => {
  it("converts between scales exactly as the server does", () => {
    const r = pick({ duprDoubles: 4.25, duprReliability: 30 });
    expect(mu(r)).toBeCloseTo(RatingMod.duprToMu(4.25), 10);
    expect(dupr(r)).toBeCloseTo(4.25, 10);
  });
});

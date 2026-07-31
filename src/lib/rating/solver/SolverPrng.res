// Deterministic, injectable PRNG (mulberry32).
//
// Anything that can change *which* match gets selected has to draw from here so
// that identical inputs produce identical rounds (see the determinism test).
// `Math.random` is still fine for cosmetic post-processing such as the team
// order swap in `Rating.generateMatches`.

type t = {next: unit => float}

let make: int => t = %raw(`function (seed) {
  let a = (seed >>> 0) || 0x9e3779b9;
  return {
    next: function () {
      a = (a + 0x6D2B79F5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    },
  };
}`)

// FNV-1a. Lets callers seed from a stable string (event id + round index) so a
// regenerated round reproduces exactly.
let hashString: string => int = %raw(`function (s) {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}`)

let fromSeedString = (seed: string): t => make(hashString(seed))

// Uniform in [0, 1).
let nextFloat = (t: t): float => t.next()

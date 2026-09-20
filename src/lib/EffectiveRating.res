/** The one rating the UI shows for a player, and where it came from.

 A player can carry up to three signals: the pkuru rating computed from
 matches played here, a DUPR rating synced from their linked DUPR account,
 and a self-report. Every surface that displays or falls back on a rating
 must pick the same one, so the precedence lives here and nowhere else:

     pkuru  >  DUPR  >  self-report

 The server applies the same order in `League.Domain.EffectiveRating`, which
 is what actually gates event entry; this mirror exists because the pkuru
 signal is context-scoped on the client (an RSVP's rating, an event rating,
 a rating for one activity) and so is not always a field on `User`.

 `t` is abstract: the only ways to obtain one are the constructors below, so
 no component can assemble a rating that skipped the precedence order. */
module Guarded: {
  type source = Pkuru | Dupr | Self
  type t
  /* Constructors — the only ways to obtain a t. */
  let ofPkuru: float => option<t>
  let ofDupr: (~doubles: float, ~reliable: bool) => option<t>
  let ofSelf: float => option<t>
  /* The single resolution point. First signal present wins. */
  let resolve: (
    ~pkuruMu: option<float>,
    ~duprDoubles: option<float>,
    ~duprReliable: bool,
    ~selfMu: option<float>,
  ) => option<t>
  /* Accessors */
  let mu: t => float
  let dupr: t => float
  let source: t => source
  /** Whether the source vouches for this number. A pkuru rating is earned
   here so it always counts; DUPR carries its own flag; a self-report is
   never more than a claim. Shown as "provisional" when false. */
  let reliable: t => bool
  /** Hook for weighting sources against each other later. Identity today. */
  let trust: t => t
} = {
  type source = Pkuru | Dupr | Self
  type t = {mu: float, dupr: float, source: source, reliable: bool}

  let trust = (r: t) => r

  /* These come from GraphQL, where a Float can arrive as null or NaN. A
     value that is not a finite number is no rating at all — and must not be
     treated as a 0.0 player, who would read as the weakest in every list. */
  let isFiniteNumber: float => bool = %raw(`(x) => typeof x === "number" && Number.isFinite(x)`)

  let ofPkuru = mu =>
    isFiniteNumber(mu)
      ? Some({mu, dupr: Rating.guessDupr(mu), source: Pkuru, reliable: true})
      : None
  let ofDupr = (~doubles, ~reliable) =>
    isFiniteNumber(doubles) && doubles > 0.0
      ? Some({mu: Rating.duprToMu(doubles), dupr: doubles, source: Dupr, reliable})
      : None
  let ofSelf = mu =>
    isFiniteNumber(mu)
      ? Some({mu, dupr: Rating.guessDupr(mu), source: Self, reliable: false})
      : None

  let resolve = (~pkuruMu, ~duprDoubles, ~duprReliable, ~selfMu) =>
    switch pkuruMu->Option.flatMap(ofPkuru) {
    | Some(_) as r => r
    | None =>
      switch duprDoubles->Option.flatMap(doubles => ofDupr(~doubles, ~reliable=duprReliable)) {
      | Some(_) as r => r
      | None => selfMu->Option.flatMap(ofSelf)
      }
    }->Option.map(trust)

  let mu = r => r.mu
  let dupr = r => r.dupr
  let source = r => r.source
  let reliable = r => r.reliable
}

include Guarded

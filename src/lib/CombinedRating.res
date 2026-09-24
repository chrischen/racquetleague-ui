/** The rating the UI shows a player at and seeds them with, and where it
 came from.

 A player can carry up to three signals: the pkuru rating computed from
 matches played here, a DUPR rating synced from their linked DUPR account,
 and a self-report. The Round Robin tool seeds from this, and every RSVP
 display shows it, so the number a player sees is the one they are seeded
 at.

 When a player has both a pkuru and a DUPR rating, the one we are more sure
 of wins, mirroring the server's `League.Domain.EffectiveRating`:

   - a pkuru rating that is *currently confident* (sigma at or below
     `Policy.establishedSigma`) beats DUPR;
   - otherwise an *established* DUPR rating (reliability score at or above
     `Policy.reliableScore`, or DUPR's own flag when no score came) beats a
     pkuru rating that is not currently confident — a sigma near the default
     means few matches or a long absence, and a live DUPR rating is then the
     better estimate;
   - otherwise pkuru.

 The self-report is used only when neither exists. `established` says
 whether the chosen rating clears its own bar; a self-report never does.

 This mirror exists because the pkuru signal is context-scoped on the client
 (an RSVP's rating, a club's rating pool) and so is not always a field on
 `User`. It is *not* what gates event entry — the server's EffectiveRating
 does that, and it deliberately ignores the self-report. Nothing on the
 client gates, so there is no client mirror of that type.

 `t` is abstract: the only ways to obtain one are the constructors below, so
 no component can assemble a rating that skipped the rule. */
module Guarded: {
  type source = Pkuru | Dupr | Self
  type t
  /** The two bars. Same values as the server's; keep them in sync. */
  module Policy: {
    type t = {establishedSigma: float, reliableScore: float}
    let standard: t
  }
  /* Constructors — the only ways to obtain a t. */
  let ofPkuru: (~mu: float, ~sigma: option<float>) => option<t>
  let ofDupr: (~doubles: float, ~reliability: option<float>, ~reliable: bool) => option<t>
  let ofSelf: float => option<t>
  /** Whether a DUPR rating clears the bar on its own, for surfaces that
   show the DUPR number directly. */
  let duprEstablished: (~reliability: option<float>, ~reliable: bool) => bool
  /** The single resolution point. Sigma and reliability may be omitted
   where a caller does not have them; a rating of unknown confidence is
   treated as not established. */
  let resolve: (
    ~pkuruMu: option<float>,
    ~pkuruSigma: float=?,
    ~duprDoubles: option<float>,
    ~duprReliability: float=?,
    ~duprReliable: bool,
    ~selfMu: option<float>,
  ) => option<t>
  /* Accessors */
  let mu: t => float
  let dupr: t => float
  let source: t => source
  let established: t => bool
} = {
  type source = Pkuru | Dupr | Self
  type t = {mu: float, dupr: float, source: source, established: bool}

  module Policy = {
    type t = {establishedSigma: float, reliableScore: float}
    /* sigma_ref / sqrt 2 — twice the certainty of a fresh rating — and the
       twenty-match mark on DUPR's 0-100 score. Both as on the server. */
    let standard = {establishedSigma: 25.0 /. 3.0 /. Math.sqrt(2.0), reliableScore: 20.0}
  }

  /* These come from GraphQL, where a Float can arrive as null or NaN. A
     value that is not a finite number is no rating at all — and must not be
     treated as a 0.0 player, who would read as the weakest in every list. */
  let isFiniteNumber: float => bool = %raw(`(x) => typeof x === "number" && Number.isFinite(x)`)

  let duprEstablished = (~reliability, ~reliable) =>
    switch reliability {
    | Some(score) if isFiniteNumber(score) => score >= Policy.standard.reliableScore
    | _ => reliable
    }

  let ofPkuru = (~mu, ~sigma) =>
    isFiniteNumber(mu)
      ? Some({
          mu,
          dupr: Rating.guessDupr(mu),
          source: Pkuru,
          established: switch sigma {
          | Some(s) if isFiniteNumber(s) => s <= Policy.standard.establishedSigma
          | _ => false
          },
        })
      : None
  let ofDupr = (~doubles, ~reliability, ~reliable) =>
    isFiniteNumber(doubles) && doubles > 0.0
      ? Some({
          mu: Rating.duprToMu(doubles),
          dupr: doubles,
          source: Dupr,
          established: duprEstablished(~reliability, ~reliable),
        })
      : None
  let ofSelf = mu =>
    isFiniteNumber(mu)
      ? Some({mu, dupr: Rating.guessDupr(mu), source: Self, established: false})
      : None

  let resolve = (~pkuruMu, ~pkuruSigma=?, ~duprDoubles, ~duprReliability=?, ~duprReliable, ~selfMu) => {
    let pkuru = pkuruMu->Option.flatMap(mu => ofPkuru(~mu, ~sigma=pkuruSigma))
    let dupr =
      duprDoubles->Option.flatMap(doubles =>
        ofDupr(~doubles, ~reliability=duprReliability, ~reliable=duprReliable)
      )
    switch (pkuru, dupr) {
    | (Some(p), Some(d)) => p.established ? Some(p) : d.established ? Some(d) : Some(p)
    | (Some(_) as p, None) => p
    | (None, Some(_) as d) => d
    | (None, None) => selfMu->Option.flatMap(ofSelf)
    }
  }

  let mu = r => r.mu
  let dupr = r => r.dupr
  let source = r => r.source
  let established = r => r.established
}

include Guarded

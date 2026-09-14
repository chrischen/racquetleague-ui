// The rating each player started the session on, remembered so the manager can
// tell whether the base rating it is currently handed already contains the
// results it has synced.
//
// WHY. `Rating.toPlayerStateWithAdjustments` folds the recorded matches onto
// the base ratings the manager builds its players from. Once scores are synced
// the server moves each player's rating and hands the new value straight back —
// in the mutation response, and again on every reload — so from then on the
// base already contains those matches, and folding them on a second time
// doubles every change. The club pool is the exception: it is read once and a
// sync does not move it, so there the base still excludes them and the fold has
// to apply them. Only a comparison tells the two apart: if a player's base still
// equals the rating they started on, nothing of theirs has landed in it.
//
// LIFECYCLE. Per pool (global / club), per player: while a player has no scored
// match in the history their entry follows the current base — the roster is
// still settling, seeds may switch pools, the club pool may still be loading.
// Their first score freezes it. A frozen entry is the only record of the
// pre-session rating, so nothing overwrites one.
//
// EXISTING EVENTS. An event that predates this record has played players with
// no entry. Their first scored match still embeds the rating they were drawn at,
// which is the base of the time plus any seed adjustment applied before that
// round (to mu, and to sigma), so the pre-session rating is recovered by
// subtracting those.
open Rating

// playerId -> (mu, sigma), for one pool
type t = Js.Dict.t<(float, float)>

// pool name -> baseline. Pools are named by `EventManagerPersistence.seedSourceToString`.
type store = Js.Dict.t<t>

let epsilon = 1e-9

let sameRating = ((mu1, sigma1): (float, float), (mu2, sigma2): (float, float)) =>
  Math.abs(mu1 -. mu2) < epsilon && Math.abs(sigma1 -. sigma2) < epsilon

let ratingOf = (p: Player.t<'a>) => (p.rating.mu, p.rating.sigma)

// Everyone with at least one scored match in the history.
let playersWithScores = (rounds: array<array<CompletedMatchEntity.t<'a>>>): Set.t<string> =>
  rounds
  ->Array.flatMap(round => round)
  ->Array.filter(m => m.score->Option.isSome)
  ->Array.flatMap(m => Match.players(m.match)->Array.map(p => p.id))
  ->Set.fromArray

// Follow the base for players who have not played yet; leave everyone else's
// entry alone. `None` when nothing moved, so the caller can skip the write.
let track = (baseline: t, ~players: array<Player.t<'a>>, ~played: Set.t<string>): option<t> => {
  let next = baseline->Js.Dict.entries->Js.Dict.fromArray
  let changed = ref(false)
  players->Array.forEach(p =>
    if !(played->Set.has(p.id)) {
      let current = ratingOf(p)
      switch next->Js.Dict.get(p.id) {
      | Some(existing) if sameRating(existing, current) => ()
      | _ => {
          next->Js.Dict.set(p.id, current)
          changed := true
        }
      }
    }
  )
  changed.contents ? Some(next) : None
}

// Recover a baseline for an event recorded before one was kept: each played
// player's rating at their earliest scored match, less the seed adjustments the
// draw had already applied to them.
let reconstruct = (
  ~rounds: array<array<CompletedMatchEntity.t<'a>>>,
  ~adjustments: array<RatingAdjustment.t>,
): t => {
  let baseline = Js.Dict.empty()
  rounds->Array.forEachWithIndex((round, roundIndex) =>
    round->Array.forEach(m =>
      if m.score->Option.isSome {
        Match.players(m.match)->Array.forEach(p =>
          if baseline->Js.Dict.get(p.id)->Option.isNone {
            let applied =
              adjustments->Array.filter(a => a.playerId == p.id && a.appliedAtRound < roundIndex)
            let muApplied = applied->Array.reduce(0., (sum, a) => sum +. a.differential)
            let sigmaApplied = applied->Array.reduce(0., (sum, a) => sum +. a.sigmaDifferential)
            baseline->Js.Dict.set(
              p.id,
              (p.rating.mu -. muApplied, p.rating.sigma -. sigmaApplied),
            )
          }
        )
      }
    )
  )
  baseline
}

// Whether a player's base already carries the results marked synced. `fallback`
// answers for a played player with no entry on this pool, which happens only
// after switching pools mid-session: the global pool is moved by every sync, the
// club pool is not.
let baseIncludesSynced = (
  baseline: t,
  ~players: array<Player.t<'a>>,
  ~fallback: bool,
): (string => bool) => {
  let base = players->Array.map(p => (p.id, ratingOf(p)))->Js.Dict.fromArray
  playerId =>
    switch (baseline->Js.Dict.get(playerId), base->Js.Dict.get(playerId)) {
    | (Some(started), Some(current)) => !sameRating(started, current)
    | _ => fallback
    }
}

// Players as they stood at the start of the session, for "change since" displays.
let applyTo = (baseline: t, players: array<Player.t<'a>>): array<Player.t<'a>> =>
  players->Array.map(p =>
    switch baseline->Js.Dict.get(p.id) {
    | Some((mu, sigma)) => {
        let rating = Rating.make(mu, sigma)
        {...p, rating, ratingOrdinal: rating->Rating.ordinal}
      }
    | None => p
    }
  )

// ---------------------------------------------------------------------------
// Codec: { "<pool>": { "<playerId>": [mu, sigma] } }
// ---------------------------------------------------------------------------

let toJson = (store: store): Js.Json.t =>
  store
  ->Js.Dict.entries
  ->Array.map(((pool, baseline)) => (
    pool,
    baseline
    ->Js.Dict.entries
    ->Array.map(((id, (mu, sigma))) => (
      id,
      [mu->Js.Json.number, sigma->Js.Json.number]->Js.Json.array,
    ))
    ->Js.Dict.fromArray
    ->Js.Json.object_,
  ))
  ->Js.Dict.fromArray
  ->Js.Json.object_

let fromJson = (json: Js.Json.t): store =>
  json
  ->Js.Json.decodeObject
  ->Option.mapOr(Js.Dict.empty(), pools =>
    pools
    ->Js.Dict.entries
    ->Array.map(((pool, entries)) => (
      pool,
      entries
      ->Js.Json.decodeObject
      ->Option.mapOr(Js.Dict.empty(), entries =>
        entries
        ->Js.Dict.entries
        ->Array.filterMap(((id, rating)) =>
          switch rating->Js.Json.decodeArray {
          | Some([mu, sigma]) =>
            switch (mu->Js.Json.decodeNumber, sigma->Js.Json.decodeNumber) {
            | (Some(mu), Some(sigma)) => Some((id, (mu, sigma)))
            | _ => None
            }
          | _ => None
          }
        )
        ->Js.Dict.fromArray
      ),
    ))
    ->Js.Dict.fromArray
  )

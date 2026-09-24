// Moving an event's recorded history between Event Manager instances.
//
// The manager keeps everything in this browser's IndexedDB, so a second device,
// a second organiser's tab, or rounds run under a different event have no way to
// reach each other. This module is the wire format and the merge rule for a
// copy-paste transfer between them.
//
// WHAT TRAVELS. Scored matches only, grouped into rounds, plus the rating
// adjustment history. Unscored rounds are draws the receiving instance will
// regenerate for itself from its own roster and ratings, and shipping them would
// only plant stale ones.
//
// HOW PLAYERS TRAVEL (v2). The roster is listed once and matches name players
// by id. The rating a player was drawn at is still needed on the other side —
// the solver reads each player's favoured / underdog side from the ratings
// stored in the match, and the import takes a player's first one as their
// session-start rating — but nearly all of them are reproducible: replaying
// the earlier scored matches with the same rating function lands on the same
// numbers. So a rating is written into a match only where the replay would
// not reach it: a first appearance, a session that re-fetched its base, a
// score corrected after the next draw. Play counts are rebuilt the same way.
// Measured on a 52-round, five-session export, this is a third of the v1 size.
// v1 files are still read.
//
// IDS ARE THE SYNC KEY. An exported match keeps its id, and `EventManager`'s
// `submitMatch` sends that id to the server as `syncId`. So a match that lands
// here by import and is later synced from this device cannot create a second
// server match, no matter which instance exported it. That is why nothing here
// mints a new UUID, and why imported matches arrive `synced: true`.
//
// KNOWN LIMITATION. `EventManagerPersistence` keys its `matches` rows by match
// id alone, device-wide. Importing a match that also lives under a *different*
// event on this same device re-keys that row to the importing event. Exporting
// between devices — the case this exists for — is unaffected.
open Rating

let format = "pkuru-event-history"
let version = 2
// v1 embedded a full player snapshot in every match. Exports of it exist, so
// it stays readable; everything written is v2.
let readableVersions = [1, 2]

// A decoded export. Rounds hold only scored matches, and their players carry
// `data: None` until `plan` re-attaches the local RSVP node by id.
type payload<'a> = {
  eventId: string,
  exportedAt: float,
  rounds: array<array<CompletedMatchEntity.t<'a>>>,
  adjustments: array<RatingAdjustment.t>,
}

// What an import would do, for the confirmation preview. Every "skipped" here is
// deliberate and silent in the UI beyond these numbers.
type counts = {
  importedRounds: int,
  importedMatches: int,
  skippedMissingPlayers: int,
  skippedDuplicates: int,
  skippedAdjustments: int,
}

// The complete post-import state. Nothing is applied here: the caller writes all
// five pieces in one commit, because they index each other.
type plan<'a> = {
  rounds: array<array<CompletedMatchEntity.t<'a>>>,
  adjustments: array<RatingAdjustment.t>,
  roundViolations: Js.Dict.t<array<SolverTypes.violation>>,
  currentRoundInt: int,
  counts: counts,
}

let isScored = (m: CompletedMatchEntity.t<'a>) => m.score->Option.isSome

let hasExportableHistory = (rounds: array<array<CompletedMatchEntity.t<'a>>>) =>
  rounds->Array.some(round => round->Array.some(isScored))

// ---------------------------------------------------------------------------
// Round index remapping
// ---------------------------------------------------------------------------
// A rating adjustment is filed against a round index: -1 means "before any round"
// (the seed adjustments shown on the round 0 screen) and k means "applied just
// before round k". Both export and import move rounds around, so every stored
// index has to move with them or an adjustment silently reattaches to the wrong
// round — and the manager filters on exact equality, so a wrong index is not a
// near miss, it is an adjustment that vanishes from the timeline.
//
// `newIndex` maps a live round index of the source to its index in the result;
// `afterAll` is where "after this source's last round" lands.
let remapRoundIndex = (k: int, ~len: int, ~newIndex: int => int, ~afterAll: int): int =>
  if k < 0 {
    // Seed adjustments stay seed adjustments only while nothing was inserted in
    // front of them; otherwise they belong just before the round they preceded.
    if len == 0 {
      -1
    } else {
      let n = newIndex(0)
      n == 0 ? -1 : n
    }
  } else if k < len {
    newIndex(k)
  } else {
    afterAll
  }

// ---------------------------------------------------------------------------
// Encode
// ---------------------------------------------------------------------------

// Both sides run this same replay over the ratings actually written, so what
// the importer reconstructs is what the exporter left out. The tolerance
// absorbs float noise between the manager's own fold and this one; a rating
// left out is reproduced to within it.
let ratingEpsilon = 1e-9

let sameRating = (a: Rating.t, b: Rating.t) =>
  Js.Math.abs_float(a.mu -. b.mu) < ratingEpsilon &&
    Js.Math.abs_float(a.sigma -. b.sigma) < ratingEpsilon

// One round of the replay: every match rated from the pre-round state, as the
// manager's fold does (`Rating.processTimelineEvent`).
let advance = (
  predicted: Map.t<string, Rating.t>,
  round: array<(Match.t<'a>, (float, float))>,
): unit =>
  round->Array.forEach(((match, score)) =>
    switch CompletedMatch.rate((match, Some(score))) {
    | Some(teams) => teams->Array.flat->Array.forEach(p => predicted->Map.set(p.id, p.rating))
    | None => ()
    }
  )

let rosterEntry = (p: Player.t<'a>): Js.Json.t => {
  let d = Js.Dict.empty()
  d->Js.Dict.set("id", p.id->Js.Json.string)
  d->Js.Dict.set("intId", p.intId->Int.toFloat->Js.Json.number)
  d->Js.Dict.set("name", p.name->Js.Json.string)
  d->Js.Dict.set("gender", p.gender->Gender.toInt->Int.toFloat->Js.Json.number)
  d->Js.Dict.set("paid", p.paid->Js.Json.boolean)
  d->Js.Json.object_
}

let ratingToJson = (r: Rating.t): Js.Json.t =>
  [r.mu->Js.Json.number, r.sigma->Js.Json.number]->Js.Json.array

let encode = (
  ~eventId: string,
  ~exportedAt: float,
  ~rounds: array<array<CompletedMatchEntity.t<'a>>>,
  ~adjustments: array<RatingAdjustment.t>,
): string => {
  // Keep only scored matches, and only rounds left with one. `keptIdx` records
  // which original round each survivor was, so adjustments can be compacted onto
  // the shorter list.
  let keptIdx = []
  let keptRounds = []
  rounds->Array.forEachWithIndex((round, i) => {
    let scored = round->Array.filter(isScored)
    if scored->Array.length > 0 {
      keptIdx->Array.push(i)
      keptRounds->Array.push(scored)
    }
  })

  let compact = k =>
    remapRoundIndex(
      k,
      ~len=rounds->Array.length,
      ~newIndex=idx => keptIdx->Array.filter(i => i < idx)->Array.length,
      ~afterAll=keptRounds->Array.length,
    )

  // Roster in order of first appearance; ratings carried only where the
  // replay would not reproduce them (see the module comment).
  let roster = []
  let listed = Set.make()
  let predicted: Map.t<string, Rating.t> = Map.make()

  let roundsJson =
    keptRounds
    ->Array.map(round => {
      let written = []
      let matches =
        round->Array.filterMap(m =>
          m.score->Option.map(score => {
            let (team1, team2) = m.match
            let (s1, s2) = score
            let carried = Js.Dict.empty()
            // What this player is written at: the replay's value when it
            // already matches the snapshot, otherwise the snapshot itself,
            // which then travels with the match.
            let write = (team: Team.t<'a>) =>
              team->Array.map(p => {
                if !(listed->Set.has(p.id)) {
                  listed->Set.add(p.id)->ignore
                  roster->Array.push(rosterEntry(p))
                }
                switch predicted->Map.get(p.id) {
                | Some(r) if sameRating(r, p.rating) => {...p, rating: r}
                | _ => {
                    carried->Js.Dict.set(p.id, ratingToJson(p.rating))
                    p
                  }
                }
              })
            let written1 = write(team1)
            let written2 = write(team2)
            written->Array.push(((written1, written2), score))
            let ids = (team: Team.t<'a>) =>
              team->Array.map(p => p.id->Js.Json.string)->Js.Json.array
            let d = Js.Dict.empty()
            d->Js.Dict.set("id", m.id->Js.Json.string)
            d->Js.Dict.set("team1", ids(written1))
            d->Js.Dict.set("team2", ids(written2))
            d->Js.Dict.set("score", [s1->Js.Json.number, s2->Js.Json.number]->Js.Json.array)
            d->Js.Dict.set("createdAt", m.createdAt->Js.Date.getTime->Js.Json.number)
            if carried->Js.Dict.keys->Array.length > 0 {
              d->Js.Dict.set("ratings", carried->Js.Json.object_)
            }
            d->Js.Json.object_
          })
        )
      advance(predicted, written)
      let d = Js.Dict.empty()
      d->Js.Dict.set("matches", matches->Js.Json.array)
      d->Js.Json.object_
    })
    ->Js.Json.array

  let root = Js.Dict.empty()
  root->Js.Dict.set("format", format->Js.Json.string)
  root->Js.Dict.set("version", version->Int.toFloat->Js.Json.number)
  root->Js.Dict.set("eventId", eventId->Js.Json.string)
  root->Js.Dict.set("exportedAt", exportedAt->Js.Json.number)
  root->Js.Dict.set("players", roster->Js.Json.array)
  root->Js.Dict.set("rounds", roundsJson)
  root->Js.Dict.set(
    "adjustments",
    adjustments
    ->Array.map(a => {...a, appliedAtRound: compact(a.appliedAtRound)})
    ->Array.map(RatingAdjustment.toJson)
    ->Js.Json.array,
  )
  root->Js.Json.object_->Js.Json.stringify
}

// ---------------------------------------------------------------------------
// Decode
// ---------------------------------------------------------------------------
// Deliberately strict: a half-readable export becomes an error rather than a
// quietly shortened import, because the only thing standing between the user and
// a wrong merge is the preview's counts, and those have to be trustworthy.

let corruptMessage = "This export is incomplete or corrupt."

exception Invalid(string)

let asObject = (json: Js.Json.t): Js.Dict.t<Js.Json.t> =>
  switch json->Js.Json.decodeObject {
  | Some(o) => o
  | None => raise(Invalid(corruptMessage))
  }

let asArray = (json: Js.Json.t): array<Js.Json.t> =>
  switch json->Js.Json.decodeArray {
  | Some(a) => a
  | None => raise(Invalid(corruptMessage))
  }

let asString = (json: Js.Json.t): string =>
  switch json->Js.Json.decodeString {
  | Some(s) => s
  | None => raise(Invalid(corruptMessage))
  }

let asNumber = (json: Js.Json.t): float =>
  switch json->Js.Json.decodeNumber {
  | Some(n) => n
  | None => raise(Invalid(corruptMessage))
  }

let required = (obj: Js.Dict.t<Js.Json.t>, key: string): Js.Json.t =>
  switch obj->Js.Dict.get(key) {
  | Some(v) => v
  | None => raise(Invalid(corruptMessage))
  }

let decodeTeam = (json: Js.Json.t): array<Player.t<'a>> => {
  let players =
    json
    ->asArray
    ->Array.map(p =>
      switch p->Json.Decode.decode(Player.decodePlayer()) {
      | Ok(player) => player
      | Error(_) => raise(Invalid(corruptMessage))
      }
    )
  if players->Array.length == 0 {
    raise(Invalid(corruptMessage))
  }
  players
}

let decodeScore = (obj: Js.Dict.t<Js.Json.t>): (float, float) =>
  switch obj->required("score")->asArray {
  | [a, b] => (a->asNumber, b->asNumber)
  | _ => raise(Invalid(corruptMessage))
  }

// v1: every match carries full player snapshots.
let decodeMatchV1 = (json: Js.Json.t): CompletedMatchEntity.t<'a> => {
  let obj = json->asObject
  {
    CompletedMatchEntity.id: obj->required("id")->asString,
    match: (obj->required("team1")->decodeTeam, obj->required("team2")->decodeTeam),
    score: Some(decodeScore(obj)),
    createdAt: obj->required("createdAt")->asNumber->Js.Date.fromFloat,
    // Imported history came from an instance that owns the sync for it, and the
    // preserved id makes a second submission a no-op server-side anyway.
    synced: true,
  }
}

let decodeRoundsV1 = (root: Js.Dict.t<Js.Json.t>): array<array<CompletedMatchEntity.t<'a>>> =>
  root
  ->required("rounds")
  ->asArray
  ->Array.map(r => r->asObject->required("matches")->asArray->Array.map(decodeMatchV1))
  ->Array.filter(r => r->Array.length > 0)

let asBool = (json: Js.Json.t): bool =>
  switch json->Js.Json.decodeBoolean {
  | Some(b) => b
  | None => raise(Invalid(corruptMessage))
  }

// v2: who each player is, once. Ratings and counts are filled in per match.
let decodeRoster = (json: Js.Json.t): Js.Dict.t<Player.t<'a>> => {
  let roster = Js.Dict.empty()
  json
  ->asArray
  ->Array.forEach(entry => {
    let o = entry->asObject
    let rating = Rating.makeDefault()
    let p: Player.t<'a> = {
      data: None,
      id: o->required("id")->asString,
      intId: o->required("intId")->asNumber->Float.toInt,
      name: o->required("name")->asString,
      rating,
      ratingOrdinal: rating->Rating.ordinal,
      paid: o->required("paid")->asBool,
      gender: o->required("gender")->asNumber->Float.toInt->Gender.fromInt,
      count: 0,
    }
    roster->Js.Dict.set(p.id, p)
  })
  roster
}

let decodeRatingPair = (json: Js.Json.t): Rating.t =>
  switch json->asArray {
  | [mu, sigma] => Rating.make(mu->asNumber, sigma->asNumber)
  | _ => raise(Invalid(corruptMessage))
  }

// v2: matches name players by id. Each player's rating at the draw is the one
// the file carries for that match, else what replaying the earlier rounds
// produces — the mirror of the encoder. A player with neither is an export
// this reader cannot trust. Counts are the scored matches so far, this one
// included, which is what a draw stamps on its players.
let decodeRoundsV2 = (root: Js.Dict.t<Js.Json.t>): array<array<CompletedMatchEntity.t<'a>>> => {
  let roster = root->required("players")->decodeRoster
  let predicted: Map.t<string, Rating.t> = Map.make()
  let played: Map.t<string, int> = Map.make()
  root
  ->required("rounds")
  ->asArray
  ->Array.map(r => {
    let entries =
      r
      ->asObject
      ->required("matches")
      ->asArray
      ->Array.map(json => {
        let obj = json->asObject
        let carried =
          obj->Js.Dict.get("ratings")->Option.map(asObject)->Option.getOr(Js.Dict.empty())
        let team = key =>
          obj
          ->required(key)
          ->asArray
          ->Array.map(idJson => {
            let id = idJson->asString
            let base = switch roster->Js.Dict.get(id) {
            | Some(p) => p
            | None => raise(Invalid(corruptMessage))
            }
            let rating = switch (carried->Js.Dict.get(id), predicted->Map.get(id)) {
            | (Some(r), _) => decodeRatingPair(r)
            | (None, Some(r)) => r
            | (None, None) => raise(Invalid(corruptMessage))
            }
            let count = played->Map.get(id)->Option.getOr(0) + 1
            played->Map.set(id, count)
            {...base, rating, ratingOrdinal: rating->Rating.ordinal, count}
          })
        let team1 = team("team1")
        let team2 = team("team2")
        if team1->Array.length == 0 || team2->Array.length == 0 {
          raise(Invalid(corruptMessage))
        }
        let score = decodeScore(obj)
        let entity: CompletedMatchEntity.t<'a> = {
          id: obj->required("id")->asString,
          match: (team1, team2),
          score: Some(score),
          createdAt: obj->required("createdAt")->asNumber->Js.Date.fromFloat,
          synced: true,
        }
        (entity, score)
      })
    advance(predicted, entries->Array.map(((e, score)) => (e.match, score)))
    entries->Array.map(((e, _)) => e)
  })
  ->Array.filter(r => r->Array.length > 0)
}

let decode = (text: string): result<payload<'a>, string> =>
  try {
    let parsed = try text->Js.Json.parseExn catch {
    | _ => raise(Invalid("That is not valid JSON."))
    }
    let root = switch parsed->Js.Json.decodeObject {
    | Some(o) => o
    | None => raise(Invalid("That is not an event history export."))
    }

    switch root->Js.Dict.get("format")->Option.flatMap(v => v->Js.Json.decodeString) {
    | Some(f) if f == format => ()
    | _ => raise(Invalid("That is not an event history export."))
    }

    // Hard version gate for anything newer than this build writes — same rule
    // as the solver's stored weight configs. Re-export from the newer build
    // instead. Older versions this build knows how to read are decoded as such.
    let fileVersion =
      root
      ->Js.Dict.get("version")
      ->Option.flatMap(v => v->Js.Json.decodeNumber)
      ->Option.mapOr(0, Float.toInt)
    if !(readableVersions->Array.includes(fileVersion)) {
      raise(
        Invalid(
          "This export is format v" ++
          fileVersion->Int.toString ++
          ", but this version of the app reads v" ++
          version->Int.toString ++ ".",
        ),
      )
    }

    let rounds = fileVersion == 1 ? decodeRoundsV1(root) : decodeRoundsV2(root)

    let adjustments =
      root
      ->required("adjustments")
      ->asArray
      ->Array.map(a =>
        switch a->RatingAdjustment.fromJson {
        | Some(adj) => adj
        | None => raise(Invalid(corruptMessage))
        }
      )

    Ok({
      eventId: root->required("eventId")->asString,
      exportedAt: root->required("exportedAt")->asNumber,
      rounds,
      adjustments,
    })
  } catch {
  | Invalid(message) => Error(message)
  | _ => Error(corruptMessage)
  }

// ---------------------------------------------------------------------------
// Plan an import
// ---------------------------------------------------------------------------

// Carry a decoded player's recorded snapshot — the rating, name and play count as
// they stood when the match was played (rebuilt on decode for v2 files) — while
// taking the live RSVP node from the local player of the same id. The timeline
// replay rates from its own running state, but the solver's side history and
// the session-start baseline read these. Only `data` mentions the type
// parameter, so this is the one field that changes.
let hydratePlayer = (player: Player.t<'b>, local: Player.t<'a>): Player.t<'a> => {
  Player.data: local.data,
  id: player.id,
  intId: player.intId,
  name: player.name,
  rating: player.rating,
  ratingOrdinal: player.ratingOrdinal,
  paid: player.paid,
  gender: player.gender,
  count: player.count,
}

let roundTime = (round: array<CompletedMatchEntity.t<'a>>): option<float> =>
  round->Array.reduce(None, (acc, m) => {
    let t = m.createdAt->Js.Date.getTime
    switch acc {
    | Some(best) if best <= t => Some(best)
    | _ => Some(t)
    }
  })

let plan = (
  ~existingRounds: array<array<CompletedMatchEntity.t<'a>>>,
  ~existingAdjustments: array<RatingAdjustment.t>,
  ~existingRoundViolations: Js.Dict.t<array<SolverTypes.violation>>,
  ~currentRoundInt: int,
  ~players: array<Player.t<'a>>,
  ~payload: payload<'b>,
): plan<'a> => {
  let byId = players->Array.map(p => (p.id, p))->Js.Dict.fromArray
  let seen = existingRounds->Array.flatMap(r => r->Array.map(m => m.id))->Set.fromArray
  let existingCount = existingRounds->Array.length
  // The mount effect corrects an out-of-range current round, but an import can
  // run before it does.
  let cur = Math.Int.max(0, Math.Int.min(currentRoundInt, existingCount))

  // (1) Filter the payload down to what this instance can actually accept, in
  // payload order. `keptPayloadIdx` remembers which payload round each survivor
  // was, so the payload's own adjustment indices still mean something afterwards.
  let skippedDuplicates = ref(0)
  let skippedMissingPlayers = ref(0)
  let keptPayloadIdx = []
  let imported = []

  payload.rounds->Array.forEachWithIndex((round, payloadIndex) => {
    let kept = round->Array.filterMap(m =>
      if seen->Set.has(m.id) {
        // Re-importing the same export, or a match this instance already has
        // from elsewhere. Either way it is already in the timeline.
        skippedDuplicates := skippedDuplicates.contents + 1
        None
      } else {
        let (team1, team2) = m.match
        // The annotation is load-bearing: `id` is a field of several records in
        // `Rating`, and without it the parameter resolves to the wrong one.
        let hydrate = team =>
          team->Array.map((p: Player.t<_>) =>
            byId->Js.Dict.get(p.id)->Option.map(local => hydratePlayer(p, local))
          )
        let hydrated1 = hydrate(team1)
        let hydrated2 = hydrate(team2)
        if hydrated1->Array.every(Option.isSome) && hydrated2->Array.every(Option.isSome) {
          seen->Set.add(m.id)->ignore
          let entity: CompletedMatchEntity.t<'a> = {
            id: m.id,
            match: (hydrated1->Array.filterMap(x => x), hydrated2->Array.filterMap(x => x)),
            score: m.score,
            createdAt: m.createdAt,
            synced: true,
          }
          Some(entity)
        } else {
          // Someone who is not on this event's roster. Silently dropped: the
          // alternative is inventing a player, and their rating would then move
          // on results this instance cannot show.
          skippedMissingPlayers := skippedMissingPlayers.contents + 1
          None
        }
      }
    )
    if kept->Array.length > 0 {
      keptPayloadIdx->Array.push(payloadIndex)
      imported->Array.push(kept)
    }
  })

  let importedCount = imported->Array.length

  // (2) Split the local rounds into recorded history and the unscored suffix.
  //
  // Imported rounds are all scored, so they merge only into the history prefix.
  // Merging across the whole list instead would put generated draws in front of
  // them: a generated round is stamped event-start + 10 minutes per round, while
  // a round's stamp is rewritten to "now" the moment a score is entered, so the
  // draws waiting to be played carry the *earliest* timestamps in the list. The
  // suffix is re-appended untouched and regenerated by the caller's history bump.
  let lastScored = ref(-1)
  existingRounds->Array.forEachWithIndex((round, i) =>
    if round->Array.some(isScored) {
      lastScored := i
    }
  )
  let head = Math.Int.max(cur, lastScored.contents + 1)

  // (3) A round's position in time is its earliest match. An empty round — the
  // loader can produce one — inherits its predecessor's stamp so it stays put.
  let tsE = []
  existingRounds->Array.forEachWithIndex((round, i) =>
    tsE->Array.push(
      switch roundTime(round) {
      | Some(t) => t
      | None => i == 0 ? Float.Constants.negativeInfinity : tsE->Array.getUnsafe(i - 1)
      },
    )
  )
  let tsI = imported->Array.map(round => roundTime(round)->Option.getOr(0.))

  // (4) Stable two-way merge, ties to the local rounds. Rounds are units and
  // never split, and neither source is reordered internally — which matters
  // because `createdAt` is not monotonic within a source.
  let merged = []
  let mapE = Array.make(~length=existingCount, 0)
  let mapI = Array.make(~length=importedCount, 0)
  let i = ref(0)
  let j = ref(0)

  while i.contents < head || j.contents < importedCount {
    let takeExisting =
      j.contents >= importedCount ||
        (i.contents < head &&
        tsE->Array.getUnsafe(i.contents) <= tsI->Array.getUnsafe(j.contents))
    if takeExisting {
      mapE->Array.set(i.contents, merged->Array.length)
      merged->Array.push(existingRounds->Array.getUnsafe(i.contents))
      i := i.contents + 1
    } else {
      mapI->Array.set(j.contents, merged->Array.length)
      merged->Array.push(imported->Array.getUnsafe(j.contents))
      j := j.contents + 1
    }
  }

  // (5) Re-append the unscored suffix.
  let shift = merged->Array.length - head
  for k in head to existingCount - 1 {
    mapE->Array.set(k, k + shift)
    merged->Array.push(existingRounds->Array.getUnsafe(k))
  }

  // Remaps for each source.
  let afterAllE =
    existingCount > 0 ? mapE->Array.getUnsafe(existingCount - 1) + 1 : merged->Array.length
  let remapE = k =>
    remapRoundIndex(k, ~len=existingCount, ~newIndex=idx => mapE->Array.getUnsafe(idx), ~afterAll=afterAllE)

  let afterAllI =
    importedCount > 0 ? mapI->Array.getUnsafe(importedCount - 1) + 1 : merged->Array.length
  // An imported adjustment indexes the *payload's* rounds, and step (1) may have
  // dropped some of those. Land it in front of the first surviving round at or
  // after its index, which is where it sat in the source timeline.
  let newIndexI = k => {
    let q = keptPayloadIdx->Array.findIndex(p => p >= k)
    q >= 0 ? mapI->Array.getUnsafe(q) : afterAllI
  }
  let remapI = k =>
    remapRoundIndex(k, ~len=payload.rounds->Array.length, ~newIndex=newIndexI, ~afterAll=afterAllI)

  let existingRemapped =
    existingAdjustments->Array.map(a => {...a, appliedAtRound: remapE(a.appliedAtRound)})

  let skippedAdjustments = ref(0)
  let importedAdjustments = []
  payload.adjustments->Array.forEach(a =>
    if byId->Js.Dict.get(a.playerId)->Option.isNone {
      skippedAdjustments := skippedAdjustments.contents + 1
    } else {
      let moved = {...a, appliedAtRound: remapI(a.appliedAtRound)}
      // Identity deliberately excludes the round index. `timestamp` is the
      // moment the organiser saved the adjustment, shared across the batch, so
      // these three fields name one act of adjustment — while the round index is
      // the one thing the two timelines can legitimately disagree about, since
      // each files it against its own rounds. Including it would let the same
      // adjustment arrive twice and double the rating change, which is exactly
      // what happens on a partial re-import.
      let duplicate =
        existingRemapped
        ->Array.concat(importedAdjustments)
        ->Array.some(other =>
          other.playerId == moved.playerId &&
          other.timestamp == moved.timestamp &&
          other.differential == moved.differential
        )
      if duplicate {
        skippedAdjustments := skippedAdjustments.contents + 1
      } else {
        importedAdjustments->Array.push(moved)
      }
    }
  )

  // Round-level solver warnings are keyed by round index, so they move with the
  // rounds they describe. Match-level ones are keyed by match id and need nothing.
  let roundViolations = Js.Dict.empty()
  existingRoundViolations
  ->Js.Dict.entries
  ->Array.forEach(((key, violations)) =>
    switch key->Int.fromString {
    | Some(idx) if idx >= 0 && idx < existingCount =>
      roundViolations->Js.Dict.set(mapE->Array.getUnsafe(idx)->Int.toString, violations)
    | _ => ()
    }
  )

  // Stay on the round the user was watching, but never leave an imported round
  // ahead of it: generation replaces everything from the current round onward, so
  // a scored round parked in the future would be regenerated away.
  let fromExisting = cur > 0 ? mapE->Array.getUnsafe(cur - 1) + 1 : 0
  let fromImported = importedCount > 0 ? mapI->Array.getUnsafe(importedCount - 1) + 1 : 0

  {
    rounds: merged,
    adjustments: existingRemapped->Array.concat(importedAdjustments),
    roundViolations,
    currentRoundInt: Math.Int.max(fromExisting, fromImported),
    counts: {
      importedRounds: importedCount,
      importedMatches: imported->Array.reduce(0, (sum, r) => sum + r->Array.length),
      skippedMissingPlayers: skippedMissingPlayers.contents,
      skippedDuplicates: skippedDuplicates.contents,
      skippedAdjustments: skippedAdjustments.contents,
    },
  }
}

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
let version = 1

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

let matchToJson = (m: CompletedMatchEntity.t<'a>, score: (float, float)): Js.Json.t => {
  let (team1, team2) = m.match
  let (s1, s2) = score
  let d = Js.Dict.empty()
  d->Js.Dict.set("id", m.id->Js.Json.string)
  d->Js.Dict.set("team1", team1->Array.map(Player.toJson)->Js.Json.array)
  d->Js.Dict.set("team2", team2->Array.map(Player.toJson)->Js.Json.array)
  d->Js.Dict.set("score", [s1->Js.Json.number, s2->Js.Json.number]->Js.Json.array)
  d->Js.Dict.set("createdAt", m.createdAt->Js.Date.getTime->Js.Json.number)
  d->Js.Json.object_
}

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

  let roundsJson =
    keptRounds
    ->Array.map(round => {
      let d = Js.Dict.empty()
      d->Js.Dict.set(
        "matches",
        round
        ->Array.filterMap(m => m.score->Option.map(score => matchToJson(m, score)))
        ->Js.Json.array,
      )
      d->Js.Json.object_
    })
    ->Js.Json.array

  let root = Js.Dict.empty()
  root->Js.Dict.set("format", format->Js.Json.string)
  root->Js.Dict.set("version", version->Int.toFloat->Js.Json.number)
  root->Js.Dict.set("eventId", eventId->Js.Json.string)
  root->Js.Dict.set("exportedAt", exportedAt->Js.Json.number)
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

let decodeMatch = (json: Js.Json.t): CompletedMatchEntity.t<'a> => {
  let obj = json->asObject
  let score = switch obj->required("score")->asArray {
  | [a, b] => (a->asNumber, b->asNumber)
  | _ => raise(Invalid(corruptMessage))
  }
  {
    CompletedMatchEntity.id: obj->required("id")->asString,
    match: (obj->required("team1")->decodeTeam, obj->required("team2")->decodeTeam),
    score: Some(score),
    createdAt: obj->required("createdAt")->asNumber->Js.Date.fromFloat,
    // Imported history came from an instance that owns the sync for it, and the
    // preserved id makes a second submission a no-op server-side anyway.
    synced: true,
  }
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

    // Hard version gate, no migrations — same rule as the solver's stored weight
    // configs. Re-export from the newer build instead.
    let fileVersion =
      root
      ->Js.Dict.get("version")
      ->Option.flatMap(v => v->Js.Json.decodeNumber)
      ->Option.mapOr(0, Float.toInt)
    if fileVersion != version {
      raise(
        Invalid(
          "This export is format v" ++
          fileVersion->Int.toString ++
          ", but this version of the app reads v" ++
          version->Int.toString ++ ".",
        ),
      )
    }

    let rounds =
      root
      ->required("rounds")
      ->asArray
      ->Array.map(r => r->asObject->required("matches")->asArray->Array.map(decodeMatch))
      ->Array.filter(r => r->Array.length > 0)

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
// they stood when the match was played, which is what the timeline replay rates
// from — while taking the live RSVP node from the local player of the same id.
// Only `data` mentions the type parameter, so this is the one field that changes.
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

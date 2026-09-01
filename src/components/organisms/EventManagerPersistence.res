// EventManager Local Persistence Module
// Handles TinyBase synchronization for EventManager matches
// Stores match data with full player objects (ratings change per round)

open Rating

// Initialize TinyBase store at module level for event state
let eventStore = TinyBase.createStore()

// ---------------------------------------------------------------------------
// Persistence health
// ---------------------------------------------------------------------------
// Every save* function below writes to the in-memory TinyBase store, which
// cannot fail. The real write to IndexedDB happens asynchronously inside the
// persister, and TinyBase swallows those errors by design. So this is the only
// layer that can tell whether an event is actually being saved — without it a
// blocked or full IndexedDB looks identical to a healthy one until the organiser
// refreshes mid-event and finds an empty tournament.

type failureKind =
  | StorageUnavailable // IndexedDB missing or blocked — private window, blocked site data
  | QuotaExceeded // out of space
  | UnknownFailure

type health = {
  activity: [#idle | #loading | #saving],
  ready: bool, // autosave actually started
  failure: option<(failureKind, string)>, // kind for the copy, raw detail for the console
}

// Errors reach us from two channels with different shapes: onIgnoredError hands
// over whatever IndexedDB threw (DOMException, Error, string), while Promise.catch
// wraps that in ReScript's {RE_EXN_ID, _1} envelope. Unwrap both in JS rather than
// guessing a ReScript shape — otherwise the envelope stringifies to "[object Object]"
// and classifyError can never match.
let describeError: 'a => string = %raw(`function(e) {
  if (e === null || e === undefined) return "Unknown storage error"
  if (typeof e === "string") return e
  var exnId = e.RE_EXN_ID
  if (exnId !== undefined) {
    if (e._1 === undefined || e._1 === null) return String(exnId)
    e = e._1
    if (typeof e === "string") return e
  }
  var name = e.name || ""
  var message = e.message || ""
  if (name && message) return name + ": " + message
  return name || message || String(e)
}`)

let classifyError = (detail: string): failureKind => {
  let lower = detail->String.toLowerCase
  if lower->String.includes("quotaexceeded") || lower->String.includes("quota") {
    QuotaExceeded
  } else if (
    lower->String.includes("securityerror") ||
    lower->String.includes("invalidstateerror") ||
    lower->String.includes("indexeddb is not defined") ||
    lower->String.includes("indexeddb is null") ||
    lower->String.includes("access to storage")
  ) {
    StorageUnavailable
  } else {
    UnknownFailure
  }
}

let currentHealth = ref({activity: #idle, ready: false, failure: None})
let healthListeners: array<unit => unit> = []

let getHealth = () => currentHealth.contents

let setHealth = (next: health) => {
  currentHealth := next
  healthListeners->Array.forEach(listener => listener())
}

// Returns an unsubscribe function, for React effect cleanup.
let subscribeHealth = (listener: unit => unit) => {
  healthListeners->Array.push(listener)
  () => {
    let index = healthListeners->Array.indexOf(listener)
    if index >= 0 {
      healthListeners->Array.splice(~start=index, ~remove=1, ~insert=[])
    }
  }
}

// Bumped on every reported failure. The status listener compares this across a
// save so a clean write can clear a stale error instead of latching it forever.
let errorCount = ref(0)
let errorCountAtSaveStart = ref(0)

let reportFailure = error => {
  let detail = describeError(error)
  Js.Console.error2("[EventManagerPersistence] storage failure:", error)
  errorCount := errorCount.contents + 1
  setHealth({...getHealth(), failure: Some((classifyError(detail), detail))})
}

let dbName = "pkuru-fairplay"

// Create IndexedDB persister for the event store. The 1.0 is TinyBase's own
// default autoLoad poll interval; the handler is what stops errors vanishing.
let eventPersister = TinyBase.createIndexedDbPersisterWithErrors(
  eventStore,
  dbName,
  1.0,
  reportFailure,
)

// Chrome's IndexedDB is LevelDB underneath: writes append and deletes append
// tombstones, so *removing* rows grows the file until a background compaction
// runs. Safari's is SQLite, where deleted rows leave free pages and the file
// does not shrink without a VACUUM. Either way, dropping the whole database is
// the only thing that reclaims space promptly — which matters because the
// caller is usually out of space already.
//
// Never rejects. Reports which path it took instead, because "blocked" is the
// difference between the reset freeing space and merely emptying the data, and
// that is exactly what someone staring at an unchanged usage figure needs to
// know. Blocking is common: any other tab on this origin polls the database
// once a second, and its open connection defers the delete.
type deleteOutcome = [#deleted | #blocked | #errored | #timedOut]

// onblocked is not a failure and must not end the wait: it fires when another
// connection is still open, and onsuccess follows as soon as that closes.
// Resolving early would let us reopen the database while the delete is still
// pending, so the delete would then destroy what we had just written. Only
// onsuccess/onerror settle this; onblocked just records why it is taking a
// while, and the timeout distinguishes "someone is holding it" from "no reply".
let deleteDatabase: string => promise<deleteOutcome> = %raw(`function(name) {
  return new Promise(function(resolve) {
    var settled = false
    var wasBlocked = false
    var done = function(outcome) {
      if (!settled) { settled = true; resolve(outcome) }
    }
    var request
    try { request = indexedDB.deleteDatabase(name) } catch (e) { return done("errored") }
    request.onsuccess = function() { done("deleted") }
    request.onerror = function() { done("errored") }
    request.onblocked = function() { wasBlocked = true }
    setTimeout(function() { done(wasBlocked ? "blocked" : "timedOut") }, 5000)
  })
}`)

let _ = eventPersister->TinyBase.addStatusListener((_, status) => {
  let previous = getHealth()
  switch status {
  | 1 => setHealth({...previous, activity: #loading})
  | 2 => {
      errorCountAtSaveStart := errorCount.contents
      setHealth({...previous, activity: #saving})
    }
  | _ =>
    // Back to idle. If the write that just finished reported no new errors, it
    // succeeded — that proves persistence works, so clear any stale failure and
    // mark ready, otherwise a page that failed at init would read "Connecting…"
    // forever after storage recovers.
    if previous.activity == #saving && errorCount.contents == errorCountAtSaveStart.contents {
      setHealth({activity: #idle, ready: true, failure: None})
    } else {
      setHealth({...previous, activity: #idle})
    }
  }
})

// Marks the attempt healthy only if nothing failed while it ran. TinyBase reports
// a blocked IndexedDB through onIgnoredError and still *resolves*, so an
// unconditional "ready: true" here would wipe the failure just recorded and
// report a healthy tool that is saving nothing.
let settleAttempt = (countAtStart: int) => {
  let current = getHealth()
  if errorCount.contents == countAtStart {
    setHealth({...current, ready: true, failure: None})
  } else {
    setHealth({...current, ready: false})
  }
}

// Initialize persistence on module load. Without the catch, a rejection here
// leaves autosave never started while every save* call still "succeeds".
let startPersistence = () => {
  let countAtStart = errorCount.contents
  eventPersister
  ->TinyBase.startAutoLoad(Js.Json.null)
  ->Promise.then(_ => {
    eventPersister->TinyBase.startAutoSave
  })
  ->Promise.thenResolve(_ => settleAttempt(countAtStart))
  ->Promise.catch(error => {
    setHealth({...getHealth(), ready: false})
    reportFailure(error)
    Promise.resolve()
  })
}

let _ = startPersistence()

// Retry from the error banner. If autosave never started, start it; otherwise
// force a save so we learn whether writes work again.
let retry = () =>
  if !(eventPersister->TinyBase.isAutoSaving) {
    startPersistence()
  } else {
    let countAtStart = errorCount.contents
    eventPersister
    ->TinyBase.save
    ->Promise.thenResolve(_ => settleAttempt(countAtStart))
    ->Promise.catch(error => {
      reportFailure(error)
      Promise.resolve()
    })
  }

module Health = {
  let use = () => {
    let (health, setLocalHealth) = React.useState(() => getHealth())

    React.useEffect0(() => {
      // The persister is a module-level singleton that starts loading at import
      // time, so it can fail before this component ever mounts. Catch up first.
      setLocalHealth(_ => getHealth())
      Some(subscribeHealth(() => setLocalHealth(_ => getHealth())))
    })

    health
  }
}

// Load the current round index for an event from TinyBase
let loadCurrentRound = (eventId: string): int => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("currentRound"))
  ->Option.flatMap(v => v->Js.Json.decodeNumber)
  ->Option.map(Float.toInt)
  ->Option.getOr(0)
}

// Save the current round index for an event to TinyBase
let saveCurrentRound = (eventId: string, currentRound: int) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("currentRound", currentRound->Int.toFloat->Js.Json.number)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// What a reset would destroy, so the confirmation can name real numbers instead
// of issuing a vague warning. The current event is counted separately from the
// rest: its unsynced scores can be pushed from the screen the organiser is
// already on, while the other events have to be opened one by one.
type storageSummary = {
  otherEventCount: int,
  currentUnsyncedMatchCount: int,
  otherUnsyncedMatchCount: int,
}

let decodeBool = (row: TinyBase.row, key: string) =>
  row->Js.Dict.get(key)->Option.flatMap(v => v->Js.Json.decodeBoolean)->Option.getOr(false)

let matchEventId = (row: TinyBase.row) =>
  row->Js.Dict.get("eventId")->Option.flatMap(v => v->Js.Json.decodeString)

// "Unsynced" here matches the header counter: only a match with a score has
// anything worth pushing to the server.
let isUnsyncedScore = (row: TinyBase.row) =>
  row->decodeBool("hasScore") && !(row->decodeBool("synced"))

let summarizeStoredData = (currentEventId: string): storageSummary => {
  let matchRows = eventStore->TinyBase.getTable("matches")->Js.Dict.values

  let countUnsynced = (belongsToCurrent: bool) =>
    matchRows
    ->Array.filter(row =>
      switch row->matchEventId {
      | Some(eventId) => (eventId == currentEventId) == belongsToCurrent && row->isUnsyncedScore
      | None => false
      }
    )
    ->Array.length

  // Every other event that has left a trace, whether in eventState or in matches.
  let otherEventIds = Set.make()
  eventStore
  ->TinyBase.getTable("eventState")
  ->Js.Dict.keys
  ->Array.forEach(eventId =>
    if eventId != currentEventId {
      otherEventIds->Set.add(eventId)
    }
  )
  matchRows->Array.forEach(row =>
    switch row->matchEventId {
    | Some(eventId) if eventId != currentEventId => otherEventIds->Set.add(eventId)
    | _ => ()
    }
  )

  {
    otherEventCount: otherEventIds->Set.size,
    currentUnsyncedMatchCount: countUnsynced(true),
    otherUnsyncedMatchCount: countUnsynced(false),
  }
}

let byteLength: string => int = %raw(`function(s) {
  try { return new TextEncoder().encode(s).length } catch (e) { return s.length }
}`)

// How much this module actually stores. navigator.storage.estimate() reports
// the whole origin — service worker caches, localStorage, every other database
// — so on a real install it is dominated by things a reset here cannot touch,
// and reads as though clearing did nothing. This is the figure a reset controls.
let storedBytes = (): int => {
  let content = [
    eventStore->TinyBase.getTable("eventState")->Obj.magic,
    eventStore->TinyBase.getTable("matches")->Obj.magic,
  ]
  switch content->Js.Json.stringifyAny {
  | Some(json) => byteLength(json)
  | None => 0
  }
}

// The only clear this tool offers. Scoping it to a single event was never the
// right behaviour: the IndexedDB quota is shared across every event on the
// device, so clearing one rarely frees enough to matter, and a "reset" that
// silently leaves other events behind misrepresents what it did.
//
// This drops the database rather than deleting rows, because deleting rows
// *raises* reported usage until compaction runs — the opposite of what someone
// out of space needs. See deleteDatabase above.
let emptyTables = () => {
  eventStore->TinyBase.delTable("eventState")
  eventStore->TinyBase.delTable("matches")
}

let tablesAreEmpty = () =>
  eventStore->TinyBase.getTable("eventState")->Js.Dict.keys->Array.length == 0 &&
    eventStore->TinyBase.getTable("matches")->Js.Dict.keys->Array.length == 0

let clearAllEventData = async () => {
  // Stop auto-save/auto-load and discard queued writes first. Emptying the
  // store while auto-save is live would race: the resulting write can be either
  // flushed or dropped by destroy, which decides whether the database still
  // holds the old rows a moment later.
  let _ = await eventPersister->TinyBase.destroy

  // Persistence is genuinely down between here and startPersistence, so say so.
  setHealth({...getHealth(), ready: false})

  emptyTables()

  let outcome = await deleteDatabase(dbName)
  if outcome != #deleted {
    // Worth surfacing: the data is still cleared below, but the space is not
    // reclaimed until whatever holds the database open lets go.
    Js.Console.warn2(
      "[EventManagerPersistence] could not drop the database, so storage space was not reclaimed. Close other tabs on this site and reset again. Outcome:",
      outcome,
    )
  }

  // destroy() drops *queued* work but cannot recall a load that is already
  // awaiting IndexedDB. That one still calls setContent when it resolves, which
  // lands about here and puts every row back. Clearing again after the delete —
  // by which point such a read has certainly returned — is what makes the reset
  // deterministic instead of a coin flip.
  emptyTables()

  // Guarantee the clear even when the drop was blocked: write the emptied store
  // back before startAutoLoad can read the old rows and put them straight back.
  let _ = await eventPersister->TinyBase.save

  // Rebuild against the (ideally fresh) database. This also re-tests
  // writability, so a quota failure clears itself once the space is free.
  let _ = await startPersistence()

  // Belt and braces: if anything did resurrect rows, take them out for good
  // rather than leaving the organiser with a reset that silently did nothing.
  if !tablesAreEmpty() {
    Js.Console.warn("[EventManagerPersistence] rows reappeared after the reset; clearing again.")
    emptyTables()
    let _ = await eventPersister->TinyBase.save
  }

  outcome
}

// Load the court count for an event from TinyBase
let loadCourtCount = (eventId: string): option<int> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("courtCount"))
  ->Option.flatMap(v => v->Js.Json.decodeNumber)
  ->Option.map(Float.toInt)
}

// Save the court count for an event to TinyBase
let saveCourtCount = (eventId: string, courtCount: int) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("courtCount", courtCount->Int.toFloat->Js.Json.number)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// The draw seed: every solver generation for this event derives its PRNG from
// this value plus the absolute round index, which is what makes "reset"
// canonical — the same seed, strategy and state reproduce the same round. The
// dice button in the generation controls mints a new one.
let loadDrawSeed = (eventId: string): int => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("drawSeed"))
  ->Option.flatMap(v => v->Js.Json.decodeNumber)
  ->Option.map(Float.toInt)
  ->Option.getOr(1)
}

let saveDrawSeed = (eventId: string, seed: int) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("drawSeed", seed->Int.toFloat->Js.Json.number)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Helper to serialize strategy to string
let strategyToString = (strategy: strategy): string => {
  switch strategy {
  | CompetitivePlus => "competitive-plus"
  | Competitive => "competitive"
  | Mixed => "mixed"
  | RoundRobin => "round-robin"
  | Random => "random"
  | DUPR => "dupr"
  | NoveltyRoundRobin => "novelty-round-robin"
  | SolverRoundRobin => "solver-round-robin"
  | SolverRandomBalanced => "solver-random-balanced"
  | SolverCompetitivePlusStatic => "solver-competitive-plus-static"
  | SolverCompetitivePlus => "solver-competitive-plus"
  }
}

// Helper to deserialize strategy from string
let stringToStrategy = (str: string): strategy => {
  switch str {
  | "competitive-plus" => CompetitivePlus
  | "competitive" => Competitive
  | "mixed" => Mixed
  | "round-robin" => RoundRobin
  | "random" => Random
  | "dupr" => DUPR
  | "novelty-round-robin" => NoveltyRoundRobin
  | "solver-round-robin" => SolverRoundRobin
  | "solver-random-balanced" => SolverRandomBalanced
  // The stored name now resolves to the adaptive profile, which is what
  // "Competitive+" means; the static one is no longer selectable.
  | "solver-competitive-plus" => SolverCompetitivePlus
  | "solver-competitive-plus-static" => SolverCompetitivePlusStatic
  | "solver-auto" => SolverCompetitivePlus
  // Pre-rename aliases: events stored while the presets were still named after
  // the qualityVsVariety axis. Read forever; written never — the next
  // `saveStrategy` rewrites the row with the current string.
  | "solver-variety" => SolverRoundRobin
  | "solver-balanced" => SolverRandomBalanced
  | "solver-competitive" => SolverCompetitivePlus
  | _ => CompetitivePlus // Default fallback
  }
}

// Load the match generation strategy for an event from TinyBase
let loadStrategy = (eventId: string): strategy => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("strategy"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.map(stringToStrategy)
  ->Option.getOr(CompetitivePlus) // Default to CompetitivePlus
}

// Which pool a player's *base* rating is read from. This is a source, not an
// adjustment: seeding from the club has to replace the rating players start the
// event on, otherwise every "rating change" shown during the event is really
// the gap between the club and global scales rather than anything that happened
// on court.
type seedSource = GlobalRatings | ClubRatings

let seedSourceToString = (source: seedSource): string =>
  switch source {
  | GlobalRatings => "global"
  | ClubRatings => "club"
  }

let stringToSeedSource = (str: string): seedSource =>
  switch str {
  | "club" => ClubRatings
  | _ => GlobalRatings
  }

let loadSeedSource = (eventId: string): seedSource => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("seedSource"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.map(stringToSeedSource)
  ->Option.getOr(GlobalRatings)
}

let saveSeedSource = (eventId: string, source: seedSource) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("seedSource", source->seedSourceToString->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Save the match generation strategy for an event to TinyBase
let saveStrategy = (eventId: string, strategy: strategy) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("strategy", strategy->strategyToString->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Solver weight configuration. Only the user's `uiWeightConfig` is stored —
// presets live in code, so retuning them later applies retroactively to anyone
// who has not customised.
let loadWeightConfig = (eventId: string): option<CostModel.uiWeightConfig> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("solverWeights"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(CostModel.configFromJsonString)
}

let saveWeightConfig = (eventId: string, config: CostModel.uiWeightConfig) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("solverWeights", config->CostModel.configToJsonString->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Absence of a stored config means "use the strategy's tuned preset profile",
// so deselecting a customisation is a delete, not a write.
let clearWeightConfig = (eventId: string) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  switch eventsTable->Js.Dict.get(eventId) {
  | None => ()
  | Some(row) =>
    let filtered =
      row->Js.Dict.entries->Array.filter(((key, _)) => key != "solverWeights")->Js.Dict.fromArray
    eventStore->TinyBase.setRow("eventState", eventId, filtered)
  }
}

// ---------------------------------------------------------------------------
// Solver violation reporting
// ---------------------------------------------------------------------------
// Fallback warnings describe the *stored* rounds, so they must survive a
// reload with them — a warning that vanishes on refresh is a silent violation.
// Match-level warnings are keyed by match entity id and round-level ones by
// round index, both of which are persisted alongside the rounds themselves.

let violationsDictToJsonString = (dict: Js.Dict.t<array<SolverTypes.violation>>): string =>
  dict
  ->Js.Dict.entries
  ->Array.map(((key, violations)) => (
    key,
    violations->Array.map(v => v->SolverTypes.toJson)->Js.Json.array,
  ))
  ->Js.Dict.fromArray
  ->Js.Json.object_
  ->Js.Json.stringify

let violationsDictFromJsonString = (str: string): Js.Dict.t<array<SolverTypes.violation>> =>
  try {
    str
    ->Js.Json.parseExn
    ->Js.Json.decodeObject
    ->Option.mapOr(Js.Dict.empty(), obj =>
      obj
      ->Js.Dict.entries
      ->Array.map(((key, json)) => (
        key,
        json
        ->Js.Json.decodeArray
        ->Option.mapOr([], arr => arr->Array.filterMap(v => v->SolverTypes.fromJson)),
      ))
      ->Array.filter(((_, violations)) => violations->Array.length > 0)
      ->Js.Dict.fromArray
    )
  } catch {
  | _ => Js.Dict.empty()
  }

let saveViolationsCell = (eventId: string, cell: string, dict) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set(cell, dict->violationsDictToJsonString->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

let loadViolationsCell = (eventId: string, cell: string): Js.Dict.t<
  array<SolverTypes.violation>,
> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get(cell))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.mapOr(Js.Dict.empty(), violationsDictFromJsonString)
}

let saveSolverMatchViolations = (eventId, dict) =>
  saveViolationsCell(eventId, "solverMatchViolations", dict)
let loadSolverMatchViolations = eventId => loadViolationsCell(eventId, "solverMatchViolations")
let saveSolverRoundViolations = (eventId, dict) =>
  saveViolationsCell(eventId, "solverRoundViolations", dict)
let loadSolverRoundViolations = eventId => loadViolationsCell(eventId, "solverRoundViolations")

// Load checked-in player IDs for an event from TinyBase
let loadCheckedInPlayerIds = (eventId: string): array<string> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("checkedInPlayerIds"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeArray
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse checkedInPlayerIds JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing checkedInPlayerIds JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.map(arr => arr->Array.filterMap(item => item->Js.Json.decodeString))
  ->Option.getOr([])
}

// Save checked-in player IDs for an event to TinyBase
let saveCheckedInPlayerIds = (eventId: string, playerIds: array<string>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  let playerIdsJson = playerIds->Js.Json.stringifyAny->Option.getOr("[]")
  existingRow->Js.Dict.set("checkedInPlayerIds", playerIdsJson->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Helper function to hydrate a player with GraphQL RSVP data
let hydratePlayerWithRsvpData = (
  player: Player.t<Js.Json.t>,
  rsvpMap: Js.Dict.t<'rsvpNode>,
): Player.t<'rsvpNode> => {
  switch rsvpMap->Js.Dict.get(player.id) {
  | Some(rsvp) => {...player, data: Some(rsvp)}
  | None => {...player, data: None} // Guest players or players without RSVP data
  }
}

// Load raw match data from TinyBase for a specific event
// Returns array of tuples: (matchId, team1Players, team2Players, roundIndex, score)
// Players are hydrated with RSVP data from the provided rsvpMap
let loadMatchesFromDb = (eventId: string, rsvpMap: Js.Dict.t<'rsvpNode>): array<(
  string,
  array<player<'rsvpNode>>,
  array<player<'rsvpNode>>,
  int,
  option<(float, float)>,
  Js.Date.t,
  bool,
)> => {
  let matchesTable = eventStore->TinyBase.getTable("matches")

  // Load all matches for this event
  let results =
    matchesTable
    ->Js.Dict.entries
    ->Array.filterMap(((matchId, matchRow)) => {
      // Check if this match belongs to the current event
      switch matchRow->Js.Dict.get("eventId")->Option.map(v => v->Obj.magic) {
      | Some(mEventId: string) if mEventId == eventId => {
          // Extract match data - players are stored as JSON array string
          let team1Players =
            matchRow
            ->Js.Dict.get("team1Players")
            ->Option.flatMap(v => v->Js.Json.decodeString)
            ->Option.flatMap(str =>
              try {
                str->Js.Json.parseExn->Js.Json.decodeArray
              } catch {
              | Js.Exn.Error(e) => {
                  Js.log3(
                    "[EventManagerPersistence] Failed to parse team1Players JSON for match:",
                    matchId,
                    e,
                  )
                  None
                }
              | _ => {
                  Js.log2(
                    "[EventManagerPersistence] Unknown error parsing team1Players JSON for match:",
                    matchId,
                  )
                  None
                }
              }
            )
            ->Option.map(arr =>
              arr->Array.filterMap(
                playerJson => {
                  switch playerJson->Json.Decode.decode(Player.decodePlayer()) {
                  | Ok(player) => Some(hydratePlayerWithRsvpData(player, rsvpMap))
                  | Error(msg) => {
                      Js.log3(
                        "[EventManagerPersistence] Failed to decode team1 player for match:",
                        matchId,
                        msg,
                      )
                      None
                    }
                  }
                },
              )
            )
            ->Option.getOr([])

          let team2Players =
            matchRow
            ->Js.Dict.get("team2Players")
            ->Option.flatMap(v => v->Js.Json.decodeString)
            ->Option.flatMap(str =>
              try {
                str->Js.Json.parseExn->Js.Json.decodeArray
              } catch {
              | Js.Exn.Error(e) => {
                  Js.log3(
                    "[EventManagerPersistence] Failed to parse team2Players JSON for match:",
                    matchId,
                    e,
                  )
                  None
                }
              | _ => {
                  Js.log2(
                    "[EventManagerPersistence] Unknown error parsing team2Players JSON for match:",
                    matchId,
                  )
                  None
                }
              }
            )
            ->Option.map(arr =>
              arr->Array.filterMap(
                playerJson => {
                  switch playerJson->Json.Decode.decode(Player.decodePlayer()) {
                  | Ok(player) => Some(hydratePlayerWithRsvpData(player, rsvpMap))
                  | Error(msg) => {
                      Js.log3(
                        "[EventManagerPersistence] Failed to decode team2 player for match:",
                        matchId,
                        msg,
                      )
                      None
                    }
                  }
                },
              )
            )
            ->Option.getOr([])

          let roundIndex =
            matchRow
            ->Js.Dict.get("roundIndex")
            ->Option.flatMap(v => v->Js.Json.decodeNumber)
            ->Option.map(Float.toInt)
            ->Option.getOr(0)

          // Extract score if present
          let score = switch matchRow
          ->Js.Dict.get("hasScore")
          ->Option.flatMap(v => v->Js.Json.decodeBoolean) {
          | Some(true) => {
              let team1Score =
                matchRow
                ->Js.Dict.get("team1Score")
                ->Option.flatMap(v => v->Js.Json.decodeNumber)
              let team2Score =
                matchRow
                ->Js.Dict.get("team2Score")
                ->Option.flatMap(v => v->Js.Json.decodeNumber)

              switch (team1Score, team2Score) {
              | (Some(s1), Some(s2)) => Some((s1, s2))
              | _ => None
              }
            }
          | _ => None
          }

          // Extract createdAt timestamp
          Js.log("CreatedAt raw value:")
          let createdAt =
            matchRow
            ->Js.Dict.get("createdAt")
            ->Option.flatMap(v => v->Js.Json.decodeNumber)
            ->Option.map(ts => Js.Date.fromFloat(ts))
            ->Option.getOr(Js.Date.make())
          Js.log(createdAt)

          // Extract synced status
          let synced =
            matchRow
            ->Js.Dict.get("synced")
            ->Option.flatMap(v => v->Js.Json.decodeBoolean)
            ->Option.getOr(false)

          Some((matchId, team1Players, team2Players, roundIndex, score, createdAt, synced))
        }
      | _ => None
      }
    })
  results
}

// Load player seed adjustments for an event from TinyBase
// Load rating adjustment history for an event
let loadRatingAdjustmentHistory = (eventId: string): array<RatingAdjustment.t> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("ratingAdjustmentHistory"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeArray
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse ratingAdjustmentHistory JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing ratingAdjustmentHistory JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.map(arr => arr->Array.filterMap(RatingAdjustment.fromJson))
  ->Option.getOr([])
}

// Legacy: Load old playerSeedAdjustments dict and convert to history format
let loadPlayerSeedAdjustments = (eventId: string): Js.Dict.t<float> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("playerSeedAdjustments"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeObject
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse playerSeedAdjustments JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing playerSeedAdjustments JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.map(dict => {
    // Convert JSON values to floats
    let result = Js.Dict.empty()
    dict
    ->Js.Dict.entries
    ->Array.forEach(((playerId, jsonValue)) => {
      switch jsonValue->Js.Json.decodeNumber {
      | Some(adjustment) => result->Js.Dict.set(playerId, adjustment)
      | None => ()
      }
    })
    result
  })
  ->Option.getOr(Js.Dict.empty())
}

// Save player seed adjustments for an event to TinyBase
// Takes a dictionary mapping player IDs to mu adjustments
let savePlayerSeedAdjustments = (eventId: string, adjustments: Js.Dict.t<float>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())

  // Convert float dict to JSON object
  let adjustmentsJson = Js.Dict.empty()
  adjustments
  ->Js.Dict.entries
  ->Array.forEach(((playerId, adjustment)) => {
    adjustmentsJson->Js.Dict.set(playerId, adjustment->Js.Json.number)
  })

  let adjustmentsStr = adjustmentsJson->Js.Json.object_->Js.Json.stringifyAny->Option.getOr("{}")
  existingRow->Js.Dict.set("playerSeedAdjustments", adjustmentsStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Save rating adjustment history for an event to TinyBase
let saveRatingAdjustmentHistory = (eventId: string, history: array<RatingAdjustment.t>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())

  let historyJson = history->Array.map(RatingAdjustment.toJson)->Js.Json.array
  let historyStr = historyJson->Js.Json.stringifyAny->Option.getOr("[]")
  existingRow->Js.Dict.set("ratingAdjustmentHistory", historyStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Load teams for an event from TinyBase
let loadTeams = (eventId: string): array<array<Player.t<'a>>> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("teams"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str
      ->Js.Json.parseExn
      ->Js.Json.decodeArray
      ->Option.map(teamsJson =>
        teamsJson->Array.filterMap(
          teamJson =>
            teamJson
            ->Js.Json.decodeArray
            ->Option.map(playerJsons => playerJsons->Array.filterMap(Player.fromJson)),
        )
      )
    } catch {
    | _ => None
    }
  )
  ->Option.getOr([])
}

// Save teams for an event to TinyBase
let saveTeams = (eventId: string, teams: array<array<Player.t<'a>>>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())

  let teamsJson = teams->Array.map(team => team->Array.map(Player.toJson)->Js.Json.array)
  let teamsStr = teamsJson->Js.Json.array->Js.Json.stringifyAny->Option.getOr("[]")
  existingRow->Js.Dict.set("teams", teamsStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Load anti-teams for an event from TinyBase
let loadAntiTeams = (eventId: string): array<array<Player.t<'a>>> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("antiTeams"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str
      ->Js.Json.parseExn
      ->Js.Json.decodeArray
      ->Option.map(teamsJson =>
        teamsJson->Array.filterMap(
          teamJson =>
            teamJson
            ->Js.Json.decodeArray
            ->Option.map(playerJsons => playerJsons->Array.filterMap(Player.fromJson)),
        )
      )
    } catch {
    | _ => None
    }
  )
  ->Option.getOr([])
}

// Save anti-teams for an event to TinyBase
let saveAntiTeams = (eventId: string, antiTeams: array<array<Player.t<'a>>>) => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())

  let antiTeamsJson = antiTeams->Array.map(team => team->Array.map(Player.toJson)->Js.Json.array)
  let antiTeamsStr = antiTeamsJson->Js.Json.array->Js.Json.stringifyAny->Option.getOr("[]")
  existingRow->Js.Dict.set("antiTeams", antiTeamsStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Type for player data overrides (subset of player data that can be edited)
type playerOverride = {
  playerId: string,
  name: option<string>,
  gender: option<Gender.t>,
  paid: option<bool>,
}

// Load player data overrides for an event from TinyBase
// Returns a dictionary mapping player IDs to their overrides
let loadPlayerOverrides = (eventId: string): Js.Dict.t<playerOverride> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("playerOverrides"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeObject
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse playerOverrides JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing playerOverrides JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.map(dict => {
    let result = Js.Dict.empty()
    dict
    ->Js.Dict.entries
    ->Array.forEach(((playerId, overrideJson)) => {
      switch overrideJson->Js.Json.decodeObject {
      | Some(overrideObj) => {
          let override: playerOverride = {
            playerId,
            name: overrideObj->Js.Dict.get("name")->Option.flatMap(v => v->Js.Json.decodeString),
            gender: overrideObj
            ->Js.Dict.get("gender")
            ->Option.flatMap(v => v->Js.Json.decodeNumber)
            ->Option.map(n => Gender.fromInt(n->Float.toInt)),
            paid: overrideObj->Js.Dict.get("paid")->Option.flatMap(v => v->Js.Json.decodeBoolean),
          }
          result->Js.Dict.set(playerId, override)
        }
      | None => ()
      }
    })
    result
  })
  ->Option.getOr(Js.Dict.empty())
}

// Save a single player override for an event to TinyBase
let savePlayerOverride = (
  eventId: string,
  playerId: string,
  name: string,
  gender: Gender.t,
  paid: bool,
) => {
  // Load existing overrides
  let existingOverrides = loadPlayerOverrides(eventId)

  // Create new override
  let newOverride: playerOverride = {
    playerId,
    name: Some(name),
    gender: Some(gender),
    paid: Some(paid),
  }

  // Update overrides dict
  let overrideObj = Js.Dict.empty()
  newOverride.name->Option.forEach(n => overrideObj->Js.Dict.set("name", n->Js.Json.string))
  newOverride.gender->Option.forEach(g =>
    overrideObj->Js.Dict.set("gender", g->Gender.toInt->Int.toFloat->Js.Json.number)
  )
  newOverride.paid->Option.forEach(p => overrideObj->Js.Dict.set("paid", p->Js.Json.boolean))

  existingOverrides->Js.Dict.set(playerId, newOverride)

  // Convert to JSON and save
  let overridesJson = Js.Dict.empty()
  existingOverrides
  ->Js.Dict.entries
  ->Array.forEach(((pId, override)) => {
    let obj = Js.Dict.empty()
    override.name->Option.forEach(n => obj->Js.Dict.set("name", n->Js.Json.string))
    override.gender->Option.forEach(g =>
      obj->Js.Dict.set("gender", g->Gender.toInt->Int.toFloat->Js.Json.number)
    )
    override.paid->Option.forEach(p => obj->Js.Dict.set("paid", p->Js.Json.boolean))
    overridesJson->Js.Dict.set(pId, obj->Js.Json.object_)
  })

  let overridesStr = overridesJson->Js.Json.object_->Js.Json.stringifyAny->Option.getOr("{}")

  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("playerOverrides", overridesStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Load guest players for an event from TinyBase
let loadGuestPlayers = (eventId: string): array<Player.t<'a>> => {
  let eventsTable = eventStore->TinyBase.getTable("eventState")
  eventsTable
  ->Js.Dict.get(eventId)
  ->Option.flatMap(row => row->Js.Dict.get("guestPlayers"))
  ->Option.flatMap(v => v->Js.Json.decodeString)
  ->Option.flatMap(str =>
    try {
      str->Js.Json.parseExn->Js.Json.decodeArray
    } catch {
    | Js.Exn.Error(e) => {
        Js.log3(
          "[EventManagerPersistence] Failed to parse guestPlayers JSON for event:",
          eventId,
          e,
        )
        None
      }
    | _ => {
        Js.log2(
          "[EventManagerPersistence] Unknown error parsing guestPlayers JSON for event:",
          eventId,
        )
        None
      }
    }
  )
  ->Option.flatMap(arr =>
    arr->Array.map(Player.fromJson)->Array.every(Option.isSome)
      ? Some(arr->Array.filterMap(Player.fromJson))
      : None
  )
  ->Option.getOr([])
}

// Save guest players for an event to TinyBase
let saveGuestPlayers = (eventId: string, guestPlayers: array<Player.t<'a>>) => {
  let guestPlayersJson = guestPlayers->Array.map(Player.toJson)
  let guestPlayersStr = guestPlayersJson->Js.Json.stringifyAny->Option.getOr("[]")

  let eventsTable = eventStore->TinyBase.getTable("eventState")
  let existingRow = eventsTable->Js.Dict.get(eventId)->Option.getOr(Js.Dict.empty())
  existingRow->Js.Dict.set("guestPlayers", guestPlayersStr->Js.Json.string)
  eventStore->TinyBase.setRow("eventState", eventId, existingRow)
}

// Sync rounds to TinyBase - saves all match data with player IDs and scores
let syncRoundsToDb = (eventId: string, rounds: array<array<completedMatchEntity<'a>>>) => {
  // First, delete all existing matches for this event
  let matchesTable = eventStore->TinyBase.getTable("matches")
  let matchIdsToDelete =
    matchesTable
    ->Js.Dict.entries
    ->Array.filterMap(((matchId, matchRow)) => {
      switch matchRow->Js.Dict.get("eventId")->Option.map(v => v->Obj.magic) {
      | Some(mEventId: string) if mEventId == eventId => Some(matchId)
      | _ => None
      }
    })

  matchIdsToDelete->Array.forEach(matchId => {
    eventStore->TinyBase.delRow("matches", matchId)
  })

  // Add all matches from all rounds
  rounds->Array.forEachWithIndex((roundMatches, roundIndex) => {
    roundMatches->Array.forEach(matchEntity => {
      let matchId = matchEntity.id
      let (team1, team2) = matchEntity.match

      // Create match row
      let matchRowData = Js.Dict.empty()
      matchRowData->Js.Dict.set("eventId", eventId->Js.Json.string)
      matchRowData->Js.Dict.set("roundIndex", roundIndex->Int.toFloat->Js.Json.number)
      matchRowData->Js.Dict.set("createdAt", matchEntity.createdAt->Js.Date.getTime->Js.Json.number)

      // Store full player objects as JSON strings (TinyBase only supports primitives)
      let team1Json = team1->Array.map(Player.toJson)
      let team2Json = team2->Array.map(Player.toJson)

      let team1PlayersJson = team1Json->Js.Json.stringifyAny->Option.getOr("[]")
      let team2PlayersJson = team2Json->Js.Json.stringifyAny->Option.getOr("[]")

      matchRowData->Js.Dict.set("team1Players", team1PlayersJson->Js.Json.string)
      matchRowData->Js.Dict.set("team2Players", team2PlayersJson->Js.Json.string)

      // Store score if present
      switch matchEntity.score {
      | Some((team1Score, team2Score)) => {
          matchRowData->Js.Dict.set("hasScore", true->Js.Json.boolean)
          matchRowData->Js.Dict.set("team1Score", team1Score->Js.Json.number)
          matchRowData->Js.Dict.set("team2Score", team2Score->Js.Json.number)
        }
      | None => matchRowData->Js.Dict.set("hasScore", false->Js.Json.boolean)
      }

      // Store synced status
      matchRowData->Js.Dict.set("synced", matchEntity.synced->Js.Json.boolean)

      eventStore->TinyBase.setRow("matches", matchId, matchRowData)
    })
  })
}

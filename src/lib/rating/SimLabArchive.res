// A lab run, precomputed and saved to disk.
//
// The configurations worth drawing conclusions from are the ones nobody wants
// to sit through: the reference run is 100 rounds x 9 strategies x 3 fields x
// 7 seeds = 18,900 solver calls, about 108 minutes of a browser tab pinned at
// 100%. So it is computed once by `scripts/precompute-lab-run.ts` and served
// as a static asset the lab loads in a second.
//
// FORMAT. A saved run is JSON whose shape IS the runtime shape of what
// `MatchmakingLab` holds in state — `array<array<labResult>>`, indexed
// [field][seed]. That is deliberate: ReScript records compile to plain
// objects, payload-free variants to their own names as strings, and `None` to
// a missing key, so the whole graph round-trips through `JSON.stringify`
// without a field-by-field codec that would rot every time `SimLab.frame`
// gains a member. What that buys in brevity it owes in discipline:
//
//   - `version` is checked on load and a mismatch is refused outright. Bump it
//     whenever a type in `SimLab` changes shape. There is no migration path
//     and there should not be one — regenerate the file instead.
//   - `entry` is written as its id alone and rehydrated from the live
//     `SimLab.strategies` on load, so a saved run cannot resurrect a stale
//     copy of a strategy's weights. An unknown id fails the load.
//
// TRIMMING. Only seed 0 of each field keeps its per-round detail (`mu`,
// `sigma`, `games`, `byes`). That is the seed the lab's ladder and round views
// read — see `primary` in `MatchmakingLab` — and it is most of the bulk.
// Later seeds keep metrics only and carry empty detail arrays; they feed the
// charts and the summary's error bars, which aggregate across seeds and never
// look at a game. Anything that starts reading detail off a non-primary seed
// will silently see nothing, so `detailSeeds` records how many kept theirs.
open SimLab

// Bump on any shape change to `SimLab.labResult`, then regenerate the assets.
// v2: `frame.medianDrawProb`.
let version = 2

// ---------------------------------------------------------------------------
// Wire types
//
// The file format, written down. These mirror `SimLab`'s types except that a
// run carries its strategy's id in place of the whole `labStrategy` — that
// record is code (weights, colours, engine), not data, and a file holding its
// own copy would keep replaying a strategy's retired weights long after they
// changed.
// ---------------------------------------------------------------------------

// A frame on the wire. Identical to `SimLab.frame` but for `qualityByBand`.
//
// `None` compiles to `undefined`, and a record field holding it is simply
// dropped by `JSON.stringify` and reads back as `undefined` — so options
// survive at the top level for free. Inside an ARRAY they do not:
// `JSON.stringify([undefined])` is `[null]`, and `null` is not `undefined`, so
// a decoded `None` would come back as `Some(null)`. That matters most exactly
// where it happens: a band with no games would read as quality 0 — a round of
// perfect blowouts — instead of no data. Any future option-in-an-array needs
// the same treatment.
type wireFrame = {
  round: int,
  mu: array<float>,
  sigma: array<float>,
  spearman: float,
  rankError: float,
  muError: float,
  blowoutRate: option<float>,
  trueQuality: option<float>,
  predQuality: option<float>,
  trueDrawProb: option<float>,
  medianDrawProb: option<float>,
  qualityByBand: array<Js.Nullable.t<float>>,
  forecastError: option<float>,
  games: array<gameRecord>,
  byes: array<string>,
}

type wireRun = {
  entryId: string,
  frames: array<wireFrame>,
  fellBackToGreedy: bool,
}

type wireResult = {
  scenario: scenario,
  seed: int,
  numPlayers: int,
  courts: int,
  numRounds: int,
  truth: array<float>,
  driftRoles: array<drift>,
  names: array<string>,
  flagged: array<bool>,
  runs: array<wireRun>,
}

type savedRun = {
  version: int,
  // Human label for the picker, e.g. "Cold start · 24 players · 100 rounds".
  label: string,
  generatedAt: string,
  scenario: scenario,
  numPlayers: int,
  courts: int,
  numRounds: int,
  // First seed; the run used `seed` through `seed + seedCount - 1`.
  seed: int,
  seedCount: int,
  tournament: bool,
  // How many seeds per field kept per-round detail. Always 1 today.
  detailSeeds: int,
  // [field][seed], mirroring the lab's own state.
  byField: array<array<wireResult>>,
}

// One entry per file in the manifest, so the picker can be built without
// downloading every run.
type manifestEntry = {
  file: string,
  label: string,
  scenario: scenario,
  numPlayers: int,
  courts: int,
  numRounds: int,
  seedCount: int,
  tournament: bool,
  // Compressed size, so the picker can say what a click will cost.
  bytes: int,
}

type manifest = {version: int, runs: array<manifestEntry>}

// Where the generator writes and the app reads.
let assetDir = "matchmaking-lab"
let manifestFile = "runs.json"

// ---------------------------------------------------------------------------
// Encode
// ---------------------------------------------------------------------------

// Four decimals. Every number here is a rating, a probability or a score, and
// nothing downstream reads one to better than three figures — but full float64
// text is ~18 characters, and at ~19,000 frames that rounding is most of the
// file. It happens once, on write; a loaded run is never re-simulated, so no
// result depends on the digits thrown away.
let r4 = (v: float) => Js.Math.round(v *. 10000.) /. 10000.
let r4o = (v: option<float>) => v->Option.map(r4)

let trimFrame = (f: frame, ~detail: bool): wireFrame => {
  round: f.round,
  mu: detail ? f.mu->Array.map(r4) : [],
  sigma: detail ? f.sigma->Array.map(r4) : [],
  spearman: r4(f.spearman),
  rankError: r4(f.rankError),
  muError: r4(f.muError),
  blowoutRate: r4o(f.blowoutRate),
  trueQuality: r4o(f.trueQuality),
  predQuality: r4o(f.predQuality),
  trueDrawProb: r4o(f.trueDrawProb),
  medianDrawProb: r4o(f.medianDrawProb),
  qualityByBand: f.qualityByBand->Array.map(v => r4o(v)->Js.Nullable.fromOption),
  forecastError: r4o(f.forecastError),
  games: detail
    ? f.games->Array.map(g => {
        ...g,
        team1Score: r4(g.team1Score),
        team2Score: r4(g.team2Score),
        predictedWinProb: r4(g.predictedWinProb),
        trueWinProb: r4(g.trueWinProb),
        predictedDraw: r4(g.predictedDraw),
        trueDraw: r4(g.trueDraw),
      })
    : [],
  byes: detail ? f.byes : [],
}

let toWire = (r: labResult, ~detail: bool): wireResult => {
  scenario: r.scenario,
  seed: r.seed,
  numPlayers: r.numPlayers,
  courts: r.courts,
  numRounds: r.numRounds,
  truth: r.truth->Array.map(r4),
  driftRoles: r.driftRoles,
  names: r.names,
  flagged: r.flagged,
  runs: r.runs->Array.map(run => {
    entryId: run.entry.id,
    fellBackToGreedy: run.fellBackToGreedy,
    frames: run.frames->Array.map(f => trimFrame(f, ~detail)),
  }),
}

let encode = (
  byField: array<array<labResult>>,
  ~label: string,
  ~scenario: scenario,
  ~numPlayers: int,
  ~courts: int,
  ~numRounds: int,
  ~seed: int,
  ~seedCount: int,
  ~tournament: bool,
  ~generatedAt: string,
): string => {
  let saved: savedRun = {
    version,
    label,
    generatedAt,
    scenario,
    numPlayers,
    courts,
    numRounds,
    seed,
    seedCount,
    tournament,
    detailSeeds: 1,
    byField: byField->Array.map(bySeed =>
      // Seed 0 of each field is the session the ladder and round views show.
      bySeed->Array.mapWithIndex((r, seedIndex) => toWire(r, ~detail=seedIndex == 0))
    ),
  }
  Js.Json.stringifyAny(saved)->Option.getOr("")
}

// ---------------------------------------------------------------------------
// Decode
// ---------------------------------------------------------------------------

let strategyById = (id: string) => strategies->Array.find(s => s.id == id)

// The loaded run, in the shape the lab holds in state.
type loaded = {
  info: savedRun,
  byField: array<array<labResult>>,
}

let fromWireFrame = (f: wireFrame): frame => {
  round: f.round,
  mu: f.mu,
  sigma: f.sigma,
  spearman: f.spearman,
  rankError: f.rankError,
  muError: f.muError,
  blowoutRate: f.blowoutRate,
  trueQuality: f.trueQuality,
  predQuality: f.predQuality,
  trueDrawProb: f.trueDrawProb,
  medianDrawProb: f.medianDrawProb,
  // The one field JSON cannot carry as an option. See `wireFrame`.
  qualityByBand: f.qualityByBand->Array.map(v => v->Js.Nullable.toOption),
  forecastError: f.forecastError,
  games: f.games,
  byes: f.byes,
}

let fromWire = (w: wireResult): result<labResult, string> => {
  let missing = ref(None)
  let runs = w.runs->Array.filterMap(run =>
    switch strategyById(run.entryId) {
    | Some(entry) =>
      Some({
        entry,
        frames: run.frames->Array.map(fromWireFrame),
        fellBackToGreedy: run.fellBackToGreedy,
      })
    | None =>
      missing := Some(run.entryId)
      None
    }
  )
  switch missing.contents {
  | Some(id) => Error(`Saved run references strategy "${id}", which no longer exists.`)
  | None =>
    Ok({
      scenario: w.scenario,
      seed: w.seed,
      numPlayers: w.numPlayers,
      courts: w.courts,
      numRounds: w.numRounds,
      truth: w.truth,
      driftRoles: w.driftRoles,
      names: w.names,
      flagged: w.flagged,
      runs,
    })
  }
}

// The format is `Obj.magic`, so nothing about a parsed file is guaranteed
// until it has been looked at. A truncated download, or a URL that resolved to
// the app's own index.html, is JSON-shaped garbage that would otherwise crash
// mid-render instead of reaching the load error the UI already has a place
// for. These check the spine, not every field — `decode`'s try/catch is the
// backstop for everything else.
@val external isArray: 'a => bool = "Array.isArray"

let hasVersion = (saved: savedRun) => Js.typeof(Obj.magic(saved.version)) == "number"

let hasSpine = (saved: savedRun) =>
  isArray(saved.byField) &&
  saved.byField->Array.every(bySeed =>
    isArray(bySeed) &&
      bySeed->Array.every(r => isArray(r.runs) && r.runs->Array.every(run => isArray(run.frames)))
  )

let decode = (text: string): result<loaded, string> =>
  switch Js.Json.parseExn(text) {
  | exception _ => Error("Not valid JSON.")
  | json =>
    let saved: savedRun = Obj.magic(json)
    try {
      if !hasVersion(saved) {
        Error("Not a saved lab run.")
      } else if saved.version != version {
        // Checked before the spine, so a file from a build whose shape has
        // moved on gets the actionable message rather than "not a saved run".
        Error(
          `Saved run is format v${Int.toString(saved.version)}; this build reads v${Int.toString(
              version,
            )}. Regenerate it with \`yarn lab:precompute\`.`,
        )
      } else if !hasSpine(saved) {
        Error("Saved run is incomplete or corrupt.")
      } else if saved.byField->Array.length != fields->Array.length {
        Error(
          `Saved run covers ${Int.toString(
              saved.byField->Array.length,
            )} fields; this build has ${Int.toString(fields->Array.length)}.`,
        )
      } else {
        let failure = ref(None)
        let byField = saved.byField->Array.map(bySeed =>
          bySeed->Array.filterMap(w =>
            switch fromWire(w) {
            | Ok(r) => Some(r)
            | Error(e) =>
              failure := Some(e)
              None
            }
          )
        )
        switch failure.contents {
        | Some(e) => Error(e)
        | None => Ok({info: saved, byField})
        }
      }
    } catch {
    | _ => Error("Saved run is incomplete or corrupt.")
    }
  }

let decodeManifest = (text: string): result<manifest, string> =>
  switch Js.Json.parseExn(text) {
  | exception _ => Error("Not valid JSON.")
  | json =>
    let m: manifest = Obj.magic(json)
    if Js.typeof(Obj.magic(m.version)) != "number" || !isArray(m.runs) {
      // A dev server that answers a missing asset with index.html gets here.
      Error("Not a saved-run manifest.")
    } else {
      m.version == version
        ? Ok(m)
        : Error(
            `Manifest is format v${Int.toString(m.version)}; this build reads v${Int.toString(
                version,
              )}.`,
          )
    }
  }

// ---------------------------------------------------------------------------
// Fetching
// ---------------------------------------------------------------------------

@module("./labArchiveFetch") external fetchText: string => promise<string> = "fetchText"
@module("./labArchiveFetch") external assetBase: unit => string = "assetBase"

let assetUrl = (file: string) => {
  let base = assetBase()
  (base->String.endsWith("/") ? base : base ++ "/") ++ assetDir ++ "/" ++ file
}

let describeError = (e: exn) =>
  switch e {
  | Js.Exn.Error(err) => Js.Exn.message(err)->Option.getOr("Request failed.")
  | _ => "Request failed."
  }

let loadManifest = async (): result<manifest, string> =>
  switch await fetchText(assetUrl(manifestFile)) {
  | text => decodeManifest(text)
  | exception e => Error(describeError(e))
  }

let loadRun = async (file: string): result<loaded, string> =>
  switch await fetchText(assetUrl(file)) {
  | text => decode(text)
  | exception e => Error(describeError(e))
  }

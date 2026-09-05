%%raw("import { t } from '@lingui/macro'")

// Matchmaking convergence lab.
//
// Runs the app's real solver presets against a hidden ground truth and shows
// what each one does to the ladder. The scenarios are the committed convergence
// test cases (see tests/solver/Convergence.test.ts and `SimLab`) — this is a
// viewer for the experiments, not a separate model of them. One divergence:
// the lab's world scores outcomes with the app's own openskill model, while
// the convergence harness keeps its original ad-hoc logistic — its numeric
// baselines are internal to it, so the two suites' absolute numbers are not
// directly comparable.

// ---------------------------------------------------------------------------
// Recharts bindings (local: the shapes here are lab-specific)
// ---------------------------------------------------------------------------

module ResponsiveContainer = {
  @module("recharts") @react.component
  external make: (~width: string=?, ~height: int=?, ~children: React.element) => React.element =
    "ResponsiveContainer"
}

module LineChart = {
  type margin = {top: int, right: int, left: int, bottom: int}

  @module("recharts") @react.component
  external make: (
    ~data: array<Js.Json.t>,
    ~margin: margin=?,
    ~children: React.element,
  ) => React.element = "LineChart"
}

module Line = {
  @module("recharts") @react.component
  external make: (
    ~dataKey: string,
    // Human label for the tooltip; defaults to the dataKey.
    ~name: string=?,
    ~stroke: string=?,
    ~strokeWidth: float=?,
    ~strokeOpacity: float=?,
    ~strokeDasharray: string=?,
    ~dot: bool=?,
    ~isAnimationActive: bool=?,
    ~connectNulls: bool=?,
    ~\"type": string=?,
  ) => React.element = "Line"
}

module CartesianGrid = {
  @module("recharts") @react.component
  external make: (~stroke: string=?, ~vertical: bool=?) => React.element = "CartesianGrid"
}

module Tick = {
  type t = {fontSize: int, fill: string, fontFamily: string}
}

module XAxis = {
  @module("recharts") @react.component
  external make: (
    ~dataKey: string,
    ~stroke: string=?,
    ~tick: Tick.t=?,
    ~domain: array<float>=?,
    ~\"type": string=?,
    ~allowDecimals: bool=?,
  ) => React.element = "XAxis"
}

module YAxis = {
  @module("recharts") @react.component
  external make: (
    ~stroke: string=?,
    ~tick: Tick.t=?,
    ~domain: array<float>=?,
    ~width: int=?,
    ~allowDecimals: bool=?,
  ) => React.element = "YAxis"
}

module Tooltip = {
  type contentStyle = {
    background: string,
    border: string,
    borderRadius: int,
    fontSize: int,
    fontFamily: string,
  }

  @module("recharts") @react.component
  external make: (~contentStyle: contentStyle=?) => React.element = "Tooltip"
}

// ---------------------------------------------------------------------------
// Display copy
// ---------------------------------------------------------------------------
//
// The engine (`SimLab`) carries ids and behaviour; the words live here so they
// pass through the translation macros and so it stays importable by tests
// without i18n.

let ts = Lingui.UtilString.t

let scenarioLabel = (s: SimLab.scenario) =>
  switch s {
  | ColdStart => ts`Cold start`
  | AccuratePrior => ts`Accurate ladder`
  | Inverted => ts`Inverted ladder (complete)`
  | InvertedInserts => ts`Inverted inserts`
  | WithinBandInverted => ts`Within-band inversion`
  | NewcomerInjection => ts`Unrated newcomers`
  }

// Saved runs are described from the manifest's structured fields rather than
// its `label`, which the generator writes in English and cannot translate.
let savedRunLabel = (e: SimLabArchive.manifestEntry) => {
  let base =
    scenarioLabel(e.scenario) ++
    " · " ++
    ts`${Int.toString(e.numPlayers)}p · ${Int.toString(e.courts)} courts · ${Int.toString(
        e.numRounds,
      )} rounds · ${Int.toString(e.seedCount)} seeds`
  (e.tournament ? base ++ " · " ++ ts`tournament` : base) ++
    " · " ++
    ts`${Int.toString(e.bytes / 1024)} KB`
}

let scenarioBlurb = (s: SimLab.scenario) =>
  switch s {
  | ColdStart => ts`Everyone at the default rating. Nothing is known yet — the case every new event starts from.`
  | AccuratePrior => ts`Ratings already match the truth, held confidently. This is where match quality is the product.`
  | Inverted => ts`EVERY rating is the exact mirror of true skill, held confidently — the strongest player reads as the weakest. Balanced play is blind to this: matches look 50/50 under both truth and belief, so no evidence ever arrives. Only the variety modes escape it.`
  | InvertedInserts => ts`The same confident inversion, but applied to only a third of the pool — the rest are correctly rated anchors. The error is now visible against those anchors, so it should correct far faster than a complete inversion.`
  | WithinBandInverted => ts`Global order is right, but each band of four is internally reversed. Banded play CAN see this error, so Competitive+ self-corrects.`
  | NewcomerInjection => ts`A settled pool with unrated newcomers spread across the true ladder. Their ratings start mid-pool regardless of real skill.`
  }

let scenarioFlag = (s: SimLab.scenario) =>
  switch s {
  | NewcomerInjection => Some(ts`unrated newcomer`)
  | InvertedInserts => Some(ts`inverted insert`)
  | WithinBandInverted => Some(ts`band member`)
  | _ => None
  }

let strategyLabel = (entry: SimLab.labStrategy) =>
  switch entry.id {
  | "cpa" => ts`Competitive+ (adaptive)`
  | "rr" => ts`Round Robin`
  | "rb" => ts`Balanced Round Robin`
  | "cp" => ts`Competitive+ (static)`
  | "rnd" => ts`Random (baseline)`
  | "rndnov" => ts`Random, avoid repeats`
  | "oracle" => ts`Oracle (knows truth)`
  | "jp" => ts`Open play (JP style)`
  | "us" => ts`Open play (US style)`
  | "koc" => ts`King of the court`
  | other => other
  }

let strategyBlurb = (entry: SimLab.labStrategy) =>
  switch entry.id {
  | "cpa" => ts`What the app ships as Competitive+: calibrates with variety while the ratings are noise, then blends into banded play as they settle. Identical to the static profile once the ladder has any spread.`
  | "rr" => ts`Maximum rotation with light banding — novelty first, but still rating-aware, unlike the avoid-repeats baseline. Its unbalanced splits are what let it recover a broken ladder.`
  | "rb" => ts`Random composition, most even split available in every match.`
  | "cp" => ts`Banding from round one, with no calibration phase. Trusts whatever ratings it is given — which is why it opens badly from a cold start. Reference profile, not a mode players can pick.`
  | "rnd" => ts`No preferences at all: no balancing, no rotation, pure jitter. A synthetic floor — real clubs avoid repeats, so the realistic baseline is Random, avoid repeats.`
  | "rndnov" => ts`Random composition with partner and opponent rotation, but still no team balancing — what open play actually does, and the realistic rating-free baseline. Novelty buys variety and faster convergence, not match quality.`
  | "oracle" => ts`Matchmakes from hidden true skill instead of the ratings. Not a strategy anyone can run — it marks the best match quality this pool allows, so the distance from it is what imperfect ratings cost. Its ladder never improves: a game that is genuinely even is a coin flip, and coin flips teach nothing.`
  | "jp" => ts`Rotate through everyone, teams drawn as they come. Only when a foursome splits sharply into two strong and two weak does anyone even out the sides — and then which weak player goes with which strong is left to chance.`
  | "us" => ts`Players self-sort into a beginner group and an intermediate/advanced group and stay there, mixing only around the middle of the pool. Teams are drawn at random within a level and never evened out; about half of blowouts get run back — once — and a close game may keep the same four on court.`
  | "koc" => ts`Ranked courts: winners move up and split, losers slide down, and the bottom court's losers rotate out for whoever has sat longest. Every arriving pair is split across the net, so nobody keeps a winning partner. No ratings anywhere — the court ladder is the format's only memory.`
  | _ => ""
  }

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

let paper = "#E9EBE4"
let panel = "#F6F7F2"
let ink = "#161A17"
let mute = "#6E756B"
let rule = "#C7CCC0"
let ruleSoft = "#DDE1D6"
let ratingBlue = "#1F5FA8"
let truthRed = "#C4123F"
let warn = "#C98A05"
let monoFont = "ui-monospace, SFMono-Regular, Menlo, monospace"

// Bands run strongest (dark) to weakest (light) so the reading order matches
// the court order the app uses.
let bandColor = (~band: int, ~numBands: int) => {
  let t = numBands <= 1 ? 0.0 : Float.fromInt(band) /. Float.fromInt(numBands - 1)
  let channel = Js.Math.round(31.0 +. t *. 150.0)->Float.toInt
  let blue = Js.Math.round(168.0 -. t *. 40.0)->Float.toInt
  "rgb(" ++
  Int.toString(channel) ++
  "," ++
  Int.toString(Js.Math.round(95.0 +. t *. 90.0)->Float.toInt) ++
  "," ++
  Int.toString(blue) ++ ")"
}

let bandLabel = (~band: int, ~numBands: int) =>
  if numBands <= 1 {
    "all"
  } else if band == 0 {
    "top"
  } else if band == numBands - 1 {
    "bottom"
  } else {
    "mid " ++ Int.toString(band)
  }

let tickStyle: Tick.t = {fontSize: 9, fill: mute, fontFamily: monoFont}

let tooltipStyle: Tooltip.contentStyle = {
  background: "#fff",
  border: "1px solid " ++ rule,
  borderRadius: 0,
  fontSize: 11,
  fontFamily: monoFont,
}

let chartMargin: LineChart.margin = {top: 4, right: 8, left: -8, bottom: 0}

// `accentColor` / `borderLeft` overrides are not in ReactDOM.Style.make's
// typed record, so they go on afterwards.
let withProp = (style, key, value) => ReactDOM.Style.unsafeAddProp(style, key, value)

module Eyebrow = {
  @react.component
  let make = (~children: React.element, ~className: string="") =>
    <div
      className={"uppercase " ++ className}
      style={ReactDOM.Style.make(
        ~fontFamily=monoFont,
        ~fontSize="10px",
        ~letterSpacing="0.16em",
        ~color=mute,
        (),
      )}>
      children
    </div>
}

// ---------------------------------------------------------------------------
// Chart data
// ---------------------------------------------------------------------------

// The four plotted metrics, in one place so the chart, the leader badge and the
// summary table can never disagree about what a series means.
type metric =
  | LadderError
  | Quality
  | Blowouts
  | ForecastError
  // The typical game: median per-round draw probability. Immune to tail
  // drag, so the gap between it and Quality is how much the average is being
  // destroyed by the round's worst games.
  | QualityMedian
  // Match quality as experienced by one level band (0 = strongest).
  | QualityBand(int)

let metricKey = (m: metric) =>
  switch m {
  | LadderError => "e"
  | Quality => "q"
  | Blowouts => "b"
  | ForecastError => "fe"
  | QualityMedian => "qm"
  | QualityBand(band) => "qb" ++ Int.toString(band)
  }

// Whether a smaller number is the better one — the charts mix both directions,
// so nothing may assume it.
let lowerIsBetter = (m: metric) =>
  switch m {
  | LadderError | Blowouts | ForecastError => true
  | Quality | QualityMedian | QualityBand(_) => false
  }

// The value a series shows for one strategy at one round. Ladder error is a
// state, read directly; the rest are rates, averaged over a trailing window so
// a three-court round does not read as noise.
let seriesValue = (
  run: SimLab.strategyRun,
  ~metric: metric,
  ~round: int,
  ~window: int,
): option<float> =>
  switch metric {
  | LadderError => run.frames->Array.get(round)->Option.map(f => f.rankError)
  | _ =>
    let from = Js.Math.max_int(1, round - window + 1)
    let pick = (f: SimLab.frame) =>
      switch metric {
      | Quality => f.trueDrawProb
      | QualityMedian => f.medianDrawProb
      | Blowouts => f.blowoutRate
      | ForecastError => f.forecastError
      | QualityBand(band) => f.qualityByBand->Array.get(band)->Option.flatMap(v => v)
      | LadderError => None
      }
    let vals =
      Belt.Array.makeBy(round - from + 1, i => run.frames->Array.get(from + i))
      ->Array.filterMap(f =>
        switch f {
        | Some(frame) => pick(frame)
        | None => None
        }
      )
    vals->Array.length == 0
      ? None
      : Some(
          vals->Array.reduce(0., (a, b) => a +. b) /.
            Float.fromInt(vals->Array.length) *. 100.,
        )
  }

// Band series are added per run, since how many bands exist depends on the
// court count of that run.
let metricsFor = (~numBands: int) =>
  Array.concat(
    [LadderError, Quality, QualityMedian, Blowouts, ForecastError],
    Belt.Array.makeBy(numBands, band => QualityBand(band)),
  )

// Which strategy is ahead on this metric right now.
// Rows that matchmake from hidden truth are bounds, not competitors: they win
// quality trivially by cheating, so they never take the leader badge or a
// column highlight. Everything else — the random controls, the open-play
// styles, the static profile — is something a club could really run, so it
// competes.
let competes = (run: SimLab.strategyRun) => !run.entry.usesTruth

// A strategy's runs across every seed, by position in the strategy list.
let runsFor = (results: array<SimLab.labResult>, ~idx: int) =>
  results->Array.filterMap(r => r.runs->Array.get(idx))

let meanOf = (xs: array<float>) =>
  xs->Array.length == 0
    ? None
    : Some(xs->Array.reduce(0., (a, b) => a +. b) /. Float.fromInt(xs->Array.length))

// Standard error of the mean across seeds. None below two seeds, where there
// is no spread to measure — the summary then reports a bare number and says
// so, rather than implying a precision it does not have.
let standardError = (xs: array<float>) => {
  let n = xs->Array.length
  if n < 2 {
    None
  } else {
    switch meanOf(xs) {
    | None => None
    | Some(m) =>
      let variance =
        xs->Array.reduce(0., (acc, v) => acc +. (v -. m) *. (v -. m)) /. Float.fromInt(n - 1)
    Some(Js.Math.sqrt(variance /. Float.fromInt(n)))
    }
  }
}

// One strategy's series value, averaged over seeds.
let seriesAcross = (
  results: array<SimLab.labResult>,
  ~idx: int,
  ~metric: metric,
  ~round: int,
  ~window: int,
) =>
  meanOf(
    runsFor(results, ~idx)->Array.filterMap(run => seriesValue(run, ~metric, ~round, ~window)),
  )

let leaderAt = (
  results: array<SimLab.labResult>,
  ~metric: metric,
  ~round: int,
  ~window: int,
): option<(SimLab.strategyRun, float)> =>
  switch results->Array.get(0) {
  | None => None
  | Some(first) =>
    first.runs
    ->Array.mapWithIndex((run, idx) => (run, idx))
    ->Array.filter(((run, _)) => competes(run))
    ->Array.filterMap(((run, idx)) =>
      seriesAcross(results, ~idx, ~metric, ~round, ~window)->Option.map(v => (run, v))
    )
    ->Array.reduce(None, (best, (run, v)) =>
      switch best {
      | None => Some((run, v))
      | Some((_, bv)) => (lowerIsBetter(metric) ? v < bv : v > bv) ? Some((run, v)) : best
      }
    )
  }

type ladderRow = {
  index: int,
  rank: int,
  name: string,
  // All three are 0..1 for the bar widths.
  truthNorm: float,
  ratingNorm: float,
  sigmaNorm: float,
  flagged: bool,
}

// One session's ladder at one round, strongest first: a correct system reads
// as a clean staircase.
//
// Truth is taken AT `round` rather than from `r.truth`. `r.truth` is only
// where the session STARTED, and drifting players have moved since — reading
// the starting values here is what once pinned their red bars in place and
// froze their rank while their ↑/↓ marks promised movement. Every metric in
// `SimLab` already reads truth this way.
//
// The bar SCALE, though, is fixed for the whole run. Drift is linear per
// player, so the session's extremes are at its two ends; recomputing the range
// each round would slide every steady player's bar around to make room for one
// improver, which is the opposite of what this view is for.
let ladderRows = (r: SimLab.labResult, ~frame: SimLab.frame, ~round: int): array<ladderRow> => {
  let truthNow = SimLab.truthAt(~base=r.truth, ~roles=r.driftRoles, ~round)
  let truthEnd = SimLab.truthAt(~base=r.truth, ~roles=r.driftRoles, ~round=r.numRounds)
  let extremes = Array.concat(r.truth, truthEnd)
  let truthMin = extremes->Array.reduce(infinity, (a, b) => Js.Math.min_float(a, b))
  let truthMax = extremes->Array.reduce(neg_infinity, (a, b) => Js.Math.max_float(a, b))
  let truthSpan = truthMax -. truthMin < 0.001 ? 1.0 : truthMax -. truthMin
  let muMin = frame.mu->Array.reduce(infinity, (a, b) => Js.Math.min_float(a, b))
  let muMax = frame.mu->Array.reduce(neg_infinity, (a, b) => Js.Math.max_float(a, b))
  // A cold start has every rating identical; centre the bars rather than
  // dividing by nothing.
  let flat = muMax -. muMin < 0.5
  let muSpan = flat ? 1.0 : muMax -. muMin

  Belt.Array.makeBy(r.numPlayers, i => i)
  ->Array.toSorted((a, b) => truthNow->Array.getUnsafe(b) -. truthNow->Array.getUnsafe(a))
  ->Array.mapWithIndex((i, k) => {
    let driftMark = switch r.driftRoles->Array.get(i) {
    | Some(Improving) => " ↑"
    | Some(ImprovingFast) => " ↑↑"
    | Some(Slipping) => " ↓"
    | _ => ""
    }
    {
      index: i,
      rank: k + 1,
      name: r.names->Array.getUnsafe(i) ++ driftMark,
      truthNorm: (truthNow->Array.getUnsafe(i) -. truthMin) /. truthSpan,
      ratingNorm: flat ? 0.5 : (frame.mu->Array.getUnsafe(i) -. muMin) /. muSpan,
      sigmaNorm: Js.Math.min_float(0.5, frame.sigma->Array.getUnsafe(i) /. (flat ? 14.0 : muSpan)),
      flagged: r.flagged->Array.getUnsafe(i),
    }
  })
}

// How many rounds the standings look back over from the scrubbed round.
//
// A quarter of the session so far, never less than ten. All three summary
// columns use it, so the table answers one question — "how is this going
// NOW?" — rather than mixing a recent measure with a lifetime one, and
// scrubbing actually moves it.
//
// The length is a compromise, measured on the saved 100-round run (typical
// field, 7 seeds) as separation between best and worst strategy against the
// seed-to-seed error bar:
//
//                    places off      quality        blowouts
//                    spread  ratio   spread  ratio  spread  ratio
//   cumulative        1.46   11.0     0.21   22.7    0.27   18.7
//   second half       1.58   10.0     0.30   21.0    0.35   15.9
//   trailing 5        1.40    8.6     0.37   13.7    0.36    9.7
//   trailing 25       ~1.48   ~9.5    0.37  ~19.1    0.39  ~14.1   <- here
//
// A cumulative mean has the best ratio, but only because it is precise about
// a diluted quantity: it buries whatever a strategy does late under the whole
// history. A trailing window nearly doubles the absolute separation for about
// 20% of the signal-to-noise, and short windows give that back — trailing 5 is
// visibly noise at 100 rounds. Ten rounds is the floor because that is where a
// 30-round session still discriminates.
let summaryWindow = (~round: int) => Js.Math.max_int(10, round / 4)

// First frame of that window. Frame 0 is the pre-play state and never counts
// as a round, so the window can be shorter than `summaryWindow` early on.
let summaryFrom = (~round: int) => Js.Math.max_int(1, round - summaryWindow(~round) + 1)

// Standings for one band: every competing strategy's average quality for that
// level, best first. Over the same trailing window as the summary table, so
// the two agree — a page showing "last 25 rounds" in one panel and "all 100"
// in the next invites reading one as the other. The chart's leader badge
// answers "who is ahead at this exact round"; this smooths that.
let bandStandings = (
  results: array<SimLab.labResult>,
  ~band: int,
  ~round: int,
): array<(SimLab.strategyRun, float)> =>
  switch results->Array.get(0) {
  | None => []
  | Some(first) =>
    first.runs
    ->Array.mapWithIndex((run, idx) => (run, idx))
    ->Array.filter(((run, _)) => competes(run))
    ->Array.filterMap(((run, idx)) =>
      meanOf(
        runsFor(results, ~idx)->Array.filterMap(r => {
          let played = r.frames->Array.slice(~start=summaryFrom(~round), ~end=round + 1)
          meanOf(
            played->Array.filterMap(f => f.qualityByBand->Array.get(band)->Option.flatMap(v => v)),
          )
        }),
      )->Option.map(v => (run, v *. 100.))
    )
    ->Array.toSorted(((_, a), (_, b)) => b -. a)
  }

// One row per round, carrying every strategy's series so the charts can overlay
// them. Keys are `<metric>_<short>`, e.g. "q_RB".
// Every plotted line is the mean over seeds, which is what removes the
// run-to-run jitter from the picture. The ladder and round views below still
// show a single concrete session, since an averaged draw is not a draw.
let buildChartData = (results: array<SimLab.labResult>, ~window: int): array<Js.Json.t> =>
  switch results->Array.get(0) {
  | None => []
  | Some(first) =>
    Belt.Array.makeBy(first.numRounds, r => {
      let round = r + 1
      let row = Js.Dict.empty()
      row->Js.Dict.set("round", round->Int.toFloat->Js.Json.number)
      let metrics = metricsFor(~numBands=first.courts)
      first.runs->Array.forEachWithIndex((run, idx) =>
        metrics->Array.forEach(m =>
          switch seriesAcross(results, ~idx, ~metric=m, ~round, ~window) {
          | Some(v) => row->Js.Dict.set(metricKey(m) ++ "_" ++ run.entry.short, v->Js.Json.number)
          | None => ()
          }
        )
      )
      row->Js.Json.object_
    })
  }

// ---------------------------------------------------------------------------
// Ladder row
// ---------------------------------------------------------------------------

module LadderRow = {
  @react.component
  let make = (
    ~rank: int,
    ~name: string,
    ~truthNorm: float,
    ~ratingNorm: float,
    ~sigmaNorm: float,
    ~flagged: bool,
  ) => {
    let drift = ratingNorm -. truthNorm
    let bad = Js.Math.abs_float(drift) > 0.22
    <div className="flex items-center gap-2" style={ReactDOM.Style.make(~height="22px", ())}>
      <div
        style={ReactDOM.Style.make(
          ~width="26px",
          ~fontFamily=monoFont,
          ~fontSize="10px",
          ~color=mute,
          ~textAlign="right",
          (),
        )}>
        {rank->Int.toString->React.string}
      </div>
      <div
        style={ReactDOM.Style.make(
          ~width="42px",
          ~fontFamily=monoFont,
          ~fontSize="12px",
          ~fontWeight="600",
          ~color=flagged ? warn : ink,
          (),
        )}>
        {name->React.string}
      </div>
      <div
        className="relative flex-1"
        style={ReactDOM.Style.make(
          ~height="14px",
          ~background="#DFE3D9",
          ~borderRadius="2px",
          ~overflow="hidden",
          (),
        )}>
        <div
          style={ReactDOM.Style.make(
            ~position="absolute",
            ~left=Js.Math.max_float(0., (ratingNorm -. sigmaNorm) *. 100.)->Float.toString ++ "%",
            ~width=Js.Math.min_float(100., sigmaNorm *. 200.)->Float.toString ++ "%",
            ~top="0",
            ~bottom="0",
            ~background="rgba(31,95,168,0.16)",
            (),
          )}
        />
        <div
          style={ReactDOM.Style.make(
            ~position="absolute",
            ~left="0",
            ~top="0",
            ~bottom="0",
            ~width=Js.Math.max_float(1.5, ratingNorm *. 100.)->Float.toString ++ "%",
            ~background=bad ? "#7E9AC0" : ratingBlue,
            ~transition="width 120ms linear, background 300ms linear",
            (),
          )}
        />
        <div
          style={ReactDOM.Style.make(
            ~position="absolute",
            ~left="calc(" ++ (truthNorm *. 100.)->Float.toString ++ "% - 1px)",
            ~top="-1px",
            ~bottom="-1px",
            ~width="2px",
            ~background=truthRed,
            (),
          )}
        />
      </div>
      <div
        style={ReactDOM.Style.make(
          ~width="38px",
          ~textAlign="right",
          ~fontFamily=monoFont,
          ~fontSize="10px",
          ~color=bad ? truthRed : mute,
          (),
        )}>
        {((drift >= 0. ? "+" : "-") ++
        Js.Math.abs_float(drift)->Js.Float.toFixedWithPrecision(~digits=2))->React.string}
      </div>
    </div>
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

@react.component
let make = () => {
  let (scenario, setScenario) = React.useState(() => SimLab.ColdStart)
  let (seed, setSeed) = React.useState(() => 1)
  let (numPlayers, setNumPlayers) = React.useState(() => 18)
  let (courts, setCourts) = React.useState(() => 3)
  let (numRounds, setNumRounds) = React.useState(() => 20)

  // Seeds per field. A single session is noisy enough that the leader of a
  // column can change from one seed to the next even over 100 rounds, so the
  // summary reports a mean and a standard error across seeds and refuses to
  // crown a winner whose lead is inside that error.
  let (seedCount, setSeedCount) = React.useState(() => 3)

  // Every simulation runs all three fields across every seed.
  let (result, setResult) = React.useState(() => None)
  let (fieldIndex, setFieldIndex) = React.useState(() => 1) // typical by default
  // Tournament mode: fixed squads, so each player has only three or four
  // possible partners all session.
  let (tournament, setTournament) = React.useState(() => false)
  let (isRunning, setIsRunning) = React.useState(() => false)
  let (progress, setProgress) = React.useState(() => 0)

  // Saved runs. The configurations actually worth reading — 100 rounds over
  // several seeds — are hours of solving, so they are precomputed by
  // `yarn lab:precompute` and shipped as static assets. The manifest is
  // fetched once; if there is none published, the picker simply does not
  // appear and the lab behaves as it always has.
  let (savedRuns, setSavedRuns) = React.useState(() => [])
  let (loadingFile, setLoadingFile) = React.useState(() => None)
  let (loadError, setLoadError) = React.useState(() => None)
  // The file and header of the saved run currently on screen, if any. It
  // describes the DATA, not the controls: the sliders above stay editable and
  // describe the next live run, so the banner spells out its own parameters
  // rather than trusting them to still agree.
  let (loadedInfo, setLoadedInfo) = React.useState(() => None)

  let (stratIndex, setStratIndex) = React.useState(() => 0)
  // Quality chart view: the mean is the session as experienced (disasters
  // count); the median is the typical game. Their gap is tail drag.
  let (qualityMedianView, setQualityMedianView) = React.useState(() => false)
  // None = every band for the selected strategy; Some(b) = band b compared
  // ACROSS strategies, which is the view that answers "who gives the top
  // players the best games".
  let (bandView, setBandView) = React.useState(() => None)
  let (round, setRound) = React.useState(() => 0)
  let (playing, setPlaying) = React.useState(() => false)
  let (speed, setSpeed) = React.useState(() => 6)

  // Two fields times however many seeds.
  // Every strategy, in every field, on every seed. This is an upper bound: a
  // round that cannot be generated ends that run early, so the counter can
  // finish below the total but must never pass it.
  let totalSolves =
    numRounds * SimLab.strategies->Array.length * SimLab.fields->Array.length * seedCount

  React.useEffect0(() => {
    let live = ref(true)
    let _ = (
      async () => {
        switch await SimLabArchive.loadManifest() {
        // No manifest is the normal state of a fresh checkout that has not run
        // the generator, so a failure here is silent — there is nothing to
        // offer and nothing has gone wrong.
        | Ok(m) => live.contents ? setSavedRuns(_ => m.runs) : ()
        | Error(_) => ()
        }
      }
    )()
    Some(() => live := false)
  })

  let loadSaved = (entry: SimLabArchive.manifestEntry) => {
    setLoadingFile(_ => Some(entry.file))
    setLoadError(_ => None)
    let _ = (
      async () => {
        switch await SimLabArchive.loadRun(entry.file) {
        | Ok(loaded) =>
          setResult(_ => Some(loaded.byField))
          // Move the controls to the saved run's configuration, so hitting Run
          // reproduces it rather than silently switching to whatever was set
          // before.
          setScenario(_ => loaded.info.scenario)
          setNumPlayers(_ => loaded.info.numPlayers)
          setCourts(_ => loaded.info.courts)
          setNumRounds(_ => loaded.info.numRounds)
          setSeed(_ => loaded.info.seed)
          setSeedCount(_ => loaded.info.seedCount)
          setTournament(_ => loaded.info.tournament)
          setRound(_ => 0)
          setPlaying(_ => false)
          setLoadedInfo(_ => Some((entry.file, loaded.info)))
          setLoadingFile(_ => None)
        | Error(e) =>
          setLoadError(_ => Some(e))
          setLoadingFile(_ => None)
        }
      }
    )()
  }

  let runSim = () => {
    setIsRunning(_ => true)
    setProgress(_ => 0)
    setPlaying(_ => false)
    setLoadedInfo(_ => None)
    setLoadError(_ => None)
    let _ = (
      async () => {
        // Let the button's pending state paint before the first solve blocks.
        await SolverRounds.afterPaint()
        // [field][seed]
        let byField = SimLab.fields->Array.map(_ => [])
        for i in 0 to seedCount - 1 {
          let seedForRun = seed + i
          for f in 0 to SimLab.fields->Array.length - 1 {
            let r = await SimLab.run(
              ~scenario,
              ~seed=seedForRun,
              ~numPlayers,
              ~courts,
              ~numRounds,
              ~dist=SimLab.fields->Array.getUnsafe(f),
              ~tournament,
              ~onRound=() => setProgress(p => p + 1),
            )
            switch byField->Array.get(f) {
            | Some(bucket) => bucket->Array.push(r)
            | None => ()
            }
          }
        }
        setResult(_ => Some(byField))
        setRound(_ => 0)
        setIsRunning(_ => false)
      }
    )()
  }

  // Playback
  React.useEffect2(() => {
    switch (playing, result) {
    | (true, Some(byField)) if byField->Array.length > 0 =>
      let r =
        byField
        ->Array.get(0)
        ->Option.flatMap(rs => rs->Array.get(0))
        ->Option.getOr(byField->Array.getUnsafe(0)->Array.getUnsafe(0))
      let id = setInterval(() => {
        setRound(prev => {
          if prev >= r.numRounds {
            setPlaying(_ => false)
            prev
          } else {
            prev + 1
          }
        })
      }, 1000 / speed)
      Some(() => clearInterval(id))
    | _ => None
    }
  }, (playing, speed))

  let btnStyle = (active: bool) =>
    ReactDOM.Style.make(
      ~padding="6px 10px",
      ~fontSize="11px",
      ~fontFamily=monoFont,
      ~letterSpacing="0.04em",
      ~border="1px solid " ++ (active ? ink : rule),
      ~background=active ? ink : "transparent",
      ~color=active ? paper : ink,
      ~cursor="pointer",
      (),
    )

  let panelStyle = ReactDOM.Style.make(
    ~background=panel,
    ~border="1px solid " ++ rule,
    ~padding="10px 12px",
    (),
  )

  let chartPanelStyle = ReactDOM.Style.make(
    ~background=panel,
    ~border="1px solid " ++ rule,
    ~padding="10px 8px 4px 0",
    (),
  )

  let selected = result->Option.flatMap(byField => byField->Array.get(fieldIndex))
  // One concrete session drives the ladder and the round detail — an averaged
  // draw is not a draw. Everything aggregate reads all the seeds.
  let primary = selected->Option.flatMap(rs => rs->Array.get(0))

  let content = switch (selected, primary) {
  | (Some(results), Some(r)) =>
    let run = r.runs->Array.get(stratIndex)->Option.getOr(r.runs->Array.getUnsafe(0))
    let frame = run.frames->Array.get(round)->Option.getOr(run.frames->Array.getUnsafe(0))
    let chartData = buildChartData(results, ~window=5)
    let visible = chartData->Array.slice(~start=0, ~end=Js.Math.max_int(1, round))

    let ladder = ladderRows(r, ~frame, ~round)

    let chartBox = (
      ~metric: metric,
      ~title: string,
      ~unit: string,
      ~domain: option<array<float>>,
      // Optional control rendered in the header beside the leader badge, for
      // charts that offer a view toggle.
      ~extra: React.element=React.null,
    ) => {
      let key = metricKey(metric)
      // Who is ahead on THIS chart at the round currently scrubbed to. Reading
      // it off six overlaid lines is exactly what a legend should spare you.
      let leader = leaderAt(results, ~metric, ~round, ~window=5)
      <div style={chartPanelStyle}>
        <div className="flex items-baseline gap-2 pr-2">
          <Eyebrow className="pl-3 mb-1">
            {React.string(title ++ " ")}
            <span style={ReactDOM.Style.make(~opacity="0.6", ())}> {unit->React.string} </span>
          </Eyebrow>
          {extra}
          {switch leader {
          | Some((run, value)) =>
            <span
              className="ml-auto flex items-center gap-1 shrink-0"
              style={ReactDOM.Style.make(~fontFamily=monoFont, ~fontSize="10px", ~color=mute, ())}>
              {ts`leading `->React.string}
              <span
                style={ReactDOM.Style.make(
                  ~width="7px",
                  ~height="7px",
                  ~background=run.entry.color,
                  ~display="inline-block",
                  (),
                )}
              />
              <span style={ReactDOM.Style.make(~color=ink, ~fontWeight="600", ())}>
                {(run.entry.short ++
                " " ++
                value->Js.Float.toFixedWithPrecision(~digits=metric == LadderError ? 2 : 0))
                  ->React.string}
              </span>
            </span>
          | None => React.null
          }}
        </div>
        <ResponsiveContainer width="100%" height=128>
          <LineChart data={visible} margin={chartMargin}>
            <CartesianGrid stroke={ruleSoft} vertical={false} />
            <XAxis
              dataKey="round"
              \"type"="number"
              domain=[1.0, r.numRounds->Int.toFloat]
              tick={tickStyle}
              stroke={rule}
              allowDecimals={false}
            />
            <YAxis ?domain tick={tickStyle} stroke={rule} width=34 />
            <Tooltip contentStyle={tooltipStyle} />
            {r.runs
            ->Array.mapWithIndex((other, idx) =>
              <Line
                key={other.entry.short}
                \"type"="monotone"
                dataKey={key ++ "_" ++ other.entry.short}
                stroke={other.entry.color}
                strokeWidth={idx == stratIndex ? 2.4 : 1.0}
                strokeOpacity={idx == stratIndex ? 1.0 : 0.45}
                strokeDasharray={other.entry.isBaseline ? "4 3" : ""}
                dot={false}
                isAnimationActive={false}
                connectNulls={true}
              />
            )
            ->React.array}
          </LineChart>
        </ResponsiveContainer>
      </div>
    }

    <div className="grid gap-4 grid-cols-1 lg:grid-cols-2">
      // Ladder + this round
      <div>
        <div className="flex items-baseline justify-between mb-2">
          <Eyebrow>
            {ts`Truth ladder — ${strategyLabel(run.entry)}`->React.string}
          </Eyebrow>
          <div style={ReactDOM.Style.make(~fontFamily=monoFont, ~fontSize="11px", ~color=mute, ())}>
            {ts`rho ${frame.spearman->Js.Float.toFixedWithPrecision(~digits=3)} · off by ${frame.rankError->Js.Float.toFixedWithPrecision(
              ~digits=2,
            )} places`->React.string}
          </div>
        </div>
        <div style={panelStyle}>
          {ladder
          ->Array.map(row =>
            <LadderRow
              key={Int.toString(row.index)}
              rank={row.rank}
              name={row.name}
              truthNorm={row.truthNorm}
              ratingNorm={row.ratingNorm}
              sigmaNorm={row.sigmaNorm}
              flagged={row.flagged}
            />
          )
          ->React.array}
          <div
            className="mt-2 pt-2"
            style={ReactDOM.Style.make(
              ~borderTop="1px solid " ++ ruleSoft,
              ~fontSize="10px",
              ~color=mute,
              ~fontFamily=monoFont,
              ~lineHeight="1.6",
              (),
            )}>
            <span style={ReactDOM.Style.make(~color=ratingBlue, ())}> {"|"->React.string} </span>
            {ts` rating · `->React.string}
            <span style={ReactDOM.Style.make(~color=truthRed, ())}> {"|"->React.string} </span>
            {ts` true skill`->React.string}
            {ts` · players marked ↑ ↑↑ ↓ are improving or slipping as the session runs`
            ->React.string}
            {switch scenarioFlag(r.scenario) {
            | Some(label) =>
              <>
                {" · "->React.string}
                <span style={ReactDOM.Style.make(~color=warn, ())}> {"A"->React.string} </span>
                {(" " ++ label)->React.string}
              </>
            | None => React.null
            }}
          </div>
        </div>
        <Eyebrow className="mt-3 mb-2">
          {ts`Round ${Int.toString(round)} · ${strategyLabel(run.entry)}`->React.string}
        </Eyebrow>
        <div
          style={ReactDOM.Style.make(
            ~background=panel,
            ~border="1px solid " ++ rule,
            ~padding="8px 12px",
            ~fontFamily=monoFont,
            ~fontSize="12px",
            (),
          )}>
          {frame.games->Array.length == 0
            ? <div style={ReactDOM.Style.make(~color=mute, ())}>
                {ts`No games yet — press play or step.`->React.string}
              </div>
            : React.null}
          {frame.games
          ->Array.map(g => {
            let t1 = g.team1->Array.join("")
            let t2 = g.team2->Array.join("")
            let winner = g.team1Score > g.team2Score ? t1 : t2
            let loser = g.team1Score > g.team2Score ? t2 : t1
            let hi = Js.Math.max_float(g.team1Score, g.team2Score)
            let lo = Js.Math.min_float(g.team1Score, g.team2Score)
            let confidence = Js.Math.max_float(g.predictedWinProb, 1. -. g.predictedWinProb)
            <div
              key={Int.toString(g.courtIndex)}
              className="flex items-center gap-2"
              style={ReactDOM.Style.make(~padding="3px 0", ())}>
              <span style={ReactDOM.Style.make(~color=mute, ~width="48px", ())}>
                {ts`court ${Int.toString(g.courtIndex + 1)}`->React.string}
              </span>
              <span style={ReactDOM.Style.make(~fontWeight="600", ())}> {winner->React.string} </span>
              <span style={ReactDOM.Style.make(~color=mute, ())}> {ts`def`->React.string} </span>
              <span> {loser->React.string} </span>
              <span
                className="ml-auto"
                style={ReactDOM.Style.make(~color=mute, ())}>
                {ts`pred ${(confidence *. 100.)->Js.Float.toFixedWithPrecision(~digits=0)}%`->React.string}
              </span>
              <span>
                {(hi->Js.Float.toFixedWithPrecision(~digits=0) ++
                "-" ++
                lo->Js.Float.toFixedWithPrecision(~digits=0))->React.string}
              </span>
              {g.isBlowout
                ? <span style={ReactDOM.Style.make(~color=warn, ~fontSize="10px", ())}>
                    {ts`BLOWOUT`->React.string}
                  </span>
                : React.null}
              {g.isUpset
                ? <span style={ReactDOM.Style.make(~color=truthRed, ~fontSize="10px", ())}>
                    {ts`UPSET`->React.string}
                  </span>
                : React.null}
            </div>
          })
          ->React.array}
          {frame.byes->Array.length == 0
            ? React.null
            : <div
                className="mt-1 pt-1"
                style={ReactDOM.Style.make(
                  ~borderTop="1px solid " ++ ruleSoft,
                  ~color=mute,
                  ~fontSize="11px",
                  (),
                )}>
                {ts`sitting out: ${frame.byes->Array.join(" ")}`->React.string}
              </div>}
        </div>
      </div>
      // Charts + standings
      <div className="flex flex-col gap-3">
        {chartBox(
          ~metric=LadderError,
          ~title=ts`Distance from truth`,
          ~unit=ts`· mean ladder places off · lower is better`,
          ~domain=None,
        )}
        {chartBox(
          ~metric=Blowouts,
          ~title=ts`Blowout rate`,
          ~unit=ts`· % of games decided by 9+ · rolling 5`,
          ~domain=Some([0.0, 100.0]),
        )}
        {chartBox(
          ~metric=qualityMedianView ? QualityMedian : Quality,
          ~title=qualityMedianView ? ts`Match quality · typical game` : ts`Match quality`,
          ~unit=qualityMedianView
            ? ts`· median game's % chance of ending level · immune to blowout drag`
            : ts`· % chance the game ends level, by true skill · higher is better`,
          ~domain=Some([0.0, 100.0]),
          ~extra={
            <span className="ml-auto flex items-center gap-1 shrink-0">
              {[(false, ts`mean`), (true, ts`median`)]
              ->Array.map(((median, label)) =>
                <button
                  key={label}
                  style={btnStyle(qualityMedianView == median)}
                  onClick={_ => setQualityMedianView(_ => median)}>
                  {label->React.string}
                </button>
              )
              ->React.array}
            </span>
          },
        )}
        {chartBox(
          ~metric=ForecastError,
          ~title=ts`Rating forecast error`,
          ~unit=ts`· mean gap between predicted and true win chance · 0 = called every game right`,
          ~domain=None,
        )}
        // Quality by level band. A single match-quality average hides the
        // thing operators actually get complained at about: a strategy can
        // post a fine overall number by serving the middle well while the top
        // and bottom of the room get nothing but blowouts. Two views, because
        // there are two questions — "is this strategy fair across levels?"
        // (one strategy, every band) and "who serves the top players best?"
        // (one band, every strategy).
        {
          let numBands = r.courts
          let bandToggle =
            <div
              className="ml-auto flex items-center gap-1 shrink-0 pr-1"
              style={ReactDOM.Style.make(~fontFamily=monoFont, ~fontSize="10px", ~color=mute, ())}>
              <button
                style={btnStyle(bandView == None)}
                onClick={_ => setBandView(_ => None)}>
                {ts`all bands`->React.string}
              </button>
              {Belt.Array.makeBy(numBands, band => band)
              ->Array.map(band =>
                <button
                  key={Int.toString(band)}
                  style={btnStyle(bandView == Some(band))}
                  onClick={_ => setBandView(_ => Some(band))}>
                  {bandLabel(~band, ~numBands)->React.string}
                </button>
              )
              ->React.array}
            </div>
          <div style={chartPanelStyle}>
            <div className="flex items-baseline gap-2 pr-2">
              <Eyebrow className="pl-3 mb-1">
                {React.string(ts`Match quality by band ` ++ " ")}
                <span style={ReactDOM.Style.make(~opacity="0.6", ())}>
                  {(switch bandView {
                  | None => ts`· ${strategyLabel(run.entry)} · every level, % chance of a level game`
                  | Some(band) =>
                    ts`· ${bandLabel(~band, ~numBands)} players · every strategy`
                  })->React.string}
                </span>
              </Eyebrow>
              bandToggle
            </div>
            <ResponsiveContainer width="100%" height=128>
              <LineChart data={visible} margin={chartMargin}>
                <CartesianGrid stroke={ruleSoft} vertical={false} />
                <XAxis
                  dataKey="round"
                  \"type"="number"
                  domain=[1.0, r.numRounds->Int.toFloat]
                  tick={tickStyle}
                  stroke={rule}
                  allowDecimals={false}
                />
                <YAxis domain=[0.0, 100.0] tick={tickStyle} stroke={rule} width=34 />
                <Tooltip contentStyle={tooltipStyle} />
                {switch bandView {
                // One strategy, coloured by band: strongest dark, weakest
                // light, so a fan that spreads out IS the unfairness.
                | None =>
                  Belt.Array.makeBy(numBands, band => band)
                  ->Array.map(band =>
                    <Line
                      key={Int.toString(band)}
                      \"type"="monotone"
                      dataKey={metricKey(QualityBand(band)) ++ "_" ++ run.entry.short}
                      stroke={bandColor(~band, ~numBands)}
                      strokeWidth=1.8
                      dot={false}
                      isAnimationActive={false}
                      connectNulls={true}
                    />
                  )
                  ->React.array
                // One band, coloured by strategy: the same comparison the
                // other charts make, restricted to one level of the room.
                | Some(band) =>
                  r.runs
                  ->Array.mapWithIndex((other, idx) =>
                    <Line
                      key={other.entry.short}
                      \"type"="monotone"
                      dataKey={metricKey(QualityBand(band)) ++ "_" ++ other.entry.short}
                      stroke={other.entry.color}
                      strokeWidth={idx == stratIndex ? 2.4 : 1.0}
                      strokeOpacity={idx == stratIndex ? 1.0 : 0.45}
                      strokeDasharray={other.entry.isBaseline ? "4 3" : ""}
                      dot={false}
                      isAnimationActive={false}
                      connectNulls={true}
                    />
                  )
                  ->React.array
                }}
              </LineChart>
            </ResponsiveContainer>
            // Session totals for the selected band. The chart says who is
            // ahead right now; this says who has served this level best over
            // everything played so far, which is the question that decides
            // anything.
            {switch bandView {
            | None => React.null
            | Some(band) =>
              <div
                className="flex flex-wrap gap-x-3 gap-y-1 px-3 pb-2"
                style={ReactDOM.Style.make(
                  ~fontFamily=monoFont,
                  ~fontSize="10px",
                  ~color=mute,
                  (),
                )}>
                {bandStandings(results, ~band, ~round)
                ->Array.mapWithIndex(((other, value), place) =>
                  <span key={other.entry.short} className="flex items-center gap-1">
                    <span
                      style={ReactDOM.Style.make(
                        ~width="7px",
                        ~height="7px",
                        ~background=other.entry.color,
                        ~display="inline-block",
                        (),
                      )}
                    />
                    <span
                      style={ReactDOM.Style.make(
                        ~color=place == 0 ? ink : mute,
                        ~fontWeight=place == 0 ? "600" : "400",
                        (),
                      )}>
                      {(other.entry.short ++
                      " " ++
                      value->Js.Float.toFixedWithPrecision(~digits=0))->React.string}
                    </span>
                  </span>
                )
                ->React.array}
              </div>
            }}
          </div>
        }
        <div style={panelStyle}>
          <Eyebrow className="mb-2">
            {(round == 0
              ? ts`Standings before play`
              : ts`Standings at round ${Int.toString(round)} · last ${Int.toString(
                  Js.Math.min_int(round, summaryWindow(~round)),
                )} rounds`)->React.string}
          </Eyebrow>
          // Three rolling totals with a standard error across seeds, plus an
          // overall placing. All three read the same trailing window, so the
          // table says how things are going NOW and scrubbing moves it — see
          // `summaryWindow` for the length and what it costs.
          //
          // Highlighting is deliberately conservative: a value is marked best
          // only if nothing else is within the two error bars. A single session
          // is noisy enough that the leader of a column changes between seeds
          // even over 100 rounds, so bolding the raw minimum would be reporting
          // noise as a result. When several are indistinguishable they are all
          // marked, and the reader is told the difference is inside the error.
          {
            let col = (~width: string) =>
              ReactDOM.Style.make(~width, ~textAlign="right", ~fontFamily=monoFont, ())
            // Per-seed samples for one strategy, so the spread is measurable.
            // Every column looks back over the same trailing window ending at
            // the scrubbed round — see `summaryWindow` for how long it is and
            // what the length costs.
            let from = summaryFrom(~round)
            let samplesFor = (idx: int, pick: SimLab.frame => option<float>) =>
              runsFor(results, ~idx)->Array.filterMap(run =>
                switch meanOf(
                  run.frames->Array.slice(~start=from, ~end=round + 1)->Array.filterMap(pick),
                ) {
                | Some(v) => Some(v)
                // Nothing played yet: the rates have no value at all, but the
                // ladder does — report the starting one rather than a blank.
                | None => run.frames->Array.get(round)->Option.flatMap(pick)
                }
              )
            let statFor = (idx: int, pick: SimLab.frame => option<float>) => {
              let xs = samplesFor(idx, pick)
              (meanOf(xs), standardError(xs))
            }
            let summarise = (other: SimLab.strategyRun, idx: int) => (
              idx,
              other,
              statFor(idx, f => Some(f.rankError)),
              statFor(idx, f => f.trueDrawProb),
              statFor(idx, f => f.blowoutRate),
            )
            let indexed =
              r.runs
              ->Array.mapWithIndex((other, idx) => (other, idx))
            let rows =
              indexed
              ->Array.filter(((other, _)) => competes(other))
              ->Array.map(((other, idx)) => summarise(other, idx))
            let bounds =
              indexed
              ->Array.filter(((other, _)) => !competes(other))
              ->Array.map(((other, idx)) => summarise(other, idx))

            let valuesOf = (col: array<(option<float>, option<float>)>) => col
            let rankOf = (
              value: (option<float>, option<float>),
              all: array<(option<float>, option<float>)>,
              ~lower: bool,
            ) =>
              switch value {
              | (None, _) => rows->Array.length
              | (Some(v), _) =>
                all->Array.reduce(0, (acc, other) =>
                  switch other {
                  | (Some(o), _) => (lower ? o < v : o > v) ? acc + 1 : acc
                  | _ => acc
                  }
                )
              }
            // Indistinguishable from the leader: the gap between the two means
            // is no bigger than their error bars combined.
            let isBest = (
              value: (option<float>, option<float>),
              all: array<(option<float>, option<float>)>,
              ~lower: bool,
            ) =>
              switch value {
              | (None, _) => false
              | (Some(v), se) =>
                let err = se->Option.getOr(0.)
                !(
                  all->Array.some(other =>
                    switch other {
                    | (Some(o), oe) =>
                      let combined = err +. oe->Option.getOr(0.)
                      lower ? o < v -. combined : o > v +. combined
                    | _ => false
                    }
                  )
                )
              }
            let places = rows->Array.map(((_, _, p, _, _)) => p)->valuesOf
            let qualities = rows->Array.map(((_, _, _, q, _)) => q)->valuesOf
            let blowouts = rows->Array.map(((_, _, _, _, b)) => b)->valuesOf
            let scored = rows->Array.map(((idx, other, p, q, b)) => {
              let overall =
                rankOf(p, places, ~lower=true) +
                rankOf(q, qualities, ~lower=false) +
                rankOf(b, blowouts, ~lower=true)
              (idx, other, p, q, b, overall)
            })
            // How many share the top spot once the error is respected.
            let coLeaders =
              scored->Array.reduce(0, (acc, (_, _, p, _, _, _)) =>
                isBest(p, places, ~lower=true) ? acc + 1 : acc
              )
            let fmt = (
              value: (option<float>, option<float>),
              ~digits: int,
              ~percent: bool,
            ) =>
              switch value {
              | (None, _) => "—"
              | (Some(v), se) =>
                let shown = percent ? v *. 100. : v
                let base = shown->Js.Float.toFixedWithPrecision(~digits) ++ (percent ? "%" : "")
                switch se {
                | Some(e) if e > 0. =>
                  base ++
                  "±" ++
                  (percent ? e *. 100. : e)->Js.Float.toFixedWithPrecision(~digits)
                | _ => base
                }
              }
            let cell = (~text: string, ~width: string, ~best: bool) =>
              <span
                style={col(~width)
                ->withProp("color", best ? ink : mute)
                ->withProp("fontWeight", best ? "700" : "400")}>
                {text->React.string}
              </span>
            <>
              <div
                className="flex items-center gap-2"
                style={ReactDOM.Style.make(
                  ~fontFamily=monoFont,
                  ~fontSize="10px",
                  ~color=mute,
                  ~paddingBottom="4px",
                  ~borderBottom="1px solid " ++ ruleSoft,
                  (),
                )}>
                <span style={ReactDOM.Style.make(~width="18px", ())} />
                <span className="flex-1" />
                <span style={col(~width="86px")}> {ts`places off`->React.string} </span>
                <span style={col(~width="76px")}> {ts`quality`->React.string} </span>
                <span style={col(~width="76px")}> {ts`blowouts`->React.string} </span>
              </div>
              {scored
              ->Array.toSorted(((_, _, pa, _, _, oa), (_, _, pb, _, _, ob)) =>
                oa == ob
                  ? switch (pa, pb) {
                    | ((Some(a), _), (Some(b), _)) => a -. b
                    | _ => 0.
                    }
                  : Float.fromInt(oa - ob)
              )
              ->Array.mapWithIndex(((idx, other, p, q, b, _), position) => {
                let leads = isBest(p, places, ~lower=true)
                <div
                  key={other.entry.short}
                  className="flex items-center gap-2"
                  style={ReactDOM.Style.make(
                    ~fontFamily=monoFont,
                    ~fontSize="11px",
                    ~padding="3px 0",
                    ~opacity=idx == stratIndex ? "1" : "0.75",
                    ~cursor="pointer",
                    (),
                  )}
                  onClick={_ => setStratIndex(_ => idx)}>
                  <span
                    style={ReactDOM.Style.make(
                      ~width="10px",
                      ~color=leads ? ink : mute,
                      ~fontWeight=leads ? "700" : "400",
                      (),
                    )}>
                    {(position + 1)->Int.toString->React.string}
                  </span>
                  <span
                    style={ReactDOM.Style.make(
                      ~width="8px",
                      ~height="8px",
                      ~background=other.entry.color,
                      ~display="inline-block",
                      (),
                    )}
                  />
                  <span
                    className="flex-1"
                    style={ReactDOM.Style.make(~fontWeight=leads ? "700" : "400", ())}>
                    {strategyLabel(other.entry)->React.string}
                  </span>
                  {cell(
                    ~text=fmt(p, ~digits=2, ~percent=false),
                    ~width="86px",
                    ~best=leads,
                  )}
                  {cell(
                    ~text=fmt(q, ~digits=0, ~percent=true),
                    ~width="76px",
                    ~best=isBest(q, qualities, ~lower=false),
                  )}
                  {cell(
                    ~text=fmt(b, ~digits=0, ~percent=true),
                    ~width="76px",
                    ~best=isBest(b, blowouts, ~lower=true),
                  )}
                </div>
              })
              ->React.array}
              {bounds->Array.length == 0
                ? React.null
                : <div
                    className="mt-1 pt-1"
                    style={ReactDOM.Style.make(~borderTop="1px dashed " ++ ruleSoft, ())}>
                    {bounds
                    ->Array.map(((idx, other, p, q, b)) =>
                      <div
                        key={other.entry.short}
                        className="flex items-center gap-2"
                        style={ReactDOM.Style.make(
                          ~fontFamily=monoFont,
                          ~fontSize="11px",
                          ~padding="3px 0",
                          ~opacity=idx == stratIndex ? "0.95" : "0.6",
                          ~cursor="pointer",
                          ~fontStyle="italic",
                          (),
                        )}
                        onClick={_ => setStratIndex(_ => idx)}>
                        <span style={ReactDOM.Style.make(~width="10px", ())} />
                        <span
                          style={ReactDOM.Style.make(
                            ~width="8px",
                            ~height="8px",
                            ~background=other.entry.color,
                            ~display="inline-block",
                            (),
                          )}
                        />
                        <span className="flex-1">
                          {ts`${strategyLabel(other.entry)} · not achievable`->React.string}
                        </span>
                        <span style={col(~width="86px")}>
                          {fmt(p, ~digits=2, ~percent=false)->React.string}
                        </span>
                        <span style={col(~width="76px")}>
                          {fmt(q, ~digits=0, ~percent=true)->React.string}
                        </span>
                        <span style={col(~width="76px")}>
                          {fmt(b, ~digits=0, ~percent=true)->React.string}
                        </span>
                      </div>
                    )
                    ->React.array}
                  </div>}
              <div
                className="mt-2 pt-2"
                style={ReactDOM.Style.make(
                  ~borderTop="1px solid " ++ ruleSoft,
                  ~fontFamily=monoFont,
                  ~fontSize="10px",
                  ~color=mute,
                  ~lineHeight="1.6",
                  (),
                )}>
                {(seedCount < 2
                  ? ts`Single seed — no error bars, so treat any ordering here as provisional. Raise the seed count to tell real differences from noise.`
                  : coLeaders > 1
                  ? ts`± is the standard error over ${Int.toString(
                      seedCount,
                    )} seeds. ${Int.toString(
                      coLeaders,
                    )} strategies are tied for best on ladder error — their gaps are inside the error bars, so the ordering between them is not a result.`
                  : ts`± is the standard error over ${Int.toString(
                      seedCount,
                    )} seeds. Bold marks a value nothing else is within error of.`)->React.string}
                {ts` Ranked by the three columns combined, weighted equally. Rows below the dashed line matchmake from hidden true skill — they mark the ceiling and are excluded from the ranking. All three are rolling averages over the last ${Int.toString(
                    Js.Math.min_int(round, summaryWindow(~round)),
                  )} rounds, so they say how each strategy is doing now rather than how it did overall — drag the round slider to watch them move. places off = how far the average player sits from their true rank (lower better) · quality = chance a game ends level, by true skill (higher better) · blowouts = share of games decided by 9+ (lower better).`->React.string}
              </div>
            </>
          }
        </div>
      </div>
    </div>
  | _ =>
    <div style={panelStyle}>
      <div style={ReactDOM.Style.make(~fontSize="13px", ~color=mute, ~lineHeight="1.5", ())}>
        {ts`Pick a scenario and press Run. Each round is a real solve through the same optimiser the app uses, and every field is simulated across several seeds, so a run takes a little while.`->React.string}
      </div>
    </div>
  }

  <div
    style={ReactDOM.Style.make(
      ~background=paper,
      ~color=ink,
      ~minHeight="100%",
      ~padding="16px",
      ~fontFamily="ui-sans-serif, system-ui, -apple-system, 'Helvetica Neue', sans-serif",
      (),
    )}>
    // Header
    <div
      className="pb-3 mb-4"
      style={ReactDOM.Style.make(~borderBottom="2px solid " ++ ink, ())}>
      <Eyebrow>
        {ts`${Int.toString(numPlayers)} players · ${Int.toString(
            courts,
          )} courts · ${Int.toString(numRounds)} rounds · real solver`->React.string}
      </Eyebrow>
      <h1
        style={ReactDOM.Style.make(
          ~fontSize="26px",
          ~fontWeight="700",
          ~letterSpacing="-0.02em",
          ~margin="4px 0 6px",
          ~lineHeight="1.05",
          (),
        )}>
        {ts`Does balanced matchmaking find the truth?`->React.string}
      </h1>
      <div
        style={ReactDOM.Style.make(
          ~fontSize="13px",
          ~color=mute,
          ~maxWidth="640px",
          ~lineHeight="1.45",
          (),
        )}>
        {ts`Red ticks are true skill; blue bars are what the rating system currently believes. Rows are ordered by true skill, strongest first — a correct system reads as a clean staircase.`->React.string}
      </div>
    </div>
    // Saved runs. Only rendered when the generator has published some.
    {savedRuns->Array.length == 0
      ? React.null
      : <div
          className="flex items-center gap-2 flex-wrap mb-3"
          style={ReactDOM.Style.make(
            ~background=panel,
            ~border="1px solid " ++ rule,
            ~padding="8px 12px",
            ~fontFamily=monoFont,
            ~fontSize="11px",
            ~color=mute,
            (),
          )}>
          <span> {ts`saved runs`->React.string} </span>
          {savedRuns
          ->Array.map(entry =>
            <button
              key={entry.file}
              style={btnStyle(
                loadedInfo->Option.mapOr(false, ((file, _)) => file == entry.file),
              )}
              disabled={isRunning || loadingFile != None}
              onClick={_ => loadSaved(entry)}>
              {(loadingFile == Some(entry.file)
                ? ts`loading…`
                : savedRunLabel(entry))->React.string}
            </button>
          )
          ->React.array}
          <span>
            {ts`precomputed · loads in a second instead of an hour`->React.string}
          </span>
        </div>}
    {switch loadError {
    | None => React.null
    | Some(e) =>
      <div
        className="mb-3"
        style={ReactDOM.Style.make(
          ~border="1px solid " ++ rule,
          ~padding="8px 12px",
          ~fontFamily=monoFont,
          ~fontSize="11px",
          ~color=ink,
          (),
        )}>
        {ts`Could not load the saved run: ${e}`->React.string}
      </div>
    }}
    // Scenario
    <div className="flex flex-wrap gap-2 mb-2">
      {SimLab.scenarios
      ->Array.map(s =>
        <button
          key={SimLab.scenarioId(s)}
          style={btnStyle(scenario == s)}
          disabled={isRunning}
          onClick={_ => setScenario(_ => s)}>
          {scenarioLabel(s)->React.string}
        </button>
      )
      ->React.array}
      <button
        className="ml-auto"
        style={btnStyle(false)}
        disabled={isRunning}
        onClick={_ => setSeed(v => v + 1)}>
        {ts`reseed (${Int.toString(seed)})`->React.string}
      </button>
    </div>
    <div style={ReactDOM.Style.make(~fontSize="12px", ~color=mute, ~marginBottom="14px", ())}>
      {scenarioBlurb(scenario)->React.string}
    </div>
    // Setup + run
    <div
      className="flex items-center gap-4 flex-wrap mb-4"
      style={ReactDOM.Style.make(
        ~background=panel,
        ~border="1px solid " ++ rule,
        ~padding="8px 12px",
        ~fontFamily=monoFont,
        ~fontSize="11px",
        ~color=mute,
        (),
      )}>
      <label className="flex items-center gap-2">
        {ts`players`->React.string}
        <input
          type_="range"
          min="8"
          max="32"
          step=1.
          value={Int.toString(numPlayers)}
          disabled={isRunning}
          onChange={e => {
            let v = (e->ReactEvent.Form.target)["value"]->Int.fromString->Option.getOr(18)
            setNumPlayers(_ => v)
            // Courts cannot outrun the roster; keep the current choice if it
            // still fits so the players slider does not fight the courts one.
            setCourts(c => Js.Math.min_int(c, Js.Math.max_int(1, v / 4)))
          }}
          style={ReactDOM.Style.make(~width="90px", ())->withProp("accentColor", ink)}
        />
        <span style={ReactDOM.Style.make(~color=ink, ~width="24px", ())}>
          {Int.toString(numPlayers)->React.string}
        </span>
      </label>
      <label className="flex items-center gap-2">
        {ts`courts`->React.string}
        <input
          type_="range"
          min="1"
          max={Int.toString(Js.Math.max_int(1, numPlayers / 4))}
          step=1.
          value={Int.toString(courts)}
          disabled={isRunning}
          onChange={e =>
            setCourts(_ => (e->ReactEvent.Form.target)["value"]->Int.fromString->Option.getOr(3))}
          style={ReactDOM.Style.make(~width="70px", ())->withProp("accentColor", ink)}
        />
        <span style={ReactDOM.Style.make(~color=ink, ~width="86px", ())}>
          {ts`${Int.toString(courts)} · ${Int.toString(
              numPlayers - courts * 4,
            )} sit`->React.string}
        </span>
      </label>
      <label className="flex items-center gap-2">
        {ts`rounds`->React.string}
        <input
          type_="range"
          min="5"
          max="100"
          step=5.
          value={Int.toString(numRounds)}
          disabled={isRunning}
          onChange={e => {
            let v = (e->ReactEvent.Form.target)["value"]->Int.fromString->Option.getOr(20)
            setNumRounds(_ => v)
          }}
          style={ReactDOM.Style.make(~width="90px", ())->withProp("accentColor", ink)}
        />
        <span style={ReactDOM.Style.make(~color=ink, ~width="26px", ())}>
          {Int.toString(numRounds)->React.string}
        </span>
      </label>
      <label className="flex items-center gap-2">
        {ts`tournament`->React.string}
        <input
          type_="checkbox"
          checked={tournament}
          disabled={isRunning}
          onChange={e => {
            let v = (e->ReactEvent.Form.target)["checked"]
            setTournament(_ => v)
          }}
          style={ReactDOM.Style.make(~width="14px", ~height="14px", ())->withProp(
            "accentColor",
            ink,
          )}
        />
        <span style={ReactDOM.Style.make(~color=ink, ~width="120px", ())}>
          {(tournament ? ts`fixed squads of 4` : ts`everyone mixes`)->React.string}
        </span>
      </label>
      <label className="flex items-center gap-2">
        {ts`seeds`->React.string}
        <input
          type_="range"
          min="1"
          max="7"
          step=1.
          value={Int.toString(seedCount)}
          disabled={isRunning}
          onChange={e =>
            setSeedCount(_ =>
              (e->ReactEvent.Form.target)["value"]->Int.fromString->Option.getOr(3)
            )}
          style={ReactDOM.Style.make(~width="70px", ())->withProp("accentColor", ink)}
        />
        <span style={ReactDOM.Style.make(~color=ink, ~width="88px", ())}>
          {(seedCount == 1 ? ts`1 · no error` : ts`${Int.toString(seedCount)} · ± shown`)
          ->React.string}
        </span>
      </label>
      <button style={btnStyle(true)} disabled={isRunning} onClick={_ => runSim()}>
        {(isRunning ? ts`running…` : ts`Run simulation`)->React.string}
      </button>
      {isRunning
        ? <span>
            {ts`${Int.toString(progress)} / ${Int.toString(totalSolves)} solves`->React.string}
          </span>
        : <span className="ml-auto">
            {(totalSolves > 300
              ? ts`every round is a real ILP solve · ${Int.toString(
                  totalSolves,
                )} rounds to build — this will take a while`
              : ts`every round is a real ILP solve · ${Int.toString(
                  totalSolves,
                )} rounds to build`)->React.string}
          </span>}
    </div>
    // What is actually on screen. A saved run leaves the controls above
    // editable, so this states its own parameters rather than letting the
    // sliders speak for it.
    {switch loadedInfo {
    | None => React.null
    | Some((_, info)) =>
      <div
        className="mb-4"
        style={ReactDOM.Style.make(
          ~background=panel,
          ~border="1px solid " ++ rule,
          ~padding="8px 12px",
          ~fontFamily=monoFont,
          ~fontSize="11px",
          ~color=ink,
          (),
        )}>
        {ts`showing a saved run · ${scenarioLabel(info.scenario)} · ${Int.toString(
            info.numPlayers,
          )} players · ${Int.toString(info.courts)} courts · ${Int.toString(
            info.numRounds,
          )} rounds · ${Int.toString(
            info.seedCount,
          )} seeds. Ladder and round detail come from the first seed; the charts and standings average all of them.`->React.string}
      </div>
    }}
    {switch primary {
    | None => React.null
    | Some(r) =>
      <>
        // Transport
        <div
          className="flex items-center gap-3 flex-wrap mb-4"
          style={ReactDOM.Style.make(
            ~background=panel,
            ~border="1px solid " ++ rule,
            ~padding="8px 10px",
            (),
          )}>
          <button style={btnStyle(playing)} onClick={_ => setPlaying(p => !p)}>
            {(playing ? ts`pause` : ts`play`)->React.string}
          </button>
          <button
            style={btnStyle(false)}
            onClick={_ => {
              setPlaying(_ => false)
              setRound(v => Js.Math.min_int(r.numRounds, v + 1))
            }}>
            {ts`step`->React.string}
          </button>
          <button
            style={btnStyle(false)}
            onClick={_ => {
              setPlaying(_ => false)
              setRound(_ => 0)
            }}>
            {ts`reset`->React.string}
          </button>
          <div style={ReactDOM.Style.make(~fontFamily=monoFont, ~fontSize="13px", ~minWidth="96px", ())}>
            {ts`round ${Int.toString(round)}/${Int.toString(r.numRounds)}`->React.string}
          </div>
          <input
            type_="range"
            min="0"
            max={Int.toString(r.numRounds)}
            value={Int.toString(round)}
            onChange={e => {
              setPlaying(_ => false)
              setRound(_ =>
                (e->ReactEvent.Form.target)["value"]->Int.fromString->Option.getOr(0)
              )
            }}
            className="flex-1"
            style={ReactDOM.Style.make(~minWidth="160px", ())->withProp("accentColor", ink)}
          />
          <label
            style={ReactDOM.Style.make(~fontSize="11px", ~color=mute, ~fontFamily=monoFont, ())}>
            {ts`speed`->React.string}
            <input
              type_="range"
              min="1"
              max="30"
              value={Int.toString(speed)}
              onChange={e =>
                setSpeed(_ =>
                  (e->ReactEvent.Form.target)["value"]->Int.fromString->Option.getOr(6)
                )}
              style={ReactDOM.Style.make(~marginLeft="6px", ~width="80px", ())->withProp("accentColor", ink)}
            />
          </label>
        </div>
        // Which field's results are showing. All three were simulated.
        <div
          className="flex items-center gap-2 flex-wrap mb-3"
          style={ReactDOM.Style.make(~fontFamily=monoFont, ~fontSize="11px", ~color=mute, ())}>
          {ts`field`->React.string}
          {[(0, ts`varied`), (1, ts`typical`), (2, ts`tight`)]
          ->Array.map(((value, label)) => {
            let active = value == fieldIndex
            <button
              key={label}
              onClick={_ => setFieldIndex(_ => value)}
              style={ReactDOM.Style.make(
                ~padding="4px 10px",
                ~fontFamily=monoFont,
                ~fontSize="11px",
                ~border="1px solid " ++ (active ? ink : rule),
                ~background=active ? ink : "transparent",
                ~color=active ? paper : ink,
                ~cursor="pointer",
                (),
              )}>
              {label->React.string}
            </button>
          })
          ->React.array}
          <span>
            {switch fieldIndex {
            | 0 => ts`a wide field plus a ringer and a beginner nobody can balance around`
            | 2 => ts`a narrow, heavily bunched pack — hard to tell anyone apart`
            | _ => ts`about a 1.0 DUPR spread, roughly 3.0 to 4.0 — what most clubs look like`
            }->React.string}
          </span>
        </div>
        // Strategy selector
        <div className="flex flex-wrap gap-2 mb-4">
          {r.runs
          ->Array.mapWithIndex((other, idx) => {
            let style =
              btnStyle(idx == stratIndex)->withProp(
                "borderLeft",
                "4px solid " ++ other.entry.color,
              )
            <button
              key={other.entry.short}
              style
              onClick={_ => setStratIndex(_ => idx)}>
              {strategyLabel(other.entry)->React.string}
            </button>
          })
          ->React.array}
          {r.runs->Array.some(x => x.fellBackToGreedy)
            ? <span
                style={ReactDOM.Style.make(
                  ~fontFamily=monoFont,
                  ~fontSize="11px",
                  ~color=warn,
                  ~alignSelf="center",
                  (),
                )}>
                {ts`optimiser unavailable — some rounds fell back to the greedy engine`
                ->React.string}
              </span>
            : React.null}
        </div>
        <div style={ReactDOM.Style.make(~fontSize="12px", ~color=mute, ~marginBottom="14px", ())}>
          {(r.runs->Array.get(stratIndex)->Option.getOr(r.runs->Array.getUnsafe(0))).entry
          ->strategyBlurb
          ->React.string}
        </div>
      </>
    }}
    content
  </div>
}

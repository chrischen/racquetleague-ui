// Cost model for the ILP round builder.
//
// Everything in here is pure: history counts in, per-candidate cost and
// per-player benefit out. `SolverRound` turns those numbers into an objective;
// `LpBuilder` turns the objective into LP text.
//
// The invariant the rest of the solver leans on: **every cost and benefit
// component is normalised to [0, 1] before it is weighted**. That is what makes
// `maxMatchCost` / `maxPlayerBenefit` exact upper bounds, which in turn is what
// lets `SolverRound` derive penalty tiers that provably cannot be reordered by
// user weight settings.

open Rating

// ---------------------------------------------------------------------------
// Small numeric helpers
// ---------------------------------------------------------------------------

let clamp = (v: float, lo: float, hi: float): float => v < lo ? lo : v > hi ? hi : v
let clamp01 = (v: float): float => clamp(v, 0., 1.)

// ---------------------------------------------------------------------------
// Weights
// ---------------------------------------------------------------------------

// Upper bound for any single tunable weight. Together with the [0, 1]
// normalisation this caps one match's regular cost.
let maxWeight = 1000.

type costWeights = {
  wPartner: float, // repeat partnerships
  wOpponent: float, // repeat opponents
  wRepeatLast: float, // same team / same foursome as the previous round
  // Same foursome as *any* previous round — legacy's `repeatedGroup` tier.
  // Load-bearing, not redundant with the pair counts: once every pair in a
  // neighbourhood has been worn once, an exact rerun and a never-played
  // matchup built from equally worn pairs cost identically at pair level (an
  // exact 600-600 tie at the novelty presets), and the solver would re-deal
  // yesterday's match while fresh matchups existed. This term breaks that tie.
  wRepeatGroup: float,
  // Whether each foursome must use its most balanced team split. A boolean on
  // purpose: within a single match, balanced vs unbalanced is a yes/no
  // property — a foursome has three splits and "balanced" means taking the
  // minimum-gap one — so it is enforced as a hard candidate filter in
  // `SolverRound` rather than negotiated as a weight.
  balanceTeams: bool,
  wSpread: float, // mu range across the four players (banding)
  wAlternate: float, // favoured / underdog alternation
  wNoise: float, // per-candidate jitter, for tie-breaking only
  // How a foursome's split filter breaks ties (only meaningful with
  // `balanceTeams` on). False = variety first: never repeat a partnership
  // while a fresh split exists, then balance — the whist contract (Round
  // Robin) and the legacy cascade's ordering (Competitive+). True = balance
  // first: every match takes its most balanced split even at the cost of a
  // repeated partnership — Random Balanced's defining promise, where
  // composition is already randomised by noise and partner variety is a
  // preference rather than a contract.
  splitBalanceFirst: bool,
  // Cohort rotation: a rank-ordered bias in the play benefit, so that among
  // fairness-*tied* players the court fills strongest-first and the bye set is
  // the bottom band of the eligible cohort — bands play together and break
  // together, as the legacy competitive engine did. Capped at
  // `maxCohortWeight`, which is below one game of count-deficit, so it can
  // reorder who sits among equals but never costs anyone a game. Preset-only
  // (not user configurable), like the other rotation guardrails.
  wCohort: float,
  // Fraction of the pool's mu range a foursome may span before the spread
  // guardrail starts charging. A shape parameter rather than a magnitude, and
  // the one place the "Competitive <-> Mix players" control changes *what*
  // counts as too much spread rather than merely how much it costs. Excluded
  // from `maxMatchCost` for that reason.
  spreadTolerance: float,
}

// Guardrails. Deliberately *not* user configurable: no slider position may make
// a mode stop rotating players in. See the penalty hierarchy in `SolverRound`.
//
// `wByeDeficit` is sized so that being one game behind the most-played player
// (see `byeDeficitScale`) outweighs the entire `wByeStreak` range: games-played
// fairness decides who sits, and the streak only breaks ties between players on
// equal counts.
let wByeDeficit = 4000.
let wByeStreak = 1000.
let wPriority = 1500.

// Ceiling for `wCohort`: below one game of count-deficit (wByeDeficit / 3 =
// 1333 per game behind), so cohort ordering can never trade play time.
let maxCohortWeight = 600.

// Exact upper bound on `playerBenefit`.
let maxPlayerBenefit = wByeDeficit +. wByeStreak +. wPriority +. maxCohortWeight

// Exact upper bound on `candidateCost` for a given weight set. Balance is
// absent: it is a filter, not a cost term.
let maxMatchCost = (w: costWeights): float =>
  w.wPartner +. w.wOpponent +. w.wRepeatLast +. w.wRepeatGroup +. w.wSpread +. w.wAlternate +. w.wNoise

// ---------------------------------------------------------------------------
// UI configuration -> weights
// ---------------------------------------------------------------------------

// The advanced panel's vocabulary. Every preference `costWeights` expresses is
// present (only the guardrail tier — bye fairness, rotation, court fill — is
// withheld), so the named presets are exactly representable as configs and the
// panel can show the true tuned values rather than a slider approximation.
// Sliders are [0, 1]; each field documents its mapping to the weight it drives.
type advancedWeights = {
  partnerVariety: float, // log scale -> wPartner (wRepeatGroup derived at 0.6x)
  opponentVariety: float, // log scale -> wOpponent
  avoidRecentRepeats: float, // log scale -> wRepeatLast
  // Banding, as its two real knobs. Strength: 0 = skill plays no part in who
  // shares a court (the carry-match guardrail floor only), 1 = banding is a
  // first-class objective. Tolerance: how much of the pool's mu range a
  // foursome may span for free — 1 = ordinary mixing is free, 0 = the
  // guardrail bites immediately (linear -> spreadTolerance = 0.9 * value).
  bandStrength: float, // linear -> wSpread = max(floor, 1000 * value)
  bandTolerance: float,
  // See `costWeights.balanceTeams` — a toggle, not a degree.
  balanceTeams: bool,
  // See `costWeights.splitBalanceFirst`. Only meaningful with balance on.
  splitBalanceFirst: bool,
  alternateFavored: float, // linear -> wAlternate = 1000 * value
  shakeUp: float, // linear -> wNoise = 1000 * value (tie-breaking jitter)
  cohortRotation: float, // linear -> wCohort = 600 * value (capped guardrail-safe)
}

type uiWeightConfig = {
  // 0.0 = pure variety, 1.0 = pure quality. The one control most users touch.
  qualityVsVariety: float,
  // Present once the user has touched the advanced accordion; overrides the
  // values the primary slider would have derived.
  advanced: option<advancedWeights>,
}

// Slider position -> weight, on a log curve so the slider feels linear in
// effect rather than bunching everything at the top.
let logScale = (a: float): float => Js.Math.round(10. *. Js.Math.pow_float(~base=100., ~exp=clamp01(a)))

// Inverse of `logScale`, for showing the advanced sliders at the positions the
// primary slider implies.
let logScaleInverse = (w: float): float =>
  clamp01(Js.Math.log(Js.Math.max_float(w, 1e-6) /. 10.) /. Js.Math.log(100.))

// Spread never drops to zero: without it, equalising team sums actively rewards
// pairing the strongest player with the weakest (see the spread test).
let minSpreadWeight = 50.

// Constant across the primary slider; only the advanced slider moves it.
let defaultAlternateWeight = 100.

// Where "Competitive+" sits on the primary slider. Cohort rotation switches on
// here and above; `competitivePlusConfig` is this position's decomposition.
let competitivePosition = 0.85

// Slider -> how much skill spread a foursome may have for free.
//
// At the mixing end almost anything goes, so only a genuine
// strongest-with-weakest pairing is penalised. At the quality end the guardrail
// bites immediately, which is what actually produces skill bands: balancing
// team *sums* does not, since {rank 1 + rank 11} vs {rank 4 + rank 8} has a
// near-zero sum gap while still being a carry match.
let spreadToleranceFor = (skillFocus: float): float => 0.9 *. (1. -. clamp01(skillFocus))

// Magnitude half of the same control. At 0 the floor keeps only the
// carry-match guardrail alive; at 1 banding is a first-class objective.
let spreadWeightFor = (skillFocus: float): float =>
  Js.Math.max_float(minSpreadWeight, Js.Math.round(maxWeight *. clamp01(skillFocus)))

let weightsFromConfig = (config: uiWeightConfig): costWeights => {
  let t = clamp01(config.qualityVsVariety)
  let wPartner = Js.Math.round(10. *. Js.Math.pow_float(~base=100., ~exp=1. -. t))
  let derived = {
    wPartner,
    wOpponent: Js.Math.round(wPartner /. 5.),
    wRepeatLast: Js.Math.round(wPartner /. 2.),
    wRepeatGroup: Js.Math.round(wPartner *. 0.6),
    // The variety end of the primary slider is quality-blind; everywhere else
    // balanced splits are simply on.
    balanceTeams: t >= 0.2,
    wSpread: spreadWeightFor(t),
    wAlternate: defaultAlternateWeight,
    wNoise: 0.,
    // Cohort rotation switches on at the Competitive+ position and above.
    // Bands playing and breaking together is what leveled play means, so the
    // primary slider should reach it — without this the slider could get you
    // Competitive+'s banding but never its rotation, and only the advanced
    // panel could restore it.
    wCohort: t >= competitivePosition ? maxCohortWeight : 0.,
    splitBalanceFirst: false,
    spreadTolerance: spreadToleranceFor(t),
  }

  switch config.advanced {
  | None => derived
  | Some(a) => {
      wPartner: logScale(a.partnerVariety),
      wOpponent: logScale(a.opponentVariety),
      wRepeatLast: logScale(a.avoidRecentRepeats),
      wRepeatGroup: Js.Math.round(logScale(a.partnerVariety) *. 0.6),
      balanceTeams: a.balanceTeams,
      wSpread: spreadWeightFor(a.bandStrength),
      wAlternate: Js.Math.round(maxWeight *. clamp01(a.alternateFavored)),
      wNoise: Js.Math.round(maxWeight *. clamp01(a.shakeUp)),
      wCohort: Js.Math.round(maxCohortWeight *. clamp01(a.cohortRotation)),
      // Split ordering only exists once splits are constrained at all.
      splitBalanceFirst: a.balanceTeams && a.splitBalanceFirst,
      spreadTolerance: 0.9 *. clamp01(a.bandTolerance),
    }
  }
}

// The advanced-panel representation of a weight set. Exact for config-derived
// weights (the mappings are inverses); for blended weights (the adaptive
// profile) the log-scale positions round to the nearest representable value —
// display-grade, and the right seed for a customisation fork.
let advancedFromWeights = (w: costWeights): advancedWeights => {
  partnerVariety: logScaleInverse(w.wPartner),
  opponentVariety: logScaleInverse(w.wOpponent),
  avoidRecentRepeats: logScaleInverse(w.wRepeatLast),
  bandStrength: w.wSpread /. maxWeight,
  bandTolerance: w.spreadTolerance /. 0.9,
  balanceTeams: w.balanceTeams,
  splitBalanceFirst: w.splitBalanceFirst,
  alternateFavored: w.wAlternate /. maxWeight,
  shakeUp: w.wNoise /. maxWeight,
  cohortRotation: w.wCohort /. maxCohortWeight,
}

// The advanced-slider positions a given primary position implies. Shown when a
// custom config has a primary value but no advanced overrides; touching one of
// them marks the config custom.
let advancedFromPrimary = (qualityVsVariety: float): advancedWeights =>
  advancedFromWeights(weightsFromConfig({qualityVsVariety, advanced: None}))

// ---------------------------------------------------------------------------
// Solver preset configs
// ---------------------------------------------------------------------------
//
// The solver strategies are configs in the advanced vocabulary, and
// `weightsForStrategy` is literally `weightsFromConfig(presetConfig(s))`: one
// source of truth, so the panel always displays the real tuned values and
// forking a preset preserves its full behaviour. Presets are code, not data:
// only a *customised* `uiWeightConfig` is ever persisted, so preset retuning
// applies retroactively.
//
//   Round Robin      (SolverRoundRobin variant)
//     Maximum variety: fresh partners are non-negotiable, opponents close
//     behind. Ties break the Competitive+ way — banded, balanced matches — so
//     a session *starts* competitive and mixes as each band's novelty
//     exhausts. Splits are always balanced.
//
//   Random Balanced  (SolverRandomBalanced variant)
//     The same novelty core with skill spread at *no concern*: who shares a
//     court is rotation-random (plus a little tie-breaking jitter), and every
//     match's teams are balanced by skill.
//
//   Competitive+     (SolverCompetitivePlusStatic variant)
//     Quality first: banding at full strength with balanced splits and cohort
//     rotation, so bands play together and break together.

// The novelty-first core Round Robin and Random Balanced share. wPartner 1000
// with wOpponent/wRepeatLast at 500 and the derived group tier at 600 keeps
// the legacy ordering teams > group > opponents: one partner repeat (400 on
// the normalized scale) beats one foursome rerun (240) beats the whole
// opponent range (200) — and all of it dominates every quality term.
let noveltyAdvancedBase: advancedWeights = {
  partnerVariety: 1.0, // wPartner 1000: fresh partners are non-negotiable
  opponentVariety: logScaleInverse(500.),
  avoidRecentRepeats: logScaleInverse(500.),
  // "No concern for skill spread": the guardrail floor, at a tolerance where
  // ordinary mixing is free.
  bandStrength: minSpreadWeight /. maxWeight,
  bandTolerance: 1.0,
  // Splits are balanced by construction (the toggle is a hard filter), so no
  // weight arithmetic is involved and novelty dominance is untouched.
  balanceTeams: true,
  splitBalanceFirst: false,
  alternateFavored: 0.1,
  shakeUp: 0.,
  cohortRotation: 0.,
}

let roundRobinConfig: uiWeightConfig = {
  qualityVsVariety: 0.15,
  advanced: Some({
    ...noveltyAdvancedBase,
    // "Start off with competitive+ first until that's exhausted": a
    // tiebreak-sized banding term with a tight shape. Early rounds — when
    // every schedule is equally novel — come out banded and even; as each
    // band's partner combinations run out, novelty dominance forces mixing.
    // Deliberately a strength/tolerance pair the primary slider's coupled
    // mapping cannot express. Dominance holds: 140 + 100 + 0 < 400.
    bandStrength: 0.14, // wSpread 140
    bandTolerance: 0.25 /. 0.9, // spreadTolerance 0.25
  }),
}

let randomBalancedConfig: uiWeightConfig = {
  qualityVsVariety: 0.0,
  advanced: Some({
    ...noveltyAdvancedBase,
    // "Random should strictly randomize the matchup": noise at the legacy
    // Random strategy's magnitude, so composition genuinely varies among
    // comparably novel options — while one partner repeat (400) still
    // dominates it, keeping maximum variety intact.
    shakeUp: 0.05, // wNoise 50
    // And no favoured/underdog steering — a random mode should not shape who
    // is on which side of a matchup.
    alternateFavored: 0.,
    // Who plays whom is random; how they split is balanced.
    splitBalanceFirst: true,
  }),
}

let competitivePlusConfig: uiWeightConfig = {
  qualityVsVariety: 0.85,
  advanced: Some({
    // The 0.85 slider position's own decomposition (wOpponent lands on the
    // log scale's floor of 10 rather than the old derived 4 — a
    // tie-break-sized retune accepted for exact representability)...
    partnerVariety: 0.15, // wPartner 20
    opponentVariety: 0., // wOpponent 10
    avoidRecentRepeats: 0., // wRepeatLast 10
    bandStrength: 0.85, // wSpread 850: banding at full strength
    bandTolerance: 0.15, // spreadTolerance 0.135: the guardrail bites at once
    balanceTeams: true,
    splitBalanceFirst: false,
    alternateFavored: 0.1,
    shakeUp: 0.,
    // ...plus leveled play's cohort rotation: the court fills strongest-first
    // among fairness ties, so skill bands play together and take their breaks
    // together instead of individuals alternating out of phase with their
    // band. Capped below one game of count-deficit, so it can never trade
    // play time.
    cohortRotation: 1.0, // wCohort 600
  }),
}

// The adaptive profile's cold-start endpoint. Not a picker preset and not a slider position:
// it is the profile Competitive+ opens with, tuned for the rounds where the
// ladder is
// still fiction.
//
// It is the novelty-first core plus three things Random Balanced lacks:
//
//   1. LIGHT banding, at Round Robin's tiebreak strength (wSpread 140,
//      tolerance 0.25) rather than Competitive+'s (850 / 0.135). Grouping
//      comparable players makes each game closer and so more informative,
//      while novelty dominance still forces cross-band play. It is *heavy*
//      banding that stalls a cold start, by locking players into bands drawn
//      on noise — the two are not the same lever, and the blend cannot
//      express this one, since it moves weight and tolerance together and so
//      never visits "modest weight, tight tolerance".
//   2. Favoured/underdog alternation, as Round Robin has.
//   3. Balance-first splits, as Random Balanced has.
//
// Measured against opening with Random Balanced, cold start, 12 seeds over 20
// rounds, with the two additions decomposed:
//
//   Random Balanced plain            20.31% blowouts
//   + alternation                    19.06%
//   + alternation + light banding    17.92%   <- this profile
//
// Both additions contribute, roughly equally, and the total (~2.4pp) has held
// across four runs at different seed counts and horizons. Each individual step
// is inside the per-seed noise (se ~1.9pp on a difference), so treat the total
// as suggestive-but-not-proven and the split between the two as indicative
// only. Rating error is a wash: it crosses back and forth between the two
// endpoints across rounds, which is the signature of noise rather than effect.
// So the honest claim is narrow: somewhat fewer blowouts, same accuracy.
//
// Why light banding helps at all, when ratings are still noise: it does not
// reshape the distribution of foursome spread (measured: median span 0.63 vs
// 0.64, p90 1.00 for both — though that metric is degenerate at cold start,
// where the pool's own mu-range is tiny, so it cannot resolve the mechanism
// either way). The plausible account is a weak tilt — from round 2 the visible
// ratings correlate with truth just enough that preferring closer-rated
// foursomes yields truly-comparable ones slightly more often. A ~1pp effect is
// consistent with a tilt that weak. This is inference, not a measured
// mechanism.
let calibrateConfig: uiWeightConfig = {
  qualityVsVariety: 0.15,
  advanced: Some({
    ...noveltyAdvancedBase,
    bandStrength: 0.14,
    bandTolerance: 0.25 /. 0.9,
    splitBalanceFirst: true,
    alternateFavored: 0.1,
    shakeUp: 0.05,
  }),
}

let presetConfig = (strategy: strategy): uiWeightConfig =>
  switch strategy {
  | SolverRoundRobin => roundRobinConfig
  | SolverRandomBalanced => randomBalancedConfig
  | SolverCompetitivePlusStatic => competitivePlusConfig
  // The adaptive profile's weights are a live blend (see `adaptiveWeightsAt`);
  // a custom config forked from it starts mid-axis, the blend's own halfway
  // point.
  | SolverCompetitivePlus => {qualityVsVariety: 0.5, advanced: None}
  // Legacy strategies get the nearest nominal, so the cost model can also be
  // used to *score* rounds produced by the greedy path (see `SessionMetrics`).
  | RoundRobin | NoveltyRoundRobin | Random => {qualityVsVariety: 0.15, advanced: None}
  | Mixed | DUPR => {qualityVsVariety: 0.5, advanced: None}
  | Competitive | CompetitivePlus => {qualityVsVariety: 0.85, advanced: None}
  }

// Random is not a slider position: it wants no preference at all beyond the
// spread floor, plus jitter so ties break differently every seed.
let randomWeights: costWeights = {
  wPartner: 0.,
  wOpponent: 0.,
  wRepeatLast: 0.,
  wRepeatGroup: 0.,
  balanceTeams: false,
  wSpread: minSpreadWeight,
  wAlternate: 0.,
  wNoise: 50.,
  wCohort: 0.,
  splitBalanceFirst: false,
  spreadTolerance: spreadToleranceFor(0.),
}

// ---------------------------------------------------------------------------
// Solver preset profiles — derived from the configs above, nothing more
// ---------------------------------------------------------------------------

let roundRobinWeights = weightsFromConfig(roundRobinConfig)
let randomBalancedWeights = weightsFromConfig(randomBalancedConfig)
let competitivePlusWeights = weightsFromConfig(competitivePlusConfig)
let calibrateWeights = weightsFromConfig(calibrateConfig)

// ---------------------------------------------------------------------------
// Adaptive Competitive+: calibrate first, band once the ratings earn it
// ---------------------------------------------------------------------------
//
// The measured convergence facts this encodes (see Convergence.test.ts): while
// ratings are still noise, variety-first play with balanced splits teaches the
// rating system fastest, and banding by those ratings only schedules fiction;
// once ratings separate, Competitive+'s banding is accurate and is what leveled
// play wants. "Settled" is a signal-to-noise ratio — how far the pool's mu
// spread has grown past its mean sigma — not absolute sigma, which decays far
// too slowly in openskill to ever cross a threshold.

// Pool signal-to-noise: std(mu) / mean(sigma).
let readinessRatio = (players: array<Player.t<'a>>): float => {
  let n = players->Array.length->Int.toFloat
  if n < 2. {
    0.
  } else {
    let meanMu = players->Array.reduce(0., (acc, p) => acc +. p.rating.mu) /. n
    let variance =
      players->Array.reduce(0., (acc, p) => {
        let d = p.rating.mu -. meanMu
        acc +. d *. d
      }) /. n
    let meanSigma = players->Array.reduce(0., (acc, p) => acc +. p.rating.sigma) /. n
    meanSigma <= 0. ? 1. : Js.Math.sqrt(variance) /. meanSigma
  }
}

// Ratio -> blend position. 0.30 is just above a cold-start pool (measured
// ~0.24 after one round); 0.75 is the "ratings have settled" criterion, where
// pools land around round 8 at 16 players. Between the two the profile
// interpolates, so a session drifts from calibration into leveled play instead
// of jumping.
let readinessFloor = 0.30
let readinessCeiling = 0.75

let adaptiveBlend = (ratio: float): float =>
  clamp01((ratio -. readinessFloor) /. (readinessCeiling -. readinessFloor))

let lerp = (a: float, b: float, t: float): float => a +. (b -. a) *. t

let adaptiveWeightsAt = (t: float): costWeights => {
  let cal = calibrateWeights
  let cp = competitivePlusWeights
  {
    wPartner: lerp(cal.wPartner, cp.wPartner, t),
    wOpponent: lerp(cal.wOpponent, cp.wOpponent, t),
    wRepeatLast: lerp(cal.wRepeatLast, cp.wRepeatLast, t),
    wRepeatGroup: lerp(cal.wRepeatGroup, cp.wRepeatGroup, t),
    balanceTeams: true, // both endpoints: every match takes its balanced split
    wSpread: lerp(cal.wSpread, cp.wSpread, t),
    wAlternate: lerp(cal.wAlternate, cp.wAlternate, t),
    wNoise: lerp(cal.wNoise, cp.wNoise, t),
    wCohort: lerp(cal.wCohort, cp.wCohort, t),
    // Boolean semantics switch at the midpoint: balance-first tie-breaking
    // keeps blowouts down while the ladder is worst; novelty-first is what
    // lets Competitive+ bands round-robin internally.
    splitBalanceFirst: t < 0.5,
    spreadTolerance: lerp(cal.spreadTolerance, cp.spreadTolerance, t),
  }
}

let adaptiveWeights = (players: array<Player.t<'a>>): costWeights =>
  adaptiveWeightsAt(adaptiveBlend(readinessRatio(players)))

let weightsForStrategy = (strategy: strategy): costWeights =>
  switch strategy {
  | Random => randomWeights
  | SolverRoundRobin => roundRobinWeights
  | SolverRandomBalanced => randomBalancedWeights
  | SolverCompetitivePlusStatic => competitivePlusWeights
  // Static callers (no pool in hand) get the cold-start end; the live blend is
  // dispatched in `SolverRounds.effectiveWeights`, which has the players.
  | SolverCompetitivePlus => calibrateWeights
  | s => weightsFromConfig(presetConfig(s))
  }

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

// Configs written before the advanced panel spoke the full weight vocabulary
// (the "similarSkill" era) are discarded on read rather than migrated — the
// event falls back to its strategy's preset, which is a better approximation
// of what the user had than any field-by-field guess. The version gate below
// is what enforces that.
let configVersion = 2.

let advancedToJson = (a: advancedWeights): Js.Json.t => {
  let d = Js.Dict.empty()
  d->Js.Dict.set("partnerVariety", a.partnerVariety->Js.Json.number)
  d->Js.Dict.set("opponentVariety", a.opponentVariety->Js.Json.number)
  d->Js.Dict.set("avoidRecentRepeats", a.avoidRecentRepeats->Js.Json.number)
  d->Js.Dict.set("bandStrength", a.bandStrength->Js.Json.number)
  d->Js.Dict.set("bandTolerance", a.bandTolerance->Js.Json.number)
  d->Js.Dict.set("balanceTeams", a.balanceTeams->Js.Json.boolean)
  d->Js.Dict.set("splitBalanceFirst", a.splitBalanceFirst->Js.Json.boolean)
  d->Js.Dict.set("alternateFavored", a.alternateFavored->Js.Json.number)
  d->Js.Dict.set("shakeUp", a.shakeUp->Js.Json.number)
  d->Js.Dict.set("cohortRotation", a.cohortRotation->Js.Json.number)
  d->Js.Json.object_
}

let advancedFromJson = (json: Js.Json.t): option<advancedWeights> =>
  json
  ->Js.Json.decodeObject
  ->Option.map(d => {
    let num = (key, fallback) =>
      d->Js.Dict.get(key)->Option.flatMap(v => v->Js.Json.decodeNumber)->Option.getOr(fallback)
    let bool = (key, fallback) =>
      d->Js.Dict.get(key)->Option.flatMap(v => v->Js.Json.decodeBoolean)->Option.getOr(fallback)
    {
      partnerVariety: num("partnerVariety", 0.5),
      opponentVariety: num("opponentVariety", 0.5),
      avoidRecentRepeats: num("avoidRecentRepeats", 0.5),
      bandStrength: num("bandStrength", 0.5),
      bandTolerance: num("bandTolerance", 0.5),
      balanceTeams: bool("balanceTeams", true),
      splitBalanceFirst: bool("splitBalanceFirst", false),
      alternateFavored: num("alternateFavored", 0.1),
      shakeUp: num("shakeUp", 0.),
      cohortRotation: num("cohortRotation", 0.),
    }
  })

let configToJson = (config: uiWeightConfig): Js.Json.t => {
  let d = Js.Dict.empty()
  d->Js.Dict.set("v", configVersion->Js.Json.number)
  d->Js.Dict.set("qualityVsVariety", config.qualityVsVariety->Js.Json.number)
  switch config.advanced {
  | None => ()
  | Some(a) => d->Js.Dict.set("advanced", a->advancedToJson)
  }
  d->Js.Json.object_
}

let configFromJson = (json: Js.Json.t): option<uiWeightConfig> =>
  json
  ->Js.Json.decodeObject
  ->Option.flatMap(d => {
    let isCurrent =
      d
      ->Js.Dict.get("v")
      ->Option.flatMap(v => v->Js.Json.decodeNumber)
      ->Option.map(v => v == configVersion)
      ->Option.getOr(false)
    isCurrent
      ? d
        ->Js.Dict.get("qualityVsVariety")
        ->Option.flatMap(v => v->Js.Json.decodeNumber)
        ->Option.map(qualityVsVariety => {
          qualityVsVariety,
          advanced: d->Js.Dict.get("advanced")->Option.flatMap(advancedFromJson),
        })
      : None
  })

let configToJsonString = (config: uiWeightConfig): string =>
  config->configToJson->Js.Json.stringify

let configFromJsonString = (str: string): option<uiWeightConfig> =>
  try {
    str->Js.Json.parseExn->configFromJson
  } catch {
  | _ => None
  }

// ---------------------------------------------------------------------------
// Favoured / underdog sides
// ---------------------------------------------------------------------------

type side =
  | Favored
  | Unfavored
  | Even // no meaningful favourite: neither satisfies nor creates a demand
  | NeverPlayed

// openskill defaults: mu = 25, sigma = mu / 3, beta = sigma / 2.
let defaultBeta = Rating.defaultBeta

// Normal quantile for p = 0.55, i.e. the edge of "predicted win prob 0.5 +- 0.05".
let evenZ = 0.1256613

let teamMuSum = (team: Team.t<'a>): float => team->Array.reduce(0., (acc, p) => acc +. p.rating.mu)

// Team-sum mu gap below which a match has no meaningful favourite. Scaled by
// the players' own uncertainty, so a cold-start pool gets a wider dead zone
// than a settled one.
let deadZoneEpsilon = (players: array<Player.t<'a>>): float => {
  let c2 =
    players->Array.reduce(0., (acc, p) =>
      acc +. p.rating.sigma *. p.rating.sigma +. defaultBeta *. defaultBeta
    )
  evenZ *. Js.Math.sqrt(c2)
}

// Sides for (team1, team2). `Even` when the gap sits inside the dead zone.
let matchSides = (match: Match.t<'a>): (side, side) => {
  let (team1, team2) = match
  let gap = teamMuSum(team1) -. teamMuSum(team2)
  let epsilon = deadZoneEpsilon(Match.players(match))
  if Js.Math.abs_float(gap) < epsilon {
    (Even, Even)
  } else if gap > 0. {
    (Favored, Unfavored)
  } else {
    (Unfavored, Favored)
  }
}

// ---------------------------------------------------------------------------
// History
// ---------------------------------------------------------------------------

let pairId = (p1: Player.t<'a>, p2: Player.t<'a>): string => [p1, p2]->Team.toStableId

type history = {
  partnerCount: Map.t<string, int>, // pairId -> times on the same team
  opponentCount: Map.t<string, int>, // pairId -> times on opposite teams
  // foursome (Match.toStableId) -> times those four shared a court
  matchGroupCount: Map.t<string, int>,
  lastRoundTeams: Set.t<string>,
  lastRoundMatches: Set.t<string>,
  satOutLastRound: Set.t<string>, // players who took a bye in the previous round
  roundsSinceLastBye: Map.t<string, int>,
  lastSide: Map.t<string, side>,
  // Games played by the busiest player in the pool. Deficits are measured
  // against this rather than the mean: the mean drifts with the shape of the
  // distribution, so "one game behind" would be worth different amounts
  // depending on how many players share the deficit.
  maxPlayedCount: int,
  avgPlayedCount: float,
  // Mu range across the whole pool. The spread guardrail is measured against
  // this so that "spans most of the field" means the same thing in a tight
  // group as in a wide one.
  poolMuRange: float,
  // Rank position in the pool, 1.0 = strongest, 0.0 = weakest. Drives the
  // cohort-rotation bias; rank rather than raw mu so the bias is uniform
  // regardless of how ratings are distributed.
  ratingPercentile: Map.t<string, float>,
  roundCount: int,
}

let emptyHistory: history = {
  partnerCount: Map.make(),
  opponentCount: Map.make(),
  matchGroupCount: Map.make(),
  lastRoundTeams: Set.make(),
  lastRoundMatches: Set.make(),
  satOutLastRound: Set.make(),
  roundsSinceLastBye: Map.make(),
  lastSide: Map.make(),
  maxPlayedCount: 0,
  avgPlayedCount: 0.,
  poolMuRange: 0.,
  ratingPercentile: Map.make(),
  roundCount: 0,
}

// Build every history-derived quantity the cost model needs in one pass.
//
// `lastSide` is computed here, during the chronological walk, using the player
// ratings embedded in each stored match — i.e. the ratings as they were when
// the match was played. Recomputing sides from *current* mu would retroactively
// flip historical sides once ratings move.
let buildHistory = (
  ~rounds: array<array<completedMatchEntity<'a>>>,
  ~players: array<Player.t<'a>>,
): history => {
  let partnerCount = Map.make()
  let opponentCount = Map.make()
  let matchGroupCount = Map.make()
  let lastSide = Map.make()
  let lastByeRound = Map.make()
  let lastRoundTeams = Set.make()
  let lastRoundMatches = Set.make()
  let satOutLastRound = Set.make()

  let bump = (map, key) => map->Map.set(key, map->Map.get(key)->Option.getOr(0) + 1)

  let roundCount = rounds->Array.length

  rounds->Array.forEachWithIndex((round, roundIndex) => {
    let isLastRound = roundIndex == roundCount - 1
    let playedThisRound = Set.make()

    round->Array.forEach(({match}) => {
      let (team1, team2) = match

      [team1, team2]->Array.forEach(team => {
        array_combos(team)->Array.forEach(((p1, p2)) => bump(partnerCount, pairId(p1, p2)))
        if isLastRound {
          lastRoundTeams->Set.add(team->Team.toStableId)
        }
      })

      noveltyOpponentPairIds(match)->Array.forEach(id => bump(opponentCount, id))
      bump(matchGroupCount, match->Match.toStableId)

      if isLastRound {
        lastRoundMatches->Set.add(match->Match.toStableId)
      }

      // Sides at the time the match was played.
      let (side1, side2) = matchSides(match)
      switch side1 {
      | Even | NeverPlayed => () // an Even match leaves the demand unchanged
      | Favored | Unfavored =>
        team1->Array.forEach(p => lastSide->Map.set(p.id, side1))
        team2->Array.forEach(p => lastSide->Map.set(p.id, side2))
      }

      Match.players(match)->Array.forEach(p => playedThisRound->Set.add(p.id))
    })

    players->Array.forEach(p =>
      if !(playedThisRound->Set.has(p.id)) {
        lastByeRound->Map.set(p.id, roundIndex)
        if isLastRound {
          satOutLastRound->Set.add(p.id)
        }
      }
    )
  })

  let roundsSinceLastBye = Map.make()
  players->Array.forEach(p => {
    let sinceBye = switch lastByeRound->Map.get(p.id) {
    | None => roundCount // never sat out
    | Some(index) => roundCount - index - 1
    }
    roundsSinceLastBye->Map.set(p.id, sinceBye)
  })

  let n = players->Array.length
  let avgPlayedCount =
    n == 0 ? 0. : players->Array.reduce(0, (acc, p) => acc + p.count)->Int.toFloat /. n->Int.toFloat
  let maxPlayedCount = players->Array.reduce(0, (acc, p) => Js.Math.max_int(acc, p.count))

  let ratingPercentile = Map.make()
  let ranked = players->Array.toSorted((a, b) => a.rating.mu -. b.rating.mu)
  let rankDivisor = Js.Math.max_int(1, players->Array.length - 1)->Int.toFloat
  ranked->Array.forEachWithIndex((p, index) =>
    ratingPercentile->Map.set(p.id, index->Int.toFloat /. rankDivisor)
  )

  let poolMus = players->Array.map(p => p.rating.mu)
  let poolMuRange = switch poolMus {
  | [] => 0.
  | mus =>
    mus->Array.reduce(neg_infinity, (a, b) => Js.Math.max_float(a, b)) -.
      mus->Array.reduce(infinity, (a, b) => Js.Math.min_float(a, b))
  }

  {
    partnerCount,
    opponentCount,
    matchGroupCount,
    lastRoundTeams,
    lastRoundMatches,
    satOutLastRound,
    roundsSinceLastBye,
    lastSide,
    maxPlayedCount,
    avgPlayedCount,
    poolMuRange,
    ratingPercentile,
    roundCount,
  }
}

// ---------------------------------------------------------------------------
// Per-candidate cost
// ---------------------------------------------------------------------------

// Repeat pressure: the *first* repeat is already most of the harm a player
// notices, and further repeats escalate from there. A plain squared count would
// price the first repeat at a ninth of the maximum, which at variety weights is
// less than the alternation and spread terms put together — enough for the
// solver to trade away a fresh partnership for a marginally tidier match.
// Saturating at `repeatCap` is what keeps the component inside [0, 1].
let repeatFloor = 0.4
let repeatCap = 4.

let normalizedRepeat = (count: int): float =>
  if count <= 0 {
    0.
  } else {
    let escalation = clamp01((count - 1)->Int.toFloat /. (repeatCap -. 1.))
    repeatFloor +. (1. -. repeatFloor) *. escalation *. escalation
  }

// Team-sum mu gap at which a match is as lopsided as we ever score it. The
// balance term is linear in the gap, so this is really a slope: at the
// competitive preset it works out to ~8 objective points per mu of imbalance,
// which is enough to hold matches inside the dead zone whenever an even split
// exists.
let muGapScale = 60.

// The spread term is a **guardrail, not a driver**. Its whole job is to stop the
// strongest player being parked with the weakest; it must not express a general
// preference for skill-sorted courts, or "Mix players" would quietly become
// "band by rating" — at max variety it is the only active term, so any ranking
// it imposes decides the entire round.
//
// Two things keep it in its lane:
//
//   1. It is measured against the *pool's own* mu range rather than an absolute
//      number of mu. A foursome spanning half of a wide pool is ordinary mixing;
//      one spanning half of a tight pool is the same thing. An absolute scale
//      gets this wrong for every pool but the one it was tuned on.
//   2. It is a hinge: exactly zero until a foursome spans more than the current
//      `spreadTolerance` of the pool, then quartic up to the full range. Free
//      mixing below the line, steeply discouraged above it — and the line moves
//      with the slider.
//
// Why it has to bite at all: take mu = [40, 30, 30, 20, 30, 30, 30, 30] on two
// courts. Putting the 40 and the 20 together yields a perfectly balanced 60-60
// match plus a flawless 30/30/30/30 one, so balance alone actively *wants* that
// carry match. Only a steeply convex spread penalty makes concentrating the
// disparity more expensive than sharing it across two slightly uneven matches.

// Pools narrower than this are treated as this wide, so that in a tight field
// — where spread differences are not meaningful — the term stays inert instead
// of amplifying noise.
let minSpreadScale = 20.

let guardrail = (normalized: float): float => {
  let squared = normalized *. normalized
  squared *. squared
}

// Quad mu range -> [0, 1], relative to the pool and to how much spread the
// current settings tolerate.
// There IS an irreducible error floor, and it is large. Measured at 18 players
// over 80 rounds: mean sigma settles near 4.1 and is still falling, while
// adjacent players in the pack differ by 0.4 to 0.8 of true skill — the rating
// uncertainty is five to fifteen times the differences it is being asked to
// resolve, and mean ladder error plateaus around two places no matter how long
// a session runs. That floor belongs to the outcome noise, not to any
// matchmaker, and nothing here can go beneath it.
//
// It is tempting to conclude that banding on differences smaller than sigma is
// banding on noise, and to make the free allowance at least sqrt(2)*sigma so
// the term never asserts precision the ratings lack. That was built and
// measured (4 seeds, both field compositions, 25 rounds) and it is WRONG —
// every banded strategy got worse:
//
//   mean ladder error      no floor    with floor
//   Competitive+ mixed       2.50        3.47
//   Competitive+ tight       2.11        2.83
//   adaptive     mixed       2.75        3.42
//   adaptive     tight       2.44        2.97
//
// The error was treating "not statistically distinguishable at one standard
// deviation" as "carries no information". A weak signal still correlates with
// the truth, so banding on it still beats ignoring it; suppressing everything
// under sigma throws away real signal in exchange for a principle. The spread
// term is allowed to act on differences it cannot prove.

// Quad mu range -> [0, 1], relative to the pool and to how much spread the
// current settings tolerate.
let spreadPenalty = (~quadRange: float, ~poolRange: float, ~tolerance: float): float => {
  let scale = Js.Math.max_float(minSpreadScale, poolRange)
  let ratio = clamp01(quadRange /. scale)
  let tolerance = clamp(tolerance, 0., 0.99)
  guardrail(clamp01((ratio -. tolerance) /. (1. -. tolerance)))
}

type costParts = {
  partner: float,
  opponent: float,
  repeatLast: float,
  repeatGroup: float,
  balance: float,
  spread: float,
  alternate: float,
}

// Each field lands in [0, 1]. Kept separately from `candidateCost` so tests and
// the round-summary UI can inspect the breakdown.
let costParts = (~weights: costWeights, ~history: history, ~match: Match.t<'a>): costParts => {
  let (team1, team2) = match
  let teams = [team1, team2]
  let players = Match.players(match)

  let partnerRaw = teams->Array.reduce(0., (acc, team) =>
    acc +.
    array_combos(team)->Array.reduce(0., (a, (p1, p2)) =>
      a +. normalizedRepeat(history.partnerCount->Map.get(pairId(p1, p2))->Option.getOr(0))
    )
  )
  let partner = clamp01(partnerRaw /. 2.)

  let opponentPairs = noveltyOpponentPairIds(match)
  let opponentRaw =
    opponentPairs->Array.reduce(0., (acc, id) =>
      acc +. normalizedRepeat(history.opponentCount->Map.get(id)->Option.getOr(0))
    )
  let opponentDivisor = Js.Math.max_float(1., opponentPairs->Array.length->Int.toFloat)
  let opponent = clamp01(opponentRaw /. opponentDivisor)

  // Repeating a *team* from the previous round is the thing players notice;
  // repeating the whole foursome with different partners is milder.
  let repeatGroup = normalizedRepeat(
    history.matchGroupCount->Map.get(match->Match.toStableId)->Option.getOr(0),
  )

  let repeatLast = if teams->Array.some(t => history.lastRoundTeams->Set.has(t->Team.toStableId)) {
    1.
  } else if history.lastRoundMatches->Set.has(match->Match.toStableId) {
    0.5
  } else {
    0.
  }

  // Diagnostic only: balance is enforced as a candidate filter when
  // `balanceTeams` is on, never priced.
  let balance = clamp01(
    Js.Math.abs_float(teamMuSum(team1) -. teamMuSum(team2)) /. muGapScale,
  )

  let spread = switch players->Array.map(p => p.rating.mu) {
  | [] => 0.
  | mus =>
    let maxMu = mus->Array.reduce(neg_infinity, (a, b) => Js.Math.max_float(a, b))
    let minMu = mus->Array.reduce(infinity, (a, b) => Js.Math.min_float(a, b))
    spreadPenalty(
      ~quadRange=maxMu -. minMu,
      ~poolRange=history.poolMuRange,
      ~tolerance=weights.spreadTolerance,
    )
  }

  let (side1, side2) = matchSides(match)
  let mismatch = (p: Player.t<'a>, side: side) =>
    switch (history.lastSide->Map.get(p.id)->Option.getOr(NeverPlayed), side) {
    | (Favored, Favored) | (Unfavored, Unfavored) => 1.
    | _ => 0.
    }
  let mismatchCount =
    team1->Array.reduce(0., (acc, p) => acc +. mismatch(p, side1)) +.
    team2->Array.reduce(0., (acc, p) => acc +. mismatch(p, side2))
  let alternate = clamp01(
    mismatchCount /. Js.Math.max_float(1., players->Array.length->Int.toFloat),
  )

  {partner, opponent, repeatLast, repeatGroup, balance, spread, alternate}
}

// Weighted cost of one candidate. Always in [0, maxMatchCost(weights)].
let candidateCost = (
  ~weights: costWeights,
  ~history: history,
  ~match: Match.t<'a>,
  ~noise: float=0.,
): float => {
  let p = costParts(~weights, ~history, ~match)
  weights.wPartner *. p.partner +.
  weights.wOpponent *. p.opponent +.
  weights.wRepeatLast *. p.repeatLast +.
  weights.wRepeatGroup *. p.repeatGroup +.
  weights.wSpread *. p.spread +.
  weights.wAlternate *. p.alternate +.
  weights.wNoise *. clamp01(noise)
}

// ---------------------------------------------------------------------------
// Per-player benefit (bye fairness)
// ---------------------------------------------------------------------------

// A player three games behind the busiest player is maximally owed a game.
// One game behind is therefore worth 4000/3 = 1333, which outranks the whole
// `wByeStreak` range — games-played fairness first, streak only as a tiebreak.
let byeDeficitScale = 3.
// Six rounds without a break is as strong a claim to a bye as we ever make.
let byeStreakScale = 6.

// Always in [0, maxPlayerBenefit]. Note this only steers *which* players sit:
// when the court constraint binds, exactly 4 * courts players play regardless.
let playerBenefit = (
  ~weights: costWeights,
  ~history: history,
  ~player: Player.t<'a>,
  ~isPriority: bool,
): float => {
  let deficit = Js.Math.max_float(0., (history.maxPlayedCount - player.count)->Int.toFloat)
  let streak = history.roundsSinceLastBye->Map.get(player.id)->Option.getOr(0)->Int.toFloat
  let percentile = history.ratingPercentile->Map.get(player.id)->Option.getOr(0.5)
  wByeDeficit *. clamp01(deficit /. byeDeficitScale) +.
  wByeStreak *. clamp01(streak /. byeStreakScale) +.
  wPriority *. (isPriority ? 1. : 0.) +.
  clamp(weights.wCohort, 0., maxCohortWeight) *. percentile
}

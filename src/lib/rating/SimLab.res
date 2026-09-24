// Matchmaking convergence lab — simulation engine.
//
// Drives the REAL solver (`SolverRounds.generateRounds`) and the REAL rating
// pipeline (`Rating.toPlayerStateWithAdjustments`) against a hidden ground
// truth, so the visualisation shows what the app would actually do rather than
// a model of it. The scenarios mirror the committed convergence suite
// (tests/solver/Convergence.test.ts) so the numbers on screen and the numbers
// the tests assert are the same measurements.
//
// Everything is deterministic per seed: the solver draws from `SolverPrng`, and
// match outcomes draw from a second seeded stream here.

open Rating

// ---------------------------------------------------------------------------
// Scenarios — the committed test cases, made visual
// ---------------------------------------------------------------------------

type scenario =
  | ColdStart
  | AccuratePrior
  | Inverted
  | InvertedInserts
  | WithinBandInverted
  | NewcomerInjection

let scenarios = [
  ColdStart,
  AccuratePrior,
  Inverted,
  InvertedInserts,
  WithinBandInverted,
  NewcomerInjection,
]

let scenarioId = (s: scenario) =>
  switch s {
  | ColdStart => "cold"
  | AccuratePrior => "accurate"
  | Inverted => "inverted"
  | InvertedInserts => "inverted-inserts"
  | WithinBandInverted => "in-band"
  | NewcomerInjection => "newcomers"
  }

// How a lab row produces its rounds.
type roundEngine =
  | SolverEngine
  // Human open-play cultures, simulated. Not modes the app offers — they are
  // here to show what the solver is being compared against in the real world.
  | JapanOpenPlay
  | AmericanOpenPlay
  // King of the court: ranked courts, winners move up and split, losers slide
  // down, the bottom court's losers rotate out to the queue.
  | KingCourtPlay

// Identity and behaviour only — the display name and description live in the
// UI layer (`MatchmakingLab`), where they can be wrapped in translation
// macros. Keeping them out of here also keeps this module importable by tests
// without pulling in i18n.
type labStrategy = {
  id: string,
  short: string,
  color: string,
  strategy: strategy,
  // None = use the preset's own profile.
  weightConfig: option<CostModel.uiWeightConfig>,
  // Controls are reference points, not modes anyone can pick in the app.
  isBaseline: bool,
  // Synthetic: OPTIMISE over hidden true skill instead of the visible ratings.
  // Impossible in reality, so rows with this set are bounds rather than
  // competitors and are excluded from ranking. Note this is not the same as
  // the open-play styles knowing who the beginners are — players genuinely do
  // know that about themselves, so a coarse self-sort is achievable and those
  // rows still compete.
  usesTruth: bool,
  // Which engine builds the round. The open-play styles are not expressible as
  // solver weights — they carry state between rounds and apply conditional
  // rules per foursome — so they get their own builder below.
  engine: roundEngine,
}

// The two baselines bracket what matchmaking can do. Both switch team balancing
// OFF and run through `SolverRandomBalanced`'s dispatch, which only decides
// court ordering — the weights below are what actually drive them.
let randomAdvanced: CostModel.advancedWeights = {
  partnerVariety: 0.,
  opponentVariety: 0.,
  avoidRecentRepeats: 0.,
  bandStrength: 0., // only the carry-match guardrail survives (it has a floor)
  bandTolerance: 1.,
  balanceTeams: false,
  splitBalanceFirst: false,
  alternateFavored: 0.,
  shakeUp: 1., // noise at maximum: it must dominate every residual term
  cohortRotation: 0.,
}

// Same, but with the novelty core switched back on: random composition that
// still refuses to repeat partners and opponents. This isolates novelty from
// balancing — the difference between the two baselines is what rotation alone
// buys you.
let randomNoveltyAdvanced: CostModel.advancedWeights = {
  ...randomAdvanced,
  partnerVariety: 1.,
  opponentVariety: 0.85,
  avoidRecentRepeats: 0.85,
  shakeUp: 0.05, // enough to break ties, not enough to outrank a repeat
}

let strategies: array<labStrategy> = [
  {
    id: "cpa",
    short: "C+A",
    color: "#1F5FA8",
    strategy: SolverCompetitivePlus,
    weightConfig: None,
    isBaseline: false,
    usesTruth: false,
    engine: SolverEngine,
  },
  {
    id: "rr",
    short: "RR",
    color: "#7A3DB8",
    strategy: SolverRoundRobin,
    weightConfig: None,
    isBaseline: false,
    usesTruth: false,
    engine: SolverEngine,
  },
  {
    id: "rb",
    short: "RB",
    color: "#0E8F6E",
    strategy: SolverRandomBalanced,
    weightConfig: None,
    isBaseline: false,
    usesTruth: false,
    engine: SolverEngine,
  },
  {
    // No longer selectable in the app — kept here (and in the convergence
    // suite) as the unblended reference the adaptive version is measured
    // against. Without it there is nothing to show what calibrating buys.
    id: "cp",
    short: "C+S",
    color: "#C4123F",
    strategy: SolverCompetitivePlusStatic,
    weightConfig: None,
    isBaseline: true,
    usesTruth: false,
    engine: SolverEngine,
  },
  {
    id: "rnd",
    short: "RND",
    color: "#93998F",
    strategy: SolverRandomBalanced,
    weightConfig: Some({qualityVsVariety: 0., advanced: Some(randomAdvanced)}),
    isBaseline: true,
    usesTruth: false,
    engine: SolverEngine,
  },
  {
    id: "rndnov",
    short: "RNV",
    color: "#B07A2A",
    strategy: SolverRandomBalanced,
    weightConfig: Some({qualityVsVariety: 0., advanced: Some(randomNoveltyAdvanced)}),
    isBaseline: true,
    usesTruth: false,
    engine: SolverEngine,
  },
  {
    // The ceiling. Bands on hidden truth, so its match quality is the best any
    // matchmaker could achieve for this pool — the gap between it and a real
    // strategy is the part attributable to not knowing the ratings, as opposed
    // to the pool simply not containing an even game.
    //
    // Its ladder error is NOT meaningful: it never consults the ratings it is
    // being scored on, so it learns nothing on purpose.
    id: "oracle",
    short: "ORC",
    color: "#0B7285",
    strategy: SolverCompetitivePlusStatic,
    weightConfig: None,
    isBaseline: true,
    usesTruth: true,
    engine: SolverEngine,
  },
  {
    id: "jp",
    short: "JP",
    color: "#8A6D1F",
    strategy: SolverRandomBalanced,
    weightConfig: None,
    isBaseline: true,
    usesTruth: false,
    engine: JapanOpenPlay,
  },
  {
    id: "us",
    short: "US",
    color: "#A03E7A",
    strategy: SolverRandomBalanced,
    weightConfig: None,
    isBaseline: true,
    usesTruth: false,
    engine: AmericanOpenPlay,
  },
  {
    id: "koc",
    short: "KOC",
    color: "#5B7F3C",
    strategy: SolverRandomBalanced,
    weightConfig: None,
    isBaseline: true,
    usesTruth: false,
    engine: KingCourtPlay,
  },
]

// ---------------------------------------------------------------------------
// Ground truth and starting ratings
// ---------------------------------------------------------------------------

// The shape of the field, as two dials.
//
//   curve   0 = an even ladder, every adjacent pair equally far apart.
//           1 = a tight pack: most players nearly indistinguishable, with the
//           differences pushed out to the edges.
//
// The two extremes are NOT optional. A ringer and a beginner the pool cannot
// absorb are a permanent fact of club play, and hiding them would flatter every
// strategy — an even field always affords a tidy banding and never a genuinely
// awkward player to place. Instead of removing them, every quality figure is
// reported twice: once over the whole field and once over the tight pack alone
// (see `qualityTight`), so their unavoidable cost can be separated from how
// well a strategy handles the players it CAN place.
type distribution = {
  curve: float,
  outliers: bool,
  // Where the pack sits and how far it reaches, in mu. Parameterised so a
  // field can be specified in DUPR terms rather than by hand-tuned constants.
  center: float,
  halfSpread: float,
}

// A field described the way a club would describe itself: "we run about 3.0 to
// 4.0". `Rating.duprToMu` is the app's own conversion, so these spreads mean
// the same thing here as they do on a player's profile.
let fieldFromDupr = (~low: float, ~high: float, ~curve: float, ~outliers: bool) => {
  let loMu = duprToMu(low)
  let hiMu = duprToMu(high)
  {curve, outliers, center: (loMu +. hiMu) /. 2.0, halfSpread: (hiMu -. loMu) /. 2.0}
}

// The three fields the lab always reports, so nothing about the population is a
// setting. Which strategy wins depends on the room.
//
//   varied   a wide field plus the two players it cannot absorb — a ringer far
//            above everyone and a beginner far below. The open club night.
//   typical  about a 1.0 DUPR spread (roughly 3.0 to 4.0), moderately bunched,
//            nobody outside the group. What most clubs actually look like.
//   tight    a narrow, heavily bunched pack. The level session, where players
//            were sorted before they arrived and are hard to tell apart.
let variedField = {curve: 0.0, outliers: true, center: 28.0, halfSpread: 10.0}
let typicalField = fieldFromDupr(~low=3.0, ~high=4.0, ~curve=0.5, ~outliers=false)
let tightField = {curve: 0.85, outliers: false, center: 28.0, halfSpread: 10.0}

let fields = [variedField, typicalField, tightField]

// ---------------------------------------------------------------------------
// Tournament mode
// ---------------------------------------------------------------------------
//
// A tournament session, where you arrive with a small squad rather than mixing
// with the whole room: players are grouped into pods of four, so each player
// has exactly three possible partners all session. Opponents are unrestricted —
// any pod can face any other — so rotation continues, but partnership variety
// is capped at three by construction.
//
// This is a real constraint the app already models: the solver's partner pools
// (`teamConstraints`) express exactly this, so tournament mode passes the pods
// straight through rather than needing a separate engine.
let podSize = 4

let partnerPods = (~players: array<Player.t<'a>>, ~seed: int): array<Set.t<string>> => {
  let prng = SolverPrng.fromSeedString("lab-pods:" ++ Int.toString(seed))
  let shuffled = players->Array.copy
  for i in shuffled->Array.length - 1 downto 1 {
    let j = Js.Math.floor_int(SolverPrng.nextFloat(prng) *. Float.fromInt(i + 1))
    let tmp = shuffled->Array.getUnsafe(i)
    shuffled->Array.setUnsafe(i, shuffled->Array.getUnsafe(j))
    shuffled->Array.setUnsafe(j, tmp)
  }
  let n = shuffled->Array.length
  let podCount = Js.Math.max_int(1, n / podSize)
  // Deal round-robin rather than in blocks, so a remainder adds ONE player to
  // each of the first few squads instead of stacking them all onto the last.
  // With 18 players that is squads of 5,5,4,4 — four partners at worst —
  // rather than 4,4,4,6, where six people would have five.
  let pods = Belt.Array.makeBy(podCount, _ => Set.make())
  shuffled->Array.forEachWithIndex((p, i) =>
    switch pods->Array.get(mod(i, podCount)) {
    | Some(pod) => pod->Set.add(p.id)
    | None => ()
    }
  )
  pods
}

// ---------------------------------------------------------------------------
// Skill drift
// ---------------------------------------------------------------------------
//
// Real players do not hold still. Most stay roughly where they are, a fifth
// improve gradually, one in twenty improves sharply, and one in twenty slips.
// A rating system that only ever converges on a frozen truth is being graded on
// the easy case; this is what separates a model that keeps up from one that
// merely settles.
//
// Roles are drawn once per run from the seed and shared by EVERY strategy in
// that run, so the comparison is between matchmakers rather than between
// different luck about who improved.
type drift =
  | Steady
  | Slipping
  | Improving
  | ImprovingFast

// How far a player's true skill can move, as a DUPR change — the unit clubs
// actually think in. The fast improver tops out at half a DUPR point; the
// gradual movers at 0.15. (Drift was once linear and unbounded — +0.3 mu per
// round forever — which meant the fast improver gained more than a full DUPR
// by round 100 and a "tight" room quietly stopped being tight mid-run, so the
// long-horizon results partly measured drift response rather than the room
// they claimed to.)
let driftTargetDupr = (d: drift) =>
  switch d {
  | Steady => 0.0
  | Slipping => -0.15
  | Improving => 0.15
  | ImprovingFast => 0.5
  }

// Improvement follows a saturating curve, not a straight line: gains come
// fastest early and taper off, approaching the cap and never passing it. With
// tau = 40, a player has made about 63% of their total move by round 40 and
// 92% by round 100.
let driftTau = 40.0

// The app's own DUPR<->mu conversion, so a "0.5 DUPR" drift here means the
// same thing it does on a player's profile.
let muPerDupr = duprToMu(4.0) -. duprToMu(3.0)

let driftAt = (d: drift, ~round: int) =>
  driftTargetDupr(d) *.
  muPerDupr *.
  (1.0 -. Js.Math.exp(-.Float.fromInt(round) /. driftTau))

let slippingShare = 0.05
let improvingShare = 0.20
let fastShare = 0.05

// Who drifts, fixed for the whole run. Assigned over ladder positions rather
// than player slots so "the improver" is a specific player, wherever they sit.
let driftRoles = (~numPlayers: int, ~seed: int): array<drift> => {
  let roles = Belt.Array.make(numPlayers, Steady)
  if numPlayers < 4 {
    roles
  } else {
    let prng = SolverPrng.fromSeedString("lab-drift:" ++ Int.toString(seed))
    let order = Belt.Array.makeBy(numPlayers, i => i)
    // Fisher-Yates, so which players drift is seeded but arbitrary.
    for i in numPlayers - 1 downto 1 {
      let j = Js.Math.floor_int(SolverPrng.nextFloat(prng) *. Float.fromInt(i + 1))
      let tmp = order->Array.getUnsafe(i)
      order->Array.setUnsafe(i, order->Array.getUnsafe(j))
      order->Array.setUnsafe(j, tmp)
    }
    let atLeastOne = share =>
      Js.Math.max_int(1, Js.Math.round(Float.fromInt(numPlayers) *. share)->Float.toInt)
    let nSlip = atLeastOne(slippingShare)
    let nFast = atLeastOne(fastShare)
    let nUp = Js.Math.round(Float.fromInt(numPlayers) *. improvingShare)->Float.toInt
    let assign = (from, count, role) =>
      for k in from to Js.Math.min_int(numPlayers, from + count) - 1 {
        roles->Array.setUnsafe(order->Array.getUnsafe(k), role)
      }
    assign(0, nSlip, Slipping)
    assign(nSlip, nFast, ImprovingFast)
    assign(nSlip + nFast, nUp, Improving)
    roles
  }
}

// ---------------------------------------------------------------------------
// Ground truth
// ---------------------------------------------------------------------------

// The pack, before any outliers are pulled out of it. Blending the cubic with
// a linear term is deliberate even at curve = 1: a pure cube puts the middle
// third inside half a rating point, which no rating system could separate, so
// the ladder would be unrankable by construction and "places off" would stop
// measuring the matchmaker at all.
let packSkill = (~index: int, ~numPlayers: int, ~dist: distribution) => {
  let n = Float.fromInt(numPlayers)
  let u = (Float.fromInt(index) +. 0.5) /. n
  let z = 2.0 *. u -. 1.0
  let c = CostModel.clamp01(dist.curve)
  dist.center +. dist.halfSpread *. ((1.0 -. c) *. z +. c *. z *. z *. z)
}

// The extremes the two outliers are pulled toward, when a field has them.
// Partnered with an average player the ringer's side wins about 95% of the time
// and the beginner's about 8%, so no split can even those games out.
let ringerSkill = 52.0
let beginnerSkill = 8.0

// True skill at the START of a session, before any drift.
let trueSkill = (~index: int, ~numPlayers: int, ~dist: distribution) =>
  if numPlayers < 4 {
    15.0 +. Float.fromInt(index) *. 2.0
  } else if dist.outliers && index <= 0 {
    beginnerSkill
  } else if dist.outliers && index >= numPlayers - 1 {
    ringerSkill
  } else {
    packSkill(~index, ~numPlayers, ~dist)
  }

let names = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"->String.split("")

let playerName = (i: int) =>
  switch names->Array.get(mod(i, 26)) {
  | Some(c) => i >= 26 ? c ++ Int.toString(i / 26) : c
  | None => Int.toString(i)
  }

// Player slots carry no skill information: the hidden ladder is dealt out in a
// seeded permutation, so `index` (which player) and `rank` (how good) are
// independent. Without this, any deterministic tie-break in the solver pairs
// adjacent slots — which were adjacent in TRUE skill — and the zero-jitter
// modes get accidentally well-matched opening rounds that no real roster would
// give them.
let ladderPermutation = (~seed: int, ~numPlayers: int): array<int> => {
  let prng = SolverPrng.fromSeedString("lab-ladder:" ++ Int.toString(seed))
  let out = Belt.Array.makeBy(numPlayers, i => i)
  for i in numPlayers - 1 downto 1 {
    let j = Js.Math.floor_int(SolverPrng.nextFloat(prng) *. Float.fromInt(i + 1))
    let tmp = out->Array.getUnsafe(i)
    out->Array.setUnsafe(i, out->Array.getUnsafe(j))
    out->Array.setUnsafe(j, tmp)
  }
  out
}

// Which players carry the scenario's "flag" (newcomer / reversed band member).
let isFlagged = (~scenario: scenario, ~index: int, ~numPlayers: int) =>
  switch scenario {
  | NewcomerInjection
  | InvertedInserts =>
    mod(index, 3) == 1 && index < numPlayers
  | WithinBandInverted => true
  | _ => false
  }

// Starting visible rating for each scenario. `settledSigma` marks a rating the
// system already holds confidently, which is what makes the Inverted case a
// trap rather than a transient.
let settledSigma = 7.0

let startingRating = (
  ~scenario: scenario,
  ~index: int,
  ~rank: int,
  ~numPlayers: int,
  ~dist: distribution,
): Rating.t => {
  let theta = trueSkill(~index=rank, ~numPlayers, ~dist)
  let defaultRating = Rating.makeDefault()
  switch scenario {
  | ColdStart => defaultRating
  | AccuratePrior => Rating.make(theta, settledSigma)
  | Inverted =>
    // Exact mirror around the ladder's midpoint.
    let mid =
      (trueSkill(~index=0, ~numPlayers, ~dist) +.
        trueSkill(~index=numPlayers - 1, ~numPlayers, ~dist)) /. 2.0
    Rating.make(mid -. (theta -. mid), settledSigma)
  | WithinBandInverted =>
    // Global order right, each band of four internally reversed. Bands are
    // defined over the true LADDER, not over player slots.
    let band = rank / 4
    let within = mod(rank, 4)
    Rating.make(trueSkill(~index=band * 4 + (3 - within), ~numPlayers, ~dist), settledSigma)
  | NewcomerInjection =>
    isFlagged(~scenario, ~index, ~numPlayers)
      ? defaultRating // unrated: mid-pool mu, wide sigma
      : Rating.make(theta, settledSigma)
  | InvertedInserts =>
    // Confidently mirrored, but surrounded by correct anchors.
    let mid =
      (trueSkill(~index=0, ~numPlayers, ~dist) +.
        trueSkill(~index=numPlayers - 1, ~numPlayers, ~dist)) /. 2.0
    isFlagged(~scenario, ~index, ~numPlayers)
      ? Rating.make(mid -. (theta -. mid), settledSigma)
      : Rating.make(theta, settledSigma)
  }
}

let buildPlayers = (
  ~scenario: scenario,
  ~numPlayers: int,
  ~ranks: array<int>,
  ~dist: distribution,
): array<Player.t<unit>> =>
  Belt.Array.makeBy(numPlayers, index => {
    let rating = startingRating(
      ~scenario,
      ~index,
      ~rank=ranks->Array.getUnsafe(index),
      ~numPlayers,
      ~dist,
    )
    let player: Player.t<unit> = {
      data: None,
      id: "p" ++ Int.toString(index),
      intId: index,
      name: playerName(index),
      rating,
      ratingOrdinal: rating->Rating.ordinal,
      paid: false,
      gender: Gender.Male,
      count: 0,
    }
    player
  })

// ---------------------------------------------------------------------------
// Outcome model
// ---------------------------------------------------------------------------

// The world speaks the app's own language: win and draw probabilities come
// from openskill (`Rating.predictWin` / `Rating.predictDraw`), with hidden
// true skill as mu and NO uncertainty term.
//
// The lab grades MATCHMAKING STRATEGIES, not the rating model. Every strategy
// runs the same rater, so a world that disagreed with the rater's model would
// only add an error floor common to all of them — compressing exactly the
// differences the lab exists to show — while the strategies' ordering is
// decided by which matches they choose, not by which link function scores
// them. It also puts the whole sim in one lens: outcomes were once drawn from
// an ad-hoc logistic (team-sum gap / 8, inherited from
// tests/solver/sessionSim.ts, which still uses it internally) while quality
// was judged by `predictDraw` — two world models at once, and a homebrew
// predictor scale-matched to the ad-hoc one just to keep forecast error
// meaningful. With the world and the rater sharing a model, a perfect rating
// system forecasts every game exactly, so forecast error's zero is honest.
//
// If we ever want to test robustness to model error, the instrument is a link
// function FITTED from real recorded scores, not an arbitrary constant.
let maxScore = 11.0

// The truth-based metrics — `truthRatings`, `clampProb`, `trueWinProbability`,
// `drawSigma` and `drawProbability` — live in `Rating` now (opened above),
// next to the event quality score that shares them, and their history moved
// with them. Re-bound here so the lab's tests and callers keep their entry
// points.
let truthRatings = truthRatings
let clampProb = clampProb
let trueWinProbability = trueWinProbability
let drawSigma = drawSigma
let drawProbability = drawProbability
let evenGameDraw = evenGameDraw
let evenness = evenness

// What the RATINGS expected, through the same model the app uses everywhere:
// openskill's own predictWin over the ratings embedded at match time. This is
// literally the number the app could show players, and because the world is
// drawn from the same model, forecast error above zero is attributable to
// wrong rating VALUES, not to two formulas disagreeing about what a skill gap
// means.
let predictedWinProbability = (match: Match.t<'a>) => {
  let (team1, team2) = match
  Rating.predictWin([team1->Array.map(p => p.rating), team2->Array.map(p => p.rating)])
  ->Array.get(0)
  ->Option.getOr(0.5)
  ->clampProb
}

// Scores come from simulating the game rally by rally: each point is a
// Bernoulli trial with a per-rally probability solved so that the GAME-level
// win chance equals the world's `trueWinProbability` exactly. Winners, and
// therefore ratings, convergence and every ladder metric, are untouched by
// this choice — only the margins change, and they now have the spread real
// rally scoring produces.
//
// The model itself lives in `Rating.ScoreModel`, because it runs in both
// directions: the lab uses it forward to simulate scores, and the app can use
// it in reverse to read them (`ScoreModel.rateWithScore`, the score-aware
// rating update). These aliases keep the lab's public surface stable.
let maxScore = ScoreModel.maxScore
let gameWinProb = ScoreModel.gameWinProb
let rallyProbFor = ScoreModel.rallyProbFor

let simulateScore = (match: Match.t<'a>, ~truth: array<float>, ~prng: SolverPrng.t) => {
  let q = rallyProbFor(trueWinProbability(match, ~truth))
  let s1 = ref(0.0)
  let s2 = ref(0.0)
  while s1.contents < maxScore && s2.contents < maxScore {
    if SolverPrng.nextFloat(prng) < q {
      s1 := s1.contents +. 1.0
    } else {
      s2 := s2.contents +. 1.0
    }
  }
  (s1.contents, s2.contents)
}

// ---------------------------------------------------------------------------
// Metrics — the same ones the convergence suite asserts on
// ---------------------------------------------------------------------------

let ranksOf = (values: array<float>): array<int> => {
  let n = values->Array.length
  let indexed = Belt.Array.makeBy(n, i => (i, values->Array.getUnsafe(i)))
  let sorted = indexed->Array.toSorted(((_, a), (_, b)) => a -. b)
  let out = Belt.Array.make(n, 0)
  sorted->Array.forEachWithIndex(((originalIndex, _), rank) => out->Array.setUnsafe(originalIndex, rank))
  out
}

let spearman = (~visible: array<float>, ~truth: array<float>) => {
  let n = visible->Array.length
  if n < 2 {
    1.0
  } else {
    let rv = ranksOf(visible)
    let rt = ranksOf(truth)
    let d2 = Belt.Array.makeBy(n, i => {
      let d = Float.fromInt(rv->Array.getUnsafe(i) - rt->Array.getUnsafe(i))
      d *. d
    })->Array.reduce(0., (a, b) => a +. b)
    let nf = Float.fromInt(n)
    1.0 -. 6.0 *. d2 /. (nf *. (nf *. nf -. 1.0))
  }
}

// Mean |visible rank - true rank|, in ladder positions: the interpretable one.
let rankError = (~visible: array<float>, ~truth: array<float>) => {
  let n = visible->Array.length
  if n == 0 {
    0.0
  } else {
    let rv = ranksOf(visible)
    let rt = ranksOf(truth)
    Belt.Array.makeBy(n, i =>
      Js.Math.abs_float(Float.fromInt(rv->Array.getUnsafe(i) - rt->Array.getUnsafe(i)))
    )->Array.reduce(0., (a, b) => a +. b) /. Float.fromInt(n)
  }
}

let standardise = (values: array<float>) => {
  let n = values->Array.length
  if n == 0 {
    []
  } else {
    let nf = Float.fromInt(n)
    let mean = values->Array.reduce(0., (a, b) => a +. b) /. nf
    let variance =
      values->Array.reduce(0., (acc, v) => acc +. (v -. mean) *. (v -. mean)) /. nf
    let sd = Js.Math.sqrt(variance)
    sd < 1e-9 ? values->Array.map(_ => 0.0) : values->Array.map(v => (v -. mean) /. sd)
  }
}

// RMSE of visible vs true rating, both standardised so the arbitrary scale and
// offset of each cancel.
let muError = (~visible: array<float>, ~truth: array<float>) => {
  let zv = standardise(visible)
  let zt = standardise(truth)
  let n = zv->Array.length
  if n == 0 {
    0.0
  } else {
    Js.Math.sqrt(
      Belt.Array.makeBy(n, i => {
        let d = zv->Array.getUnsafe(i) -. zt->Array.getUnsafe(i)
        d *. d
      })->Array.reduce(0., (a, b) => a +. b) /. Float.fromInt(n),
    )
  }
}

// ---------------------------------------------------------------------------
// Open play (simulation only)
// ---------------------------------------------------------------------------
//
// These reproduce how club sessions actually run when nobody is optimising:
// people form fours at the net and split teams by eye. They are not solver
// configurations — both carry state between rounds or branch per foursome —
// so they are built here directly. Their value is as the honest comparison:
// the solver presets should be measured against what clubs really do, not only
// against each other.

@module("../uuid") external randomUUID: unit => string = "randomUUID"

let shuffle = (arr: array<'a>, ~prng: SolverPrng.t): array<'a> => {
  let out = arr->Array.copy
  for i in out->Array.length - 1 downto 1 {
    let j = Js.Math.floor_int(SolverPrng.nextFloat(prng) *. Float.fromInt(i + 1))
    let tmp = out->Array.getUnsafe(i)
    out->Array.setUnsafe(i, out->Array.getUnsafe(j))
    out->Array.setUnsafe(j, tmp)
  }
  out
}

// How much these two have already seen of each other. Partnering counts double:
// "we keep getting put together" is more noticeable than facing someone twice.
let contact = (~history: CostModel.history, a: Player.t<'a>, b: Player.t<'a>) => {
  let id = CostModel.pairId(a, b)
  2 * history.partnerCount->Map.get(id)->Option.getOr(0) +
    history.opponentCount->Map.get(id)->Option.getOr(0)
}

// Fours form around whoever is next up. With novelty on, the other three are
// the people that player has seen least — which is what a rotation board
// approximates. Without it, whoever happens to be standing there.
let formFoursomes = (
  ~seated: array<Player.t<'a>>,
  ~history: CostModel.history,
  ~preferNovelty: bool,
  ~prng: SolverPrng.t,
): array<array<Player.t<'a>>> => {
  let pool = ref(shuffle(seated, ~prng))
  let out = []
  while pool.contents->Array.length >= 4 {
    let anchor = pool.contents->Array.getUnsafe(0)
    let rest = pool.contents->Array.sliceToEnd(~start=1)
    let ordered = preferNovelty
      ? rest->Array.toSorted((x, y) =>
          Float.fromInt(contact(~history, anchor, x) - contact(~history, anchor, y))
        )
      : rest
    let quad = Array.concat([anchor], ordered->Array.slice(~start=0, ~end=3))
    let chosen = quad->Array.map(p => p.id)->Set.fromArray
    out->Array.push(quad)
    pool := pool.contents->Array.filter(p => !(chosen->Set.has(p.id)))
  }
  out
}

let splitRandom = (quad: array<Player.t<'a>>, ~prng): Match.t<'a> => {
  let sh = shuffle(quad, ~prng)
  ([sh->Array.getUnsafe(0), sh->Array.getUnsafe(1)], [sh->Array.getUnsafe(2), sh->Array.getUnsafe(3)])
}

// Japan style: nobody evens the teams up unless the four obviously divide into
// two strong and two weak — that is the only case anyone bothers. When they do,
// each strong player takes a weak one, but WHICH weak one is not considered.
//
// "Obviously" is an absolute half-DUPR gap between the pair averages, not a
// fraction of the room. The organiser's eye judges skill differences on the
// scale it always uses, so in a tight room nothing ever looks obviously
// unbalanced and JP-style correctly degenerates to pure random there. This
// was once `max(6, 0.35 * pool range)` — about a 0.35-DUPR pair gap in a
// typical room — which fired on a large share of ordinary foursomes and made
// the style a bulk intervention; the median game quality exposed it, moving
// +21 points against random when the style's whole premise is that it only
// prevents the worst matches.
let bigDivideThreshold = 0.5 *. muPerDupr

// Keyed on TRUE skill, like the American self-sort below and for the same
// reason: the organiser eyeballing a lopsided foursome is reacting to what is
// visibly happening in the room, which exists whether or not any rating
// system does. This used to read the visible ratings instead, which broke the
// baseline both ways — at a cold start every mu is identical, so the split
// NEVER fired exactly when the style is supposed to earn its edge over
// random, and as ratings converged the "rating-free" baseline quietly
// borrowed the knowledge of the very system it is a control for.
let splitJapan = (quad: array<Player.t<'a>>, ~truth: array<float>, ~prng): Match.t<'a> => {
  let sorted =
    quad->Array.toSorted((a, b) =>
      truth->Array.getUnsafe(b.intId) -. truth->Array.getUnsafe(a.intId)
    )
  let skill = i => truth->Array.getUnsafe((sorted->Array.getUnsafe(i)).intId)
  let strongPair = (skill(0) +. skill(1)) /. 2.0
  let weakPair = (skill(2) +. skill(3)) /. 2.0
  if strongPair -. weakPair > bigDivideThreshold {
    let s0 = sorted->Array.getUnsafe(0)
    let s1 = sorted->Array.getUnsafe(1)
    let w0 = sorted->Array.getUnsafe(2)
    let w1 = sorted->Array.getUnsafe(3)
    // The weaker two are shared out at random, not matched by strength.
    SolverPrng.nextFloat(prng) < 0.5 ? ([s0, w0], [s1, w1]) : ([s0, w1], [s1, w0])
  } else {
    splitRandom(quad, ~prng)
  }
}

// American open play self-segregates. Players sort themselves into "beginner"
// and "intermediate/advanced" and largely stay put: a beginner does not wander
// onto the advanced courts and the advanced players do not come down. Only the
// people around the middle of the pool are ambiguous enough to appear on
// either side.
//
// This is keyed on true skill rather than the app's ratings on purpose — the
// sort happens in the room, by people who know roughly what they are, and it
// happens whether or not any rating system exists. It is a coarse two-way
// split, not an optimisation, which is why this row still competes.
let crossoverLow = 0.35
let crossoverHigh = 0.65

let selfSortedBands = (
  ~seated: array<Player.t<'a>>,
  ~truth: array<float>,
  ~prng: SolverPrng.t,
): (array<Player.t<'a>>, array<Player.t<'a>>) => {
  let sorted =
    seated->Array.toSorted((a, b) =>
      truth->Array.getUnsafe(a.intId) -. truth->Array.getUnsafe(b.intId)
    )
  let n = Float.fromInt(sorted->Array.length)
  let lower = []
  let upper = []
  sorted->Array.forEachWithIndex((p, i) => {
    let position = Float.fromInt(i) /. Js.Math.max_float(1.0, n -. 1.0)
    if position < crossoverLow {
      lower->Array.push(p) // never goes up
    } else if position > crossoverHigh {
      upper->Array.push(p) // never comes down
    } else {
      // Around the median, either court is plausible.
      (SolverPrng.nextFloat(prng) < 0.5 ? lower : upper)->Array.push(p)
    }
  })
  (lower, upper)
}

// American style: a hammering demands a rematch, and a good close game keeps
// the same four on court. Both hold the group together, which is why rotation
// suffers even though nobody intends it.
let blowoutMargin = 9.0
let tightMargin = 2.0

// A match, ignoring court and team order, so a rematch can be recognised.
let rematchKey = (m: Match.t<'a>): string => {
  let (t1, t2) = m
  let side = (team: Team.t<'a>) =>
    team
    ->Array.map(p => p.id)
    ->Array.toSorted((a, b) => a < b ? -1.0 : a > b ? 1.0 : 0.0)
    ->Array.join("+")
  let a = side(t1)
  let b = side(t2)
  a < b ? a ++ " vs " ++ b : b ++ " vs " ++ a
}

// The revenge is a coin flip, and it happens at most ONCE. Not every hammered
// team demands a rerun — half do — and the ones that get it disband afterwards
// whatever the score. A first version carried EVERY blowout with no memory,
// and a genuinely mismatched foursome blows out every time it plays — so it
// carried forever. Measured over a 30-round session, 84 of 120 US games were
// repeats, with chains 23, 29 and 30 rounds long: three of four courts frozen
// on the same drubbing all session, logging a fresh blowout every round and
// starving the ratings of anything new. Only a match that has NOT already
// just been run back may carry. The tight-game stay is the same coin flip —
// 50% per round decays a clump geometrically on its own.
let revengeChance = 0.5

let americanCarryOvers = (
  ~previous: array<completedMatchEntity<'a>>,
  ~beforePrevious: array<completedMatchEntity<'a>>,
  ~maxCarried: int,
  ~prng: SolverPrng.t,
): array<Match.t<'a>> => {
  let alreadyRanBack =
    beforePrevious->Array.map(e => rematchKey(e.match))->Set.fromArray
  previous
  ->Array.filterMap(entity =>
    switch entity.score {
    | Some((a, b)) =>
      let margin = Js.Math.abs_float(a -. b)
      if margin >= blowoutMargin {
        if alreadyRanBack->Set.has(rematchKey(entity.match)) {
          None // this WAS the revenge; the group has had it
        } else if SolverPrng.nextFloat(prng) < revengeChance {
          Some(entity.match) // run it back
        } else {
          None // shrug it off and rotate
        }
      } else if margin <= tightMargin && SolverPrng.nextFloat(prng) < 0.5 {
        Some(entity.match) // that was a good one, stay on
      } else {
        None
      }
    | None => None
    }
  )
  // Always leave at least one court rotating, or a session can seize up
  // entirely and the play-count comparison stops meaning anything.
  ->Array.slice(~start=0, ~end=Js.Math.max_int(0, maxCarried))
}

// King of the court. Courts are ranked, top first, and the round is built
// entirely from the previous one:
//   - a court's winners move UP one court (the top court's winners stay);
//   - its losers slide DOWN one court (the bottom court's losers rotate out);
//   - the bottom court refills from whoever has sat longest.
// EVERY arriving pair splits: the two who just won together on the lower
// court are put on opposite sides, as are the two who arrived from above, so
// each new team is one player from above and one from below — nobody keeps a
// winning partner. No ratings are consulted anywhere; position on the court
// ladder is the format's only memory.
let buildKingCourtRound = (
  ~players: array<Player.t<'a>>,
  ~courts: int,
  ~rounds: array<array<completedMatchEntity<'a>>>,
  ~prng: SolverPrng.t,
): array<Match.t<'a>> => {
  let byId = Js.Dict.empty()
  players->Array.forEach(p => byId->Js.Dict.set(p.id, p))
  let prev = rounds->Array.get(rounds->Array.length - 1)->Option.getOr([])

  let side = (c: int, winning: bool): array<Player.t<'a>> =>
    prev
    ->Array.get(c)
    ->Option.flatMap(e =>
      switch e.score {
      | Some((a, b)) => {
          let (t1, t2) = e.match
          Some(a > b == winning ? t1 : t2)
        }
      | None => None
      }
    )
    ->Option.getOr([])

  // Intended occupants per court, [pair-from-above, pair-from-below] order.
  let intended = if prev->Array.length == 0 {
    // Opening round: deal at random.
    let sh = shuffle(players, ~prng)
    Belt.Array.makeBy(Js.Math.min_int(courts, sh->Array.length / 4), c =>
      sh->Array.slice(~start=c * 4, ~end=c * 4 + 4)
    )
  } else {
    Belt.Array.makeBy(courts, c => {
      let fromAbove = c == 0 ? side(0, true) : side(c - 1, false)
      let fromBelow = c < courts - 1 ? side(c + 1, true) : []
      Array.concat(fromAbove, fromBelow)
    })
  }

  // Repair pass: drop the absent, never seat anyone twice, and backfill each
  // short court from the queue — present players not yet seated, longest
  // sitting first. Absences and the bottom court's refill both land here.
  let seatedIds = Set.make()
  let repaired = intended->Array.map(group =>
    group->Array.filterMap(p =>
      switch byId->Js.Dict.get(p.id) {
      | Some(fresh) if !(seatedIds->Set.has(p.id)) => {
          seatedIds->Set.add(p.id)
          Some(fresh)
        }
      | _ => None
      }
    )
  )
  // The bottom court's losers go to the BACK of the line — they rotate out
  // for at least a round, whatever their play count, or a tie on counts could
  // seat them right back down.
  let rotatedOut =
    prev
    ->Array.get(prev->Array.length - 1)
    ->Option.flatMap(e =>
      switch e.score {
      | Some((a, b)) => {
          let (t1, t2) = e.match
          Some((a > b ? t2 : t1)->Array.map(p => p.id))
        }
      | None => None
      }
    )
    ->Option.getOr([])
    ->Set.fromArray
  let waiting = shuffle(players->Array.filter(p => !(seatedIds->Set.has(p.id))), ~prng)
  let queue = Array.concat(
    waiting
    ->Array.filter(p => !(rotatedOut->Set.has(p.id)))
    ->Array.toSorted((a, b) => Float.fromInt(a.count - b.count)),
    waiting->Array.filter(p => rotatedOut->Set.has(p.id)),
  )
  let qi = ref(0)
  let matches = []
  repaired->Array.forEach(group => {
    let g = group->Array.copy
    while g->Array.length < 4 && qi.contents < queue->Array.length {
      switch queue->Array.get(qi.contents) {
      | Some(p) => g->Array.push(p)
      | None => ()
      }
      qi := qi.contents + 1
    }
    switch g {
    | [a, b, c, d] =>
      // {a, b} came down (or stayed) together, {c, d} came up together: both
      // pairs split across the net, the coin deciding who partners whom.
      matches->Array.push(
        SolverPrng.nextFloat(prng) < 0.5 ? ([a, c], [b, d]) : ([a, d], [b, c]),
      )
    | _ => () // the roster cannot fill this court tonight
    }
  })
  matches
}

let buildOpenPlayRound = (
  ~style: roundEngine,
  ~players: array<Player.t<'a>>,
  ~courts: int,
  ~rounds: array<array<completedMatchEntity<'a>>>,
  ~truth: array<float>,
  ~pods: option<array<Set.t<string>>>,
  ~prng: SolverPrng.t,
): array<Match.t<'a>> => {
  let history = CostModel.buildHistory(~rounds, ~players)
  let seats = courts * 4
  let previous = rounds->Array.get(rounds->Array.length - 1)->Option.getOr([])
  let beforePrevious = rounds->Array.get(rounds->Array.length - 2)->Option.getOr([])

  let presentIds = players->Array.map(p => p.id)->Set.fromArray
  let carried = switch style {
  | AmericanOpenPlay =>
    americanCarryOvers(
      ~previous,
      ~beforePrevious,
      ~maxCarried=Js.Math.max_int(0, courts - 1),
      ~prng,
    )
    // A carried match survives only while all four are still in the building
    // — a drop-in leaving between sessions dissolves it.
    ->Array.filter(m => Match.players(m)->Array.every(p => presentIds->Set.has(p.id)))
  | _ => []
  }
  let carriedIds =
    carried->Array.flatMap(m => Match.players(m)->Array.map(p => p.id))->Set.fromArray

  // Whoever is not already holding a court queues by games played, so the
  // people who have sat most go on next.
  let queue =
    shuffle(players->Array.filter(p => !(carriedIds->Set.has(p.id))), ~prng)
    ->Array.toSorted((a, b) => Float.fromInt(a.count - b.count))
  let remainingSeats = Js.Math.max_int(0, seats - carriedIds->Set.size)
  let seated = queue->Array.slice(~start=0, ~end=remainingSeats)

  let courtsLeft = Js.Math.max_int(0, courts - carried->Array.length)

  // In a tournament the squad is the team. Build pairs inside each squad and
  // then put two pairs on a court; the style's own logic can still choose WHICH
  // pairs meet, but not who partners whom.
  let podPairs = switch pods {
  | None => None
  | Some(groups) =>
    // Pair inside each squad across the WHOLE roster, then let play counts pick
    // which pairs take a court. Pairing only the already-seated players left
    // squads with an odd member out and courts standing empty, because a
    // leftover has no squad-mate to partner.
    let pairs = []
    groups->Array.forEach(group => {
      let members = shuffle(players->Array.filter(p => group->Set.has(p.id)), ~prng)
      let i = ref(0)
      while i.contents + 1 < members->Array.length {
        pairs->Array.push([
          members->Array.getUnsafe(i.contents),
          members->Array.getUnsafe(i.contents + 1),
        ])
        i := i.contents + 2
      }
    })
    // Whoever has sat most goes on first, which is the same fairness rule the
    // free-play path uses for individuals.
    Some(
      pairs->Array.toSorted((a, b) =>
        Float.fromInt(
          (a->Array.getUnsafe(0)).count +
          (a->Array.getUnsafe(1)).count -
          (b->Array.getUnsafe(0)).count -
          (b->Array.getUnsafe(1)).count,
        )
      ),
    )
  }

  let quads = switch (podPairs, style) {
  | (Some(pairs), _) =>
    let out = []
    let i = ref(0)
    while out->Array.length < courtsLeft && i.contents + 1 < pairs->Array.length {
      out->Array.push(
        Array.concat(pairs->Array.getUnsafe(i.contents), pairs->Array.getUnsafe(i.contents + 1)),
      )
      i := i.contents + 2
    }
    out
  | (None, style) =>
    switch style {
  | AmericanOpenPlay =>
    // Fours form within a level, not across the room. Courts are shared out
    // between the two bands in turn so neither monopolises the session.
    let (lower, upper) = selfSortedBands(~seated, ~truth, ~prng)
    let lowerQuads = formFoursomes(~seated=lower, ~history, ~preferNovelty=false, ~prng)
    let upperQuads = formFoursomes(~seated=upper, ~history, ~preferNovelty=false, ~prng)
    let out = []
    let li = ref(0)
    let ui = ref(0)
    let takeLowerFirst = ref(SolverPrng.nextFloat(prng) < 0.5)
    while (
      out->Array.length < courtsLeft &&
        (li.contents < lowerQuads->Array.length || ui.contents < upperQuads->Array.length)
    ) {
      let fromLower = takeLowerFirst.contents
      let picked = fromLower
        ? lowerQuads->Array.get(li.contents)
        : upperQuads->Array.get(ui.contents)
      switch picked {
      | Some(quad) => {
          out->Array.push(quad)
          if fromLower {
            li := li.contents + 1
          } else {
            ui := ui.contents + 1
          }
        }
      | None => ()
      }
      takeLowerFirst := !takeLowerFirst.contents
    }
    // A level cannot always field four. When one band is short, the court does
    // not stay empty — whoever is waiting plays whoever else is waiting, which
    // is the one moment the two groups reliably mix.
    if out->Array.length < courtsLeft {
      let used = out->Array.flatMap(q => q->Array.map(p => p.id))->Set.fromArray
      let leftovers = seated->Array.filter(p => !(used->Set.has(p.id)))
      formFoursomes(~seated=leftovers, ~history, ~preferNovelty=false, ~prng)
      ->Array.slice(~start=0, ~end=courtsLeft - out->Array.length)
      ->Array.forEach(q => out->Array.push(q))
    }
    out
  | _ =>
    formFoursomes(~seated, ~history, ~preferNovelty=true, ~prng)
    ->Array.slice(~start=0, ~end=courtsLeft)
    }
  }

  let fresh =
    quads->Array.map(quad => {
      let split = switch (pods, quad) {
      // Pod-built quad: the pairs are the teams.
      | (Some(_), [a, b, c, d]) => ([a, b], [c, d])
      | _ =>
        switch style {
        | JapanOpenPlay => splitJapan(quad, ~truth, ~prng)
        | _ => splitRandom(quad, ~prng)
        }
      }
      // In a tournament the squads are fixed, so a team has to come from one
      // pod. Re-split the foursome along pod lines when the free split crossed
      // them; if the four span more than two pods there is no legal split and
      // the free one stands.
      switch pods {
      | None => split
      | Some(groups) =>
        let podOf = (p: Player.t<'a>) =>
          groups->Array.findIndex(g => g->Set.has(p.id))
        switch quad->Array.map(podOf)->Array.toSorted((a, b) => Float.fromInt(a - b)) {
        | [a, b, c, d] if a == b && c == d && a != c =>
          let first = quad->Array.filter(p => podOf(p) == a)
          let second = quad->Array.filter(p => podOf(p) == c)
          switch (first, second) {
          | ([p1, p2], [p3, p4]) => ([p1, p2], [p3, p4])
          | _ => split
          }
        | _ => split
        }
      }
    })
  Array.concat(carried, fresh)
}

// ---------------------------------------------------------------------------
// Frames
// ---------------------------------------------------------------------------

type gameRecord = {
  courtIndex: int,
  team1: array<string>,
  team2: array<string>,
  // Player slots on court, so a game's quality can be attributed to the level
  // band each of its players belongs to.
  playerIndices: array<int>,
  team1Score: float,
  team2Score: float,
  // What the ratings expected for team 1, and what the truth says.
  predictedWinProb: float,
  trueWinProb: float,
  isBlowout: bool,
  // The rated favourite lost.
  isUpset: bool,
  // Match-quality proxies: probability this game ends level, as the ratings
  // see it and as the hidden truth sees it.
  predictedDraw: float,
  trueDraw: float,
}

// Level bands by TRUE skill, one per court — band 0 is the strongest, matching
// the app's convention that court 1 is the top court. Keyed on truth rather
// than the visible ratings on purpose: the question is what quality of game a
// genuinely strong or weak player receives, which should not move around just
// because the ladder is wrong.
let bandsOf = (~truth: array<float>, ~numBands: int): array<int> => {
  let n = truth->Array.length
  if n == 0 || numBands <= 0 {
    []
  } else {
    let order =
      Belt.Array.makeBy(n, i => i)->Array.toSorted((a, b) =>
        truth->Array.getUnsafe(b) -. truth->Array.getUnsafe(a)
      )
    let out = Belt.Array.make(n, 0)
    order->Array.forEachWithIndex((playerIndex, rank) =>
      out->Array.setUnsafe(
        playerIndex,
        Js.Math.min_int(numBands - 1, rank * numBands / n),
      )
    )
    out
  }
}

type frame = {
  round: int,
  mu: array<float>,
  sigma: array<float>,
  spearman: float,
  rankError: float,
  muError: float,
  // None on the pre-play frame.
  blowoutRate: option<float>,
  trueQuality: option<float>,
  predQuality: option<float>,
  // Mean draw probability across the round, from hidden truth: the quality
  // proxy. Higher = better matched.
  trueDrawProb: option<float>,
  // Median of the same per-game draw probabilities: the TYPICAL game, immune
  // to how hard the round's disasters drag the mean. The mean stays the
  // headline — a session's blowouts should count against it — but the pair
  // together separates "the typical game is bad" from "the average is being
  // destroyed by the worst games": the mean-median gap is tail drag, per
  // round. This is what exposed JP-style's old split threshold as a bulk
  // intervention (its median moved +21 against random) and the sigma-0 draw
  // bug (Balanced Round Robin's median read 102%).
  medianDrawProb: option<float>,
  // Match quality experienced by each level band, strongest first. Averaged
  // over (player, game) pairs rather than over games, so a match that mixes
  // levels counts toward every band standing on that court — which is the
  // point: a carry game is a good game for one player and a bad one for
  // another, and a single per-match number hides that.
  qualityByBand: array<option<float>>,
  // Rating forecast error: mean |predicted win probability - true win
  // probability|, per match. This is the ratings' accuracy as a continuous
  // quantity — how far off the forecast for THIS game was — and unlike any
  // measure of evenness it does not reward a strategy for declining to make a
  // claim. 0 = the ratings called every game exactly right.
  forecastError: option<float>,
  games: array<gameRecord>,
  byes: array<string>,
}

type strategyRun = {
  entry: labStrategy,
  frames: array<frame>,
  fellBackToGreedy: bool,
}

// True skill at a given round, after drift. Everything that reads the truth —
// metrics, the outcome model, the oracle — must use this rather than the
// starting values, or a strategy would be graded against a world that no
// longer exists.
let truthAt = (~base: array<float>, ~roles: array<drift>, ~round: int): array<float> =>
  base->Array.mapWithIndex((v, i) =>
    v +.
    driftAt(roles->Array.get(i)->Option.getOr(Steady), ~round)
  )

// ---------------------------------------------------------------------------
// Sessions: form jitter and drop-ins
// ---------------------------------------------------------------------------

// A real club plays in sessions of roughly this many rounds; the 100-round
// horizon is seven or eight of them. Session boundaries are where day-to-day
// form changes and where attendance changes.
let sessionLength = 13

let sessionOf = (round: int) => round <= 1 ? 0 : (round - 1) / sessionLength

// Day-to-day form: each session, every player performs at their underlying
// skill plus a temporary offset — up to about 0.15 DUPR either way, centred
// on zero (sum of two uniforms, so mid-sized swings are more common than
// extremes). Drawn once per run from its own seeded stream and shared by
// every strategy, so all of them face the same good days and bad days.
//
// Outcomes are played at the PERFORMED level (`performedAt`); the ladder
// metrics stay graded against the underlying level (`truthAt`). That split is
// deliberate: next session's form is unknowable, so the best possible rating
// tracks underlying skill and treats form as noise — the test is whether the
// rating system sees THROUGH a whole session of correlated noise without
// being dragged around by it, not whether it chases the unknowable.
let formSwingDupr = 0.15

let formTable = (~numPlayers: int, ~numRounds: int, ~seed: int): array<array<float>> => {
  let sessions = sessionOf(numRounds) + 1
  let prng = SolverPrng.fromSeedString("lab-form:" ++ Int.toString(seed))
  Belt.Array.makeBy(sessions, _ =>
    Belt.Array.makeBy(numPlayers, _ => {
      let u1 = SolverPrng.nextFloat(prng)
      let u2 = SolverPrng.nextFloat(prng)
      (u1 +. u2 -. 1.0) *. formSwingDupr *. muPerDupr
    })
  )
}

// Skill as PLAYED this round: underlying truth plus this session's form.
let performedAt = (
  ~base: array<float>,
  ~roles: array<drift>,
  ~form: array<array<float>>,
  ~round: int,
): array<float> => {
  let offsets = form->Array.get(sessionOf(round))->Option.getOr([])
  truthAt(~base, ~roles, ~round)->Array.mapWithIndex((v, i) =>
    v +. offsets->Array.get(i)->Option.getOr(0.0)
  )
}

// Drop-ins: two players who attend only some sessions — one from the 70th
// percentile of the true ladder and one from the 30th, so the model covers a
// drop-in the club has to place high and one it has to place low. They arrive
// UNRATED whatever the scenario says — a drop-in is by definition someone the
// system has no history for — first appear in a random session, and either
// never return or return sporadically. The plan is drawn once per run and
// shared by every strategy. There is always at least ONE drop-in: when the
// roster has no slack over the seats, their absent sessions simply run a
// court short — which is exactly what happens to a real club that planned
// its courts around someone who did not come back.
let dropInReturnChance = 0.3
let dropInPercentiles = [0.7, 0.3]

type attendancePlan = {
  isDropIn: array<bool>,
  // [session][player]
  attends: array<array<bool>>,
}

let dropInPlan = (
  ~numPlayers: int,
  ~courts: int,
  ~numRounds: int,
  ~seed: int,
  ~ranks: array<int>,
): attendancePlan => {
  let sessions = sessionOf(numRounds) + 1
  let seats = courts * 4
  let count = Js.Math.max_int(
    1,
    Js.Math.min_int(dropInPercentiles->Array.length, numPlayers - seats),
  )
  let prng = SolverPrng.fromSeedString("lab-dropins:" ++ Int.toString(seed))
  let isDropIn = Belt.Array.make(numPlayers, false)
  // The slot holding a given ladder percentile. `ranks` maps slot -> ladder
  // rank (0 = weakest), so invert it at the ranks we want.
  for i in 0 to count - 1 {
    let pct = dropInPercentiles->Array.getUnsafe(i)
    let wantRank = Js.Math.round(pct *. Float.fromInt(numPlayers - 1))->Float.toInt
    ranks->Array.forEachWithIndex((r, slot) =>
      if r == wantRank {
        isDropIn->Array.setUnsafe(slot, true)
      }
    )
  }
  // Attendance per drop-in: one first appearance; half are one-and-done, the
  // rest come back to any later session with `dropInReturnChance`.
  let attends = Belt.Array.makeBy(sessions, _ => Belt.Array.make(numPlayers, true))
  isDropIn->Array.forEachWithIndex((isD, player) =>
    if isD {
      let first = Js.Math.floor_int(SolverPrng.nextFloat(prng) *. Float.fromInt(sessions))
      let oneAndDone = SolverPrng.nextFloat(prng) < 0.5
      for sess in 0 to sessions - 1 {
        let there = if sess == first {
          true
        } else if sess < first || oneAndDone {
          false
        } else {
          SolverPrng.nextFloat(prng) < dropInReturnChance
        }
        (attends->Array.getUnsafe(sess))->Array.setUnsafe(player, there)
      }
    }
  )
  {isDropIn, attends}
}

type labResult = {
  scenario: scenario,
  seed: int,
  numPlayers: int,
  courts: int,
  numRounds: int,
  // Starting truth; `truthAt` applies drift for a given round.
  truth: array<float>,
  driftRoles: array<drift>,
  // Per-session performance offsets, [session][player]; see `formTable`.
  form: array<array<float>>,
  // Which players are drop-ins, and who attends which session.
  dropIns: array<bool>,
  attendance: array<array<bool>>,
  names: array<string>,
  flagged: array<bool>,
  runs: array<strategyRun>,
}

let makeFrame = (
  ~round: int,
  ~state: array<Player.t<'a>>,
  ~truth: array<float>,
  ~games: array<gameRecord>,
  ~byes: array<string>,
  ~numPlayers: int,
  ~numBands: int,
) => {
  // Index by intId so the ladder rows stay stable regardless of solver order.
  let mu = Belt.Array.make(numPlayers, 25.0)
  let sigma = Belt.Array.make(numPlayers, 25.0 /. 3.0)
  state->Array.forEach(p => {
    mu->Array.setUnsafe(p.intId, p.rating.mu)
    sigma->Array.setUnsafe(p.intId, p.rating.sigma)
  })
  let mean = (xs: array<float>) =>
    xs->Array.length == 0
      ? None
      : Some(xs->Array.reduce(0., (a, b) => a +. b) /. Float.fromInt(xs->Array.length))
  let bands = bandsOf(~truth, ~numBands)
  {
    round,
    mu,
    sigma,
    spearman: spearman(~visible=mu, ~truth),
    rankError: rankError(~visible=mu, ~truth),
    muError: muError(~visible=mu, ~truth),
    blowoutRate: mean(games->Array.map(g => g.isBlowout ? 1.0 : 0.0)),
    trueDrawProb: mean(games->Array.map(g => g.trueDraw)),
    medianDrawProb: {
      let sorted = games->Array.map(g => g.trueDraw)->Array.toSorted((a, b) => a -. b)
      let n = sorted->Array.length
      n == 0
        ? None
        : Some(
            mod(n, 2) == 1
              ? sorted->Array.getUnsafe(n / 2)
              : (sorted->Array.getUnsafe(n / 2 - 1) +. sorted->Array.getUnsafe(n / 2)) /. 2.0,
          )
    },
    qualityByBand: Belt.Array.makeBy(numBands, band => {
      let total = ref(0.0)
      let seats = ref(0)
      games->Array.forEach(g =>
        g.playerIndices->Array.forEach(i =>
          switch bands->Array.get(i) {
          | Some(b) if b == band => {
              total := total.contents +. g.trueDraw
              seats := seats.contents + 1
            }
          | _ => ()
          }
        )
      )
      seats.contents == 0 ? None : Some(total.contents /. Float.fromInt(seats.contents))
    }),
    forecastError: mean(
      games->Array.map(g => Js.Math.abs_float(g.predictedWinProb -. g.trueWinProb)),
    ),
    trueQuality: mean(
      games->Array.map(g => Js.Math.abs_float(g.trueWinProb -. 0.5) *. 2.0),
    ),
    predQuality: mean(
      games->Array.map(g => Js.Math.abs_float(g.predictedWinProb -. 0.5) *. 2.0),
    ),
    games,
    byes,
  }
}

// ---------------------------------------------------------------------------
// Role probe — an experiment, not a strategy
// ---------------------------------------------------------------------------
//
// Pins one player to the favored or unfavored side of every match they play,
// to measure what a streak of one role does to that player's rating. It only
// re-splits the foursome the matchmaker already chose: the same four players
// share the court, so partner and opponent rotation stay the matchmaker's.
// Applied after the solve and before scoring, so the rating replay and the
// next round's history both see the swapped match. Never used by the UI or
// the saved runs (see scripts/role-probe.ts).

type roleTarget =
  | ForceFavored
  | ForceUnfavored
  // The control: flip side every game, with the same kind of re-split.
  | ForceAlternate

type probePick =
  // Keep the matchmaker's own split when it already achieves the target;
  // otherwise the achieving split closest to an even game.
  | Nearest
  // The most one-sided achieving split (favored: strongest partner).
  | Farthest

// Experiment only: a regular who misses a stretch of rounds — arrives late,
// leaves early, skips a session — and comes back rated but behind on games.
// Inclusive, 1-based rounds.
type absence = {absentIntId: int, fromRound: int, toRound: int}

type roleProbe = {
  playerIntId: int,
  target: roleTarget,
  // Favored means own win probability above 0.5 + margin; unfavored, below
  // 0.5 - margin. 0 = strictly one side; 0.05 = outside the dead zone.
  margin: float,
  pick: probePick,
}

// A player's own win probability in a match, as the ratings at match time
// see it. None when they are not in it.
let ownWinProbIn = (match: Match.t<'a>, ~intId: int): option<float> => {
  let (team1, team2) = match
  let p = predictedWinProbability(match)
  if team1->Array.some(x => x.intId == intId) {
    Some(p)
  } else if team2->Array.some(x => x.intId == intId) {
    Some(1.0 -. p)
  } else {
    None
  }
}

// `lastOwnWinProb` is the player's most recent game that was clearly on one
// side (outside the margin); only ForceAlternate reads it.
let probeAchieves = (~probe: roleProbe, ~ownWinProb: float, ~lastOwnWinProb: option<float>) => {
  let favored = ownWinProb > 0.5 +. probe.margin
  let unfavored = ownWinProb < 0.5 -. probe.margin
  switch probe.target {
  | ForceFavored => favored
  | ForceUnfavored => unfavored
  | ForceAlternate =>
    switch lastOwnWinProb {
    | Some(last) if last > 0.5 => unfavored
    | Some(_) => favored
    | None => favored || unfavored
    }
  }
}

// Re-split the probed player's foursome to meet the target. Returns the match
// unchanged when the player is not in it or no split achieves the target
// (the ringer cannot be made an underdog by any partner choice).
let applyRoleProbe = (
  match: Match.t<'a>,
  ~probe: roleProbe,
  ~lastOwnWinProb: option<float>,
): Match.t<'a> => {
  let (team1, team2) = match
  let inTeam1 = team1->Array.some(p => p.intId == probe.playerIntId)
  let inTeam2 = team2->Array.some(p => p.intId == probe.playerIntId)
  let (mine, theirs) = inTeam1 ? (team1, team2) : (team2, team1)
  switch mine->Array.find(p => p.intId == probe.playerIntId) {
  | Some(me) if inTeam1 || inTeam2 =>
    // Index 0 is the matchmaker's own partner, so candidate 0 is its split.
    let others = Array.concat(mine->Array.filter(p => p.intId != probe.playerIntId), theirs)
    if others->Array.length != 3 {
      match
    } else {
      let candidates = others->Array.mapWithIndex((partner, i) => {
        let pair = [me, partner]
        let rest = others->Array.filterWithIndex((_, j) => j != i)
        (i, pair, rest, predictedWinProbability((pair, rest)))
      })
      let achieving =
        candidates->Array.filter(((_, _, _, prob)) =>
          probeAchieves(~probe, ~ownWinProb=prob, ~lastOwnWinProb)
        )
      let chosen = switch probe.pick {
      | Nearest =>
        switch achieving->Array.find(((i, _, _, _)) => i == 0) {
        | Some(own) => Some(own)
        | None =>
          achieving->Array.reduce(None, (best, c) => {
            let (_, _, _, prob) = c
            switch best {
            | Some((_, _, _, bp)) if Js.Math.abs_float(bp -. 0.5) <= Js.Math.abs_float(prob -. 0.5) =>
              best
            | _ => Some(c)
            }
          })
        }
      | Farthest =>
        achieving->Array.reduce(None, (best, c) => {
          let (_, _, _, prob) = c
          switch best {
          | Some((_, _, _, bp)) if Js.Math.abs_float(bp -. 0.5) >= Js.Math.abs_float(prob -. 0.5) =>
            best
          | _ => Some(c)
          }
        })
      }
      switch chosen {
      | None | Some((0, _, _, _)) => match
      | Some((_, pair, rest, _)) => inTeam1 ? (pair, rest) : (rest, pair)
      }
    }
  | _ => match
  }
}

// ---------------------------------------------------------------------------
// The run
// ---------------------------------------------------------------------------

let simulateStrategy = async (
  ~entry: labStrategy,
  ~initialPlayers: array<Player.t<unit>>,
  ~baseTruth: array<float>,
  ~roles: array<drift>,
  ~form: array<array<float>>,
  ~plan: attendancePlan,
  ~courts: int,
  ~numRounds: int,
  ~seed: int,
  ~numPlayers: int,
  ~pods: option<array<Set.t<string>>>,
  ~onRound: option<unit => unit>=?,
  ~probe: option<roleProbe>=?,
  ~absences: array<absence>=[],
): strategyRun => {
  let seedString = "lab:" ++ Int.toString(seed) ++ ":" ++ entry.id
  let outcomePrng = SolverPrng.fromSeedString(seedString ++ ":outcomes")
  let startTime = Js.Date.fromFloat(0.0)

  let scoredRounds = ref([])
  let frames = [
    makeFrame(
      ~round=0,
      ~state=initialPlayers,
      ~truth=truthAt(~base=baseTruth, ~roles, ~round=0),
      ~games=[],
      ~byes=[],
      ~numPlayers,
      ~numBands=courts,
    ),
  ]
  let fellBack = ref(false)
  let round = ref(0)
  // The probed player's last clearly-sided game, for ForceAlternate.
  let probeLast = ref(None)

  while round.contents < numRounds {
    let state = toPlayerStateWithAdjustments(
      scoredRounds.contents,
      ~players=initialPlayers,
      ~adjustments=[],
    )

    // The round being built is round.contents + 1 in human terms; sessions,
    // form and attendance are all keyed on it.
    let thisRound = round.contents + 1
    // Truth as it stands this round: players drift, so the target moves. The
    // ladder metrics grade against this. Outcomes are played at `performed` —
    // truth plus this session's form.
    let truth = truthAt(~base=baseTruth, ~roles, ~round=round.contents)
    let performed = performedAt(~base=baseTruth, ~roles, ~form, ~round=thisRound)

    // An oracle sees the truth when CHOOSING matches only — today's PERFORMED
    // truth, the strongest oracle there is. The results it produces still
    // update the real ratings, so its ladder column stays an honest measure
    // of what its matches teach.
    let solverPlayers = entry.usesTruth
      ? state->Array.map(p => {
          let t = performed->Array.getUnsafe(p.intId)
          {...p, rating: Rating.make(t, p.rating.sigma), ratingOrdinal: t}
        })
      : state
    // Only the players attending this session are in the pool tonight.
    let attending =
      plan.attends->Array.get(sessionOf(thisRound))->Option.getOr([])
    let isPresent = (p: Player.t<'a>) =>
      attending->Array.get(p.intId)->Option.getOr(true) &&
        !(absences->Array.some(a =>
          a.absentIntId == p.intId && thisRound >= a.fromRound && thisRound <= a.toRound
        ))
    let presentPlayers = solverPlayers->Array.filter(isPresent)
    let realById = Js.Dict.empty()
    state->Array.forEach(p => realById->Js.Dict.set(p.id, p))
    let restoreRatings = (match: Match.t<'a>): Match.t<'a> => {
      let (team1, team2) = match
      let fix = (team: Team.t<'a>) =>
        team->Array.map(p =>
          switch realById->Js.Dict.get(p.id) {
          | Some(real) => {...p, rating: real.rating, ratingOrdinal: real.ratingOrdinal}
          | None => p
          }
        )
      (fix(team1), fix(team2))
    }

    // Open-play styles build their own round; everything else goes through the
    // real solver. Both paths end with the same shape, so the metrics, scoring
    // and rating replay below are shared.
    let (matches, fellBackThisRound) = switch entry.engine {
    | SolverEngine =>
      let result = await SolverRounds.generateRounds(
        ~numberOfRounds=1,
        ~availablePlayers=presentPlayers,
        ~completedRounds=scoredRounds.contents,
        ~strategy=entry.strategy,
        ~courtCount=courts,
        ~startTime,
        ~weightConfig=?entry.weightConfig,
        // Tournament squads reach the solver as partner pools — the mechanism
        // the app already has for "these people play together".
        ~teamConstraints=?pods,
        ~startRoundIndex=round.contents,
        ~seed=seedString,
        (),
      )
      (
        result.rounds
        ->Array.get(0)
        ->Option.map(outcome => outcome.matches->Array.map(m => m.match))
        ->Option.getOr([]),
        result.fellBackToGreedy,
      )
    | KingCourtPlay if pods == None => (
        buildKingCourtRound(
          ~players=presentPlayers,
          ~courts,
          ~rounds=scoredRounds.contents,
          ~prng=SolverPrng.fromSeedString(
            seedString ++ "#open#" ++ round.contents->Int.toString,
          ),
        ),
        false,
      )
    // Tournament pods override every open-play format — the squads are the
    // teams — so king-of-the-court with pods routes through the shared
    // pod-pairing path like the other styles.
    | style => (
        buildOpenPlayRound(
          ~style,
          ~players=presentPlayers,
          ~courts,
          ~rounds=scoredRounds.contents,
          ~truth,
          ~pods,
          ~prng=SolverPrng.fromSeedString(
            seedString ++ "#open#" ++ round.contents->Int.toString,
          ),
        ),
        false,
      )
    }
    if fellBackThisRound {
      fellBack := true
    }

    if matches->Array.length == 0 {
      round := numRounds // nothing more can be generated
    } else {
      let createdAt = Js.Date.fromFloat(
        startTime->Js.Date.getTime +. Float.fromInt(round.contents + 1) *. 600000.0,
      )
      let seatedIds = Set.make()
      let scored = matches->Array.mapWithIndex((rawMatch, courtIndex) => {
        // Composition may have come from an oracle's view of the pool; every
        // number recorded from here on uses the real ratings.
        let match = entry.usesTruth ? restoreRatings(rawMatch) : rawMatch
        // Tournament pods fix the teams, so there is nothing to re-split.
        let match = switch probe {
        | Some(pr) if pods == None =>
          let swapped = applyRoleProbe(match, ~probe=pr, ~lastOwnWinProb=probeLast.contents)
          switch ownWinProbIn(swapped, ~intId=pr.playerIntId) {
          | Some(own) if Js.Math.abs_float(own -. 0.5) > pr.margin => probeLast := Some(own)
          | _ => ()
          }
          swapped
        | _ => match
        }
        let predicted = predictedWinProbability(match)
        let trueProb = trueWinProbability(match, ~truth=performed)
        let (s1, s2) = simulateScore(match, ~truth=performed, ~prng=outcomePrng)
        let (team1, team2) = match
        team1->Array.forEach(p => seatedIds->Set.add(p.id))
        team2->Array.forEach(p => seatedIds->Set.add(p.id))
        let record = {
          courtIndex,
          team1: team1->Array.map(p => p.name),
          team2: team2->Array.map(p => p.name),
          playerIndices: Match.players(match)->Array.map(p => p.intId),
          team1Score: s1,
          team2Score: s2,
          predictedWinProb: predicted,
          trueWinProb: trueProb,
          isBlowout: Js.Math.abs_float(s1 -. s2) >= 9.0,
          isUpset: (predicted > 0.5) != (s1 > s2),
          predictedDraw: drawProbability(match, ~truth=None),
          trueDraw: drawProbability(match, ~truth=Some(performed)),
        }
        let entity: CompletedMatchEntity.t<'a> = {
          id: randomUUID(),
          match: match->Match.incrementPlayCounts,
          score: Some((s1, s2)),
          createdAt,
          synced: false,
        }
        (entity, record)
      })

      scoredRounds := Array.concat(scoredRounds.contents, [scored->Array.map(((e, _)) => e)])

      let after = toPlayerStateWithAdjustments(
        scoredRounds.contents,
        ~players=initialPlayers,
        ~adjustments=[],
      )
      frames->Array.push(
        makeFrame(
          ~round=round.contents + 1,
          ~state=after,
          ~truth,
          ~games=scored->Array.map(((_, r)) => r),
          ~byes=initialPlayers
          ->Array.filter(p => isPresent(p) && !(seatedIds->Set.has(p.id)))
          ->Array.map(p => p.name),
          ~numPlayers,
          ~numBands=courts,
        ),
      )
      round := round.contents + 1
      switch onRound {
      | Some(cb) => cb()
      | None => ()
      }
      await SolverRounds.yieldToBrowser()
    }
  }

  {entry, frames, fellBackToGreedy: fellBack.contents}
}

let run = async (
  ~scenario: scenario,
  ~seed: int,
  ~numPlayers: int,
  ~courts: int,
  ~numRounds: int,
  ~dist: distribution=variedField,
  // Tournament mode: fixed squads of four, so each player has exactly three
  // possible partners for the whole session.
  ~tournament: bool=false,
  ~onRound: option<unit => unit>=?,
  // Which strategies to run; experiments pass a subset.
  ~entries: array<labStrategy>=strategies,
  // Experiment only — see `roleProbe`.
  ~probe: option<roleProbe>=?,
  // Experiment only — see `absence`.
  ~absences: array<absence>=[],
): labResult => {
  let ranks = ladderPermutation(~seed, ~numPlayers)
  let baseTruth = Belt.Array.makeBy(numPlayers, index =>
    trueSkill(~index=ranks->Array.getUnsafe(index), ~numPlayers, ~dist)
  )
  // Drawn once and shared by every strategy in this run, so the comparison is
  // between matchmakers rather than between different luck about who improved.
  let roles = driftRoles(~numPlayers, ~seed)
  let form = formTable(~numPlayers, ~numRounds, ~seed)
  let plan = dropInPlan(~numPlayers, ~courts, ~numRounds, ~seed, ~ranks)
  let initialPlayers =
    buildPlayers(~scenario, ~numPlayers, ~ranks, ~dist)->Array.map(p =>
      // A drop-in arrives unrated whatever the scenario's prior says — the
      // system has no history for them. The dagger marks them everywhere a
      // name is shown.
      plan.isDropIn->Array.get(p.intId)->Option.getOr(false)
        ? {
            ...p,
            name: p.name ++ "\u2020",
            rating: Rating.makeDefault(),
            ratingOrdinal: Rating.makeDefault()->Rating.ordinal,
          }
        : p
    )
  let pods = tournament ? Some(partnerPods(~players=initialPlayers, ~seed)) : None

  let runs = []
  for i in 0 to entries->Array.length - 1 {
    let entry = entries->Array.getUnsafe(i)
    let run = await simulateStrategy(
      ~entry,
      ~initialPlayers,
      ~baseTruth,
      ~roles,
      ~form,
      ~plan,
      ~courts,
      ~numRounds,
      ~seed,
      ~numPlayers,
      ~pods,
      ~onRound?,
      ~probe?,
      ~absences,
    )
    runs->Array.push(run)
  }

  {
    scenario,
    seed,
    numPlayers,
    courts,
    numRounds,
    truth: baseTruth,
    driftRoles: roles,
    form,
    dropIns: plan.isDropIn,
    attendance: plan.attends,
    names: initialPlayers->Array.map(p => p.name),
    flagged: Belt.Array.makeBy(numPlayers, index =>
      isFlagged(~scenario, ~index, ~numPlayers)
    ),
    runs,
  }
}

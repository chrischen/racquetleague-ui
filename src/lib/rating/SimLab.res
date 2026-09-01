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

// A team as the app's model would see it if it knew the truth: hidden skill
// as mu, no uncertainty.
let truthRatings = (team: Team.t<'a>, ~truth: array<float>) =>
  team->Array.map(p => Rating.make(truth->Array.getUnsafe(p.intId), 0.0))

// Openskill's probit saturates to a literal 0.0 or 1.0 in floating point once
// the gap passes about two DUPR — the varied room's ringer-vs-beginner games.
// The world never grants certainty (an injury or a sandbag is always
// possible), and everything downstream treats these as probabilities.
let clampProb = (p: float) => Js.Math.max_float(1e-9, Js.Math.min_float(1.0 -. 1e-9, p))

let trueWinProbability = (match: Match.t<'a>, ~truth: array<float>) => {
  let (team1, team2) = match
  Rating.predictWin([truthRatings(team1, ~truth), truthRatings(team2, ~truth)])
  ->Array.get(0)
  ->Option.getOr(0.5)
  ->clampProb
}

// Draw probability as a match-quality proxy. `Rating.predictDraw` is the app's
// own model of "how likely is this game to end level", which is the most
// direct statement of an even match available — high means well matched.
//
// The true version swaps hidden skill in for each player's mu with a FIXED
// uncertainty of beta: the chance a game between these known skills ends
// level, a pure function of who is on the court. Beta is the model's own
// game-to-game performance variance — even a player of exactly known skill
// does not play the same game twice — and it is also what keeps openskill's
// draw heuristic inside its calibrated regime: at sigma 0 the formula is not
// a probability at all (a perfectly even match reads 132%), while at sigma =
// beta it is bounded and still discriminates across the whole gap range
// (even 84% · 8-mu gap 63% · 28-mu gap 3%).
//
// Two historical bugs live in this function, both caught by the metrics
// misbehaving:
//   - It once used each player's LIVE sigma, which contaminated every
//     quality curve with rating confidence: the same physical matchup read
//     as higher quality later in the session merely because games had been
//     played. The Random baseline exposed it — its composition cannot
//     improve, yet its plotted quality climbed all session.
//   - The fix overshot to sigma 0, where the heuristic exceeds 1.0 for
//     near-even teams. The MEDIAN game quality exposed that one: Balanced
//     Round Robin's median read 102%.
// The constant must stay a constant — never anything that changes as the
// session runs. The clamp is insurance, not the fix.
let drawSigma = CostModel.defaultBeta

let drawProbability = (match: Match.t<'a>, ~truth: option<array<float>>) => {
  let (team1, team2) = match
  let ratingsOf = (team: Team.t<'a>) =>
    team->Array.map((p): Rating.t =>
      switch truth {
      | Some(t) => Rating.make(t->Array.getUnsafe(p.intId), drawSigma)
      | None => p.rating
      }
    )
  Js.Math.max_float(
    0.0,
    Js.Math.min_float(1.0, Rating.predictDraw([ratingsOf(team1), ratingsOf(team2)])),
  )
}

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

// A score line consistent with the true win probability: the more lopsided the
// matchup, the further the loser falls short.
let simulateScore = (match: Match.t<'a>, ~truth: array<float>, ~prng: SolverPrng.t) => {
  let p1 = trueWinProbability(match, ~truth)
  let team1Wins = SolverPrng.nextFloat(prng) < p1
  let dominance = Js.Math.abs_float(p1 -. 0.5) *. 2.0
  let expectedLoser = (maxScore -. 2.0) *. (1.0 -. dominance)
  let jitter = (SolverPrng.nextFloat(prng) -. 0.5) *. 4.0
  let loser = Js.Math.max_float(
    0.0,
    Js.Math.min_float(maxScore -. 2.0, Js.Math.round(expectedLoser +. jitter)),
  )
  team1Wins ? (maxScore, loser) : (loser, maxScore)
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

  let carried = switch style {
  | AmericanOpenPlay =>
    americanCarryOvers(
      ~previous,
      ~beforePrevious,
      ~maxCarried=Js.Math.max_int(0, courts - 1),
      ~prng,
    )
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

type labResult = {
  scenario: scenario,
  seed: int,
  numPlayers: int,
  courts: int,
  numRounds: int,
  // Starting truth; `truthAt` applies drift for a given round.
  truth: array<float>,
  driftRoles: array<drift>,
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
// The run
// ---------------------------------------------------------------------------

let simulateStrategy = async (
  ~entry: labStrategy,
  ~initialPlayers: array<Player.t<unit>>,
  ~baseTruth: array<float>,
  ~roles: array<drift>,
  ~courts: int,
  ~numRounds: int,
  ~seed: int,
  ~numPlayers: int,
  ~pods: option<array<Set.t<string>>>,
  ~onRound: option<unit => unit>=?,
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

  while round.contents < numRounds {
    let state = toPlayerStateWithAdjustments(
      scoredRounds.contents,
      ~players=initialPlayers,
      ~adjustments=[],
    )

    // Truth as it stands this round: players drift, so the target moves.
    let truth = truthAt(~base=baseTruth, ~roles, ~round=round.contents)

    // An oracle sees the truth when CHOOSING matches only. The results it
    // produces still update the real ratings, so its ladder column stays an
    // honest measure of what its matches teach.
    let solverPlayers = entry.usesTruth
      ? state->Array.map(p => {
          let t = truth->Array.getUnsafe(p.intId)
          {...p, rating: Rating.make(t, p.rating.sigma), ratingOrdinal: t}
        })
      : state
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
        ~availablePlayers=solverPlayers,
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
    | style => (
        buildOpenPlayRound(
          ~style,
          ~players=solverPlayers,
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
        let predicted = predictedWinProbability(match)
        let trueProb = trueWinProbability(match, ~truth)
        let (s1, s2) = simulateScore(match, ~truth, ~prng=outcomePrng)
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
          trueDraw: drawProbability(match, ~truth=Some(truth)),
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
          ->Array.filter(p => !(seatedIds->Set.has(p.id)))
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
): labResult => {
  let ranks = ladderPermutation(~seed, ~numPlayers)
  let baseTruth = Belt.Array.makeBy(numPlayers, index =>
    trueSkill(~index=ranks->Array.getUnsafe(index), ~numPlayers, ~dist)
  )
  // Drawn once and shared by every strategy in this run, so the comparison is
  // between matchmakers rather than between different luck about who improved.
  let roles = driftRoles(~numPlayers, ~seed)
  let initialPlayers = buildPlayers(~scenario, ~numPlayers, ~ranks, ~dist)
  let pods = tournament ? Some(partnerPods(~players=initialPlayers, ~seed)) : None

  let runs = []
  for i in 0 to strategies->Array.length - 1 {
    let entry = strategies->Array.getUnsafe(i)
    let run = await simulateStrategy(
      ~entry,
      ~initialPlayers,
      ~baseTruth,
      ~roles,
      ~courts,
      ~numRounds,
      ~seed,
      ~numPlayers,
      ~pods,
      ~onRound?,
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
    names: initialPlayers->Array.map(p => p.name),
    flagged: Belt.Array.makeBy(numPlayers, index =>
      isFlagged(~scenario, ~index, ~numPlayers)
    ),
    runs,
  }
}

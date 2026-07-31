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
  w.wPartner +. w.wOpponent +. w.wRepeatLast +. w.wSpread +. w.wAlternate +. w.wNoise

// ---------------------------------------------------------------------------
// UI configuration -> weights
// ---------------------------------------------------------------------------

type advancedWeights = {
  partnerVariety: float,
  opponentVariety: float,
  // Banding: 0 = skill plays no part in who shares a court (guardrail only),
  // 1 = courts are grouped as tightly by skill as the pool allows. This is the
  // intra-match skill spread as its own tunable, decoupled from balancing.
  similarSkill: float,
  // See `costWeights.balanceTeams` — a toggle, not a degree.
  balanceTeams: bool,
  avoidRecentRepeats: float,
  alternateFavored: float,
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
    // The variety end of the primary slider is quality-blind; everywhere else
    // balanced splits are simply on.
    balanceTeams: t >= 0.2,
    wSpread: spreadWeightFor(t),
    wAlternate: defaultAlternateWeight,
    wNoise: 0.,
    wCohort: 0.,
    splitBalanceFirst: false,
    spreadTolerance: spreadToleranceFor(t),
  }

  switch config.advanced {
  | None => derived
  | Some(a) => {
      wPartner: logScale(a.partnerVariety),
      wOpponent: logScale(a.opponentVariety),
      wRepeatLast: logScale(a.avoidRecentRepeats),
      balanceTeams: a.balanceTeams,
      wSpread: spreadWeightFor(a.similarSkill),
      wAlternate: Js.Math.round(maxWeight *. clamp01(a.alternateFavored)),
      wNoise: derived.wNoise,
      wCohort: derived.wCohort,
      splitBalanceFirst: derived.splitBalanceFirst,
      spreadTolerance: spreadToleranceFor(a.similarSkill),
    }
  }
}

// The advanced-slider positions a given primary position implies. Opening the
// accordion shows these; touching one of them marks the config custom.
let advancedFromPrimary = (qualityVsVariety: float): advancedWeights => {
  let derived = weightsFromConfig({qualityVsVariety, advanced: None})
  {
    partnerVariety: logScaleInverse(derived.wPartner),
    opponentVariety: logScaleInverse(derived.wOpponent),
    similarSkill: clamp01(qualityVsVariety),
    balanceTeams: derived.balanceTeams,
    avoidRecentRepeats: logScaleInverse(derived.wRepeatLast),
    alternateFavored: derived.wAlternate /. maxWeight,
  }
}

// Nominal slider positions. NOT the effective preset weights — those are the
// named profiles below (`weightsForStrategy`). This seeds the customisation
// panel with a sensible starting point, and gives `SessionMetrics` a scale
// point for scoring legacy-strategy rounds. Presets are code, not data: only a
// *customised* `uiWeightConfig` is ever persisted, so preset retuning applies
// retroactively.
let presetConfig = (strategy: strategy): uiWeightConfig =>
  switch strategy {
  | SolverRoundRobin => {qualityVsVariety: 0.15, advanced: None}
  // At the variety end: Random Balanced is novelty-first with balance as a
  // per-foursome tiebreak, not a mid-axis compromise — a 0.5 nominal here made
  // the panel display "50% competitive" and seeded customs with heavy banding.
  | SolverRandomBalanced => {qualityVsVariety: 0.0, advanced: None}
  | SolverCompetitivePlus => {qualityVsVariety: 0.85, advanced: None}
  // Legacy strategies get the nearest preset, so the cost model can also be
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
  balanceTeams: false,
  wSpread: minSpreadWeight,
  wAlternate: 0.,
  wNoise: 50.,
  wCohort: 0.,
  splitBalanceFirst: false,
  spreadTolerance: spreadToleranceFor(0.),
}

// ---------------------------------------------------------------------------
// Solver preset profiles
// ---------------------------------------------------------------------------
//
// The three solver strategies are *named profiles*, not positions on the
// qualityVsVariety scale. Two of them are lexicographic by construction —
// novelty terms sized to dominate every quality term, so quality only ever
// breaks ties among comparably-novel rounds — which a single scalar on the
// Variety↔Competitive axis cannot express. (The slider still exists, but as
// the vocabulary for *custom* configs.)
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
//   Competitive+     (SolverCompetitivePlus variant)
//     Quality first: banding at full strength (spread tuned to max) with
//     balanced splits. This one genuinely lives on the slider axis.

let noveltyFirstBase: costWeights = {
  wPartner: 1000.,
  // One repeated opponent pair costs wOpponent * 0.4 / 4 = 50 — sized to beat
  // the largest realistic quality swing, so "maximum variety" covers opponents
  // too, not just partners.
  wOpponent: 500.,
  wRepeatLast: 500.,
  // Splits are balanced by construction (the toggle is a hard filter), so no
  // weight arithmetic is involved and novelty dominance is untouched.
  balanceTeams: true,
  // "No concern for skill spread": the floor keeps only the carry-match
  // guardrail alive, at a tolerance where ordinary mixing is free.
  wSpread: minSpreadWeight,
  wAlternate: 100.,
  wNoise: 0.,
  wCohort: 0.,
  splitBalanceFirst: false,
  spreadTolerance: 0.9,
}

let roundRobinWeights = {
  ...noveltyFirstBase,
  // "Start off with competitive+ first until that's exhausted": a
  // tiebreak-sized banding term with a tight shape. Early rounds — when every
  // schedule is equally novel — come out banded and even; as each band's
  // partner combinations run out (three rounds for a band of four), novelty
  // dominance forces mixing. Deliberately a weight/tolerance pair the single
  // `similarSkill` slider cannot express; presets are named profiles and need
  // not live in the slider vocabulary. Dominance holds: 140 + 100 + 0 < 400.
  wSpread: 140.,
  spreadTolerance: 0.25,
}

let randomBalancedWeights = {
  ...noveltyFirstBase,
  // "Random should strictly randomize the matchup": noise at the legacy Random
  // strategy's magnitude, so composition genuinely varies among comparably
  // novel options — while one partner repeat (400) still dominates it, keeping
  // maximum variety intact. Split balance is unaffected: the filter is hard.
  wNoise: 50.,
  // And no favoured/underdog steering — a random mode should not shape who is
  // on which side of a matchup.
  wAlternate: 0.,
  // Who plays whom is random; how they split is balanced. See the field doc.
  splitBalanceFirst: true,
}

let competitivePlusWeights = {
  ...weightsFromConfig({qualityVsVariety: 0.85, advanced: None}),
  // Leveled play rotates in cohorts: the court fills strongest-first among
  // fairness ties, so skill bands play together and take their breaks
  // together instead of individuals alternating out of phase with their band.
  wCohort: maxCohortWeight,
}

let weightsForStrategy = (strategy: strategy): costWeights =>
  switch strategy {
  | Random => randomWeights
  | SolverRoundRobin => roundRobinWeights
  | SolverRandomBalanced => randomBalancedWeights
  | SolverCompetitivePlus => competitivePlusWeights
  | s => weightsFromConfig(presetConfig(s))
  }

// ---------------------------------------------------------------------------
// Persistence
// ---------------------------------------------------------------------------

let advancedToJson = (a: advancedWeights): Js.Json.t => {
  let d = Js.Dict.empty()
  d->Js.Dict.set("partnerVariety", a.partnerVariety->Js.Json.number)
  d->Js.Dict.set("opponentVariety", a.opponentVariety->Js.Json.number)
  d->Js.Dict.set("similarSkill", a.similarSkill->Js.Json.number)
  d->Js.Dict.set("balanceTeams", a.balanceTeams->Js.Json.boolean)
  d->Js.Dict.set("avoidRecentRepeats", a.avoidRecentRepeats->Js.Json.number)
  d->Js.Dict.set("alternateFavored", a.alternateFavored->Js.Json.number)
  d->Js.Json.object_
}

let advancedFromJson = (json: Js.Json.t): option<advancedWeights> =>
  json
  ->Js.Json.decodeObject
  ->Option.map(d => {
    let num = (key, fallback) =>
      d->Js.Dict.get(key)->Option.flatMap(v => v->Js.Json.decodeNumber)->Option.getOr(fallback)
    // Configs stored before spread and balance were separated carried a single
    // coupled "skillBalance"; read it as both halves.
    let legacySkillBalance = num("skillBalance", 0.5)
    {
      partnerVariety: num("partnerVariety", 0.5),
      opponentVariety: num("opponentVariety", 0.5),
      similarSkill: num("similarSkill", legacySkillBalance),
      balanceTeams: d
      ->Js.Dict.get("balanceTeams")
      ->Option.flatMap(v => v->Js.Json.decodeBoolean)
      ->Option.getOr(legacySkillBalance >= 0.2),
      avoidRecentRepeats: num("avoidRecentRepeats", 0.5),
      alternateFavored: num("alternateFavored", 0.1),
    }
  })

let configToJson = (config: uiWeightConfig): Js.Json.t => {
  let d = Js.Dict.empty()
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
  ->Option.flatMap(d =>
    d
    ->Js.Dict.get("qualityVsVariety")
    ->Option.flatMap(v => v->Js.Json.decodeNumber)
    ->Option.map(qualityVsVariety => {
      qualityVsVariety,
      advanced: d->Js.Dict.get("advanced")->Option.flatMap(advancedFromJson),
    })
  )

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
let defaultBeta = 25. /. 6.

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

  {partner, opponent, repeatLast, balance, spread, alternate}
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

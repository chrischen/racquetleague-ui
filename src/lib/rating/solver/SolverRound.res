// Solves one round as a weighted set-partitioning ILP.
//
//   enumerate -> price -> build LP -> solve -> decode
//
// Each round is solved independently; history (partner/opponent repeats, byes,
// favoured/underdog alternation) is folded into the objective coefficients by
// `CostModel`. There is deliberately no multi-round joint optimisation.

open Rating
open SolverTypes

// ---------------------------------------------------------------------------
// Penalty tiers
// ---------------------------------------------------------------------------

type tiers = {
  courtReward: float,
  antiTeamPenalty: float,
  poolPenalty: float,
  genderPenalty: float,
  requiredPenalty: float,
  backToBackBenefit: float,
  regularBudget: float,
}

// The LP carries integer coefficients so that an absolute MIP gap below 1
// proves optimality. Costs and benefits are fractional, though, so they are
// scaled up first: at raw scale, two candidates whose costs differ by less than
// 1 would round to the same coefficient and the solver would pick between them
// arbitrarily. (A round-robin preset's whole balance term can be under 1.)
//
// The scale is kept modest on purpose — see the coefficient-range note in
// `LpBuilder` for why a wide range costs solve time.
let costScale = 100.

// Strict tiers, in decreasing priority:
//
//   fill a court > don't break an avoid rule > don't break a partner pool
//                > keep a mixed round mixed > seat a required player
//                > no back-to-back byes > every regular cost and benefit
//
// Mixed-format sits below pools deliberately: a locked partnership of two men
// can never be mixed, and breaking the lock to satisfy the format would trade
// an explicit per-player promise for a round-level preference.
//
// Each level is derived from the *actual* model — court count, seat count, how
// many violations any single candidate can even carry, and how many of the
// higher-priority rules could not be made hard constraints — and set above the
// total that everything below it can reach. That makes the ordering provable
// rather than hopeful. No user weight setting can reorder it, because
// `CostModel.maxMatchCost` / `maxPlayerBenefit` are exact upper bounds.
//
// In the ordinary case (courts fillable, nobody forced into a back-to-back bye,
// no avoid groups or partner pools) every one of these tiers is vacuous and
// none of them reaches the objective at all.
let deriveTiers = (
  ~weights: CostModel.costWeights,
  ~matchTarget: int,
  ~numSoftRequired: int,
  ~numSoftSatOut: int,
  ~maxPoolViolationsPerMatch: int,
  ~maxAntiViolationsPerMatch: int,
  ~maxGenderViolationsPerMatch: int,
): tiers => {
  let f = Int.toFloat
  let seats = 4 * matchTarget
  // Widest possible span of the regular part of the objective, in scaled units.
  let regularBudget =
    costScale *.
      (f(matchTarget) *. CostModel.maxMatchCost(weights) +.
      f(seats) *. CostModel.maxPlayerBenefit) +. 1.

  let backToBackBenefit = regularBudget
  let throughBackToBack = regularBudget +. f(numSoftSatOut) *. backToBackBenefit

  let requiredPenalty = throughBackToBack +. 1.
  let throughRequired = throughBackToBack +. f(numSoftRequired) *. requiredPenalty

  let genderPenalty = throughRequired +. 1.
  let throughGender =
    throughRequired +. f(matchTarget * maxGenderViolationsPerMatch) *. genderPenalty

  let poolPenalty = throughGender +. 1.
  let throughPool =
    throughGender +. f(matchTarget * maxPoolViolationsPerMatch) *. poolPenalty

  let antiTeamPenalty = throughPool +. 1.
  let throughAnti = throughPool +. f(matchTarget * maxAntiViolationsPerMatch) *. antiTeamPenalty

  {
    courtReward: throughAnti +. 1.,
    antiTeamPenalty,
    poolPenalty,
    genderPenalty,
    requiredPenalty,
    backToBackBenefit,
    regularBudget,
  }
}

// Cheap contract check: the tier derivation is only sound while every cost
// component stays inside its [0, 1] normalisation.
let assertWeightContract = (weights: CostModel.costWeights) => {
  let maxCost = CostModel.maxMatchCost(weights)
  if maxCost > 7. *. CostModel.maxWeight {
    Js.Console.warn(
      "[SolverRound] weight set exceeds its contract (maxMatchCost=" ++
      maxCost->Float.toString ++ "); penalty tiers may be too tight",
    )
  }
}

// ---------------------------------------------------------------------------
// Enumeration (with pruning for large pools)
// ---------------------------------------------------------------------------

// C(n,4)*3 is ~32k candidates at 24 players and ~316k at 40: HiGHS copes with
// the former easily, but writing the LP text for the latter does not. Above the
// threshold we only enumerate quads that fit inside a sliding rating window.
let enumerationThreshold = 28
let initialWindowSize = 12
// Every player must stay placeable after pruning, or the window widens.
let minCandidatesPerPlayer = 20

let candidateCountsByPlayer = (matches: array<Match.t<'a>>): Map.t<string, int> => {
  let counts = Map.make()
  matches->Array.forEach(m =>
    Match.players(m)->Array.forEach(p =>
      counts->Map.set(p.id, counts->Map.get(p.id)->Option.getOr(0) + 1)
    )
  )
  counts
}

let enumerateWindowed = (players: array<Player.t<'a>>, windowSize: int): array<Match.t<'a>> => {
  let seen = Set.make()
  let out = []
  // Windows overlap by one player at a time, so every pair that could plausibly
  // be matched shows up in at least one window.
  players
  ->array_split_by_n(windowSize)
  ->Array.forEach(window =>
    enumerate_match_candidates(window)->Array.forEach(m => {
      let key = m->Match.toPairingId
      if !(seen->Set.has(key)) {
        seen->Set.add(key)
        out->Array.push(m)
      }
    })
  )
  out
}

type enumeration<'a> = {
  matches: array<Match.t<'a>>,
  pruned: bool,
}

let enumerateCandidates = (players: array<Player.t<'a>>): enumeration<'a> => {
  let n = players->Array.length
  if n <= enumerationThreshold {
    {matches: enumerate_match_candidates(players), pruned: false}
  } else {
    let sorted = players->Players.sortByRatingDesc
    let rec widen = (windowSize: int): array<Match.t<'a>> => {
      let matches = enumerateWindowed(sorted, windowSize)
      let counts = candidateCountsByPlayer(matches)
      let everyoneePlaceable =
        sorted->Array.every(p => counts->Map.get(p.id)->Option.getOr(0) >= minCandidatesPerPlayer)
      if everyoneePlaceable || windowSize >= n {
        matches
      } else {
        widen(Js.Math.min_int(n, windowSize * 2))
      }
    }
    let matches = widen(initialWindowSize)
    Js.Console.warn(
      "[SolverRound] pruned enumeration for " ++
      n->Int.toString ++
      " players: " ++
      matches->Array.length->Int.toString ++ " candidates",
    )
    {matches, pruned: true}
  }
}

// ---------------------------------------------------------------------------
// Shortlisting
// ---------------------------------------------------------------------------

// Enumerating C(n,4)x3 candidates is cheap; *solving* over all of them is not.
// The root LP relaxation is where the time goes, and it scales with the column
// count: at 24 players the full 31,878-column model takes seconds, while the
// same model restricted to a few hundred columns solves in ~150ms.
//
// So the model is built from a shortlist: each player's `shortlistSize`
// cheapest candidates, unioned. A match that is expensive for one player is
// almost always still cheap for one of the other three, so the rounds that
// matter survive — measured against full enumeration, the shortlisted model
// reaches the *same* optimal objective at 16, 20, 24 and 32 players.
//
// Two properties keep this honest rather than merely fast:
//   - every player's own cheapest candidates are always present, so nobody can
//     be shortlisted out of a good match;
//   - a greedily built seed round is always included, so the exact-fill model
//     is guaranteed to stay feasible (and to be able to seat every must-play
//     player).
let defaultShortlistSize = 100
// Below this the full model already solves instantly, so keep it exact.
let shortlistThreshold = 1500

// A feasible round, built greedily: must-play players first, then cheapest.
// Guarantees the shortlist can still fill every court.
let seedRound = (
  ~candidates: array<candidate<'a>>,
  ~order: array<int>, // candidate indices, cheapest first
  ~mustPlayIds: array<string>,
  ~target: int,
): array<int> => {
  let used = Set.make()
  let picked = []
  let uncovered = mustPlayIds->Set.fromArray

  let idsOf = i => Match.players((candidates->Array.getUnsafe(i)).match)->Array.map(p => p.id)
  let disjoint = i => idsOf(i)->Array.every(id => !(used->Set.has(id)))
  let take = i => {
    idsOf(i)->Array.forEach(id => {
      used->Set.add(id)
      uncovered->Set.delete(id)->ignore
    })
    picked->Array.push(i)
  }

  // Seat the must-play players first: they are the reason feasibility could
  // otherwise be lost.
  order->Array.forEach(i =>
    if (
      picked->Array.length < target &&
      uncovered->Set.size > 0 &&
      disjoint(i) &&
      idsOf(i)->Array.some(id => uncovered->Set.has(id))
    ) {
      take(i)
    }
  )
  order->Array.forEach(i =>
    if picked->Array.length < target && disjoint(i) {
      take(i)
    }
  )
  picked
}

// Indices to keep, in ascending order.
let shortlistIndices = (
  ~candidates: array<candidate<'a>>,
  ~players: array<Player.t<'a>>,
  ~mustPlayIds: array<string>,
  ~target: int,
  ~size: int,
): array<int> => {
  let total = candidates->Array.length
  if size <= 0 || total <= shortlistThreshold {
    Belt.Array.makeBy(total, i => i)
  } else {
    let cost = i => {
      let c = candidates->Array.getUnsafe(i)
      c.cost +. c.surcharge
    }
    let order = Belt.Array.makeBy(total, i => i)->Array.toSorted((a, b) => cost(a) -. cost(b))

    let keep = Set.make()
    let perPlayer = Map.make()
    players->Array.forEach(p => perPlayer->Map.set(p.id, 0))
    // `order` is cheapest-first, so the first `size` hits for a player are
    // exactly that player's `size` cheapest candidates.
    order->Array.forEach(i =>
      Match.players((candidates->Array.getUnsafe(i)).match)->Array.forEach(p =>
        switch perPlayer->Map.get(p.id) {
        | Some(taken) if taken < size => {
            perPlayer->Map.set(p.id, taken + 1)
            keep->Set.add(i)
          }
        | _ => ()
        }
      )
    )
    seedRound(~candidates, ~order, ~mustPlayIds, ~target)->Array.forEach(i => keep->Set.add(i))

    keep->Set.values->Array.fromIterator->Array.toSorted((a, b) => (a - b)->Int.toFloat)
  }
}

// ---------------------------------------------------------------------------
// Pricing
// ---------------------------------------------------------------------------

// Teams whose pair is not contained in any partner pool.
let poolViolatedTeams = (match: Match.t<'a>, pools: array<Set.t<string>>): array<Team.t<'a>> => {
  let (team1, team2) = match
  [team1, team2]->Array.filter(team => {
    let teamSet = team->Team.toSet
    !(pools->Array.some(pool => pool->TeamSet.containsAllOf(teamSet)))
  })
}

type pricedMatch<'a> = {
  match: Match.t<'a>,
  cost: float,
  violations: array<violation>,
  poolViolationCount: int,
  antiViolationCount: int,
  genderViolationCount: int,
}

// Balanced-or-nothing split selection, for `CostModel.balanceTeams`.
//
// Within a single match, balanced vs unbalanced is a boolean property: a
// foursome has exactly three splits and "balanced" means taking the
// minimum-gap one. So it is enforced here as a hard filter — each foursome
// contributes only its surviving split(s) to the model — rather than priced
// as a weight the objective could trade away. Novelty still decides *which*
// foursomes form; this decides only how each one divides.
//
// Splits rank lexicographically: fewest violations, then fewest repeated
// partnerships, then smallest gap.
//
//   - Violations first: a locked partnership is never broken just because the
//     rule-breaking split would be more even (§5 tier order at foursome level).
//   - Novelty second, and this is load-bearing: with real ratings, "the two
//     strongest together" is almost never a foursome's most balanced split, so
//     a balance-first filter makes such partnerships permanently unreachable —
//     variety starves and round-robin repeats while fresh pairs remain
//     (measured: 23 of 28 pairs on a rated 8-player whist). Balance yields to
//     variety and then breaks ties, which is also the literal reading of
//     "random matchups with maximum variety, each match balanced". For
//     Competitive+ it means each band round-robins internally before pairs
//     repeat — matching that strategy's own description.
let filterToBalancedSplits = (
  priced: array<pricedMatch<'a>>,
  ~history: CostModel.history,
  ~balanceFirst: bool,
): array<pricedMatch<'a>> => {
  let byQuad: Map.t<string, array<pricedMatch<'a>>> = Map.make()
  priced->Array.forEach(p => {
    // Same four players -> same stable id, whatever the split.
    let key = p.match->Match.toStableId
    switch byQuad->Map.get(key) {
    | Some(splits) => splits->Array.push(p)
    | None => byQuad->Map.set(key, [p])
    }
  })

  let gapOf = (p: pricedMatch<'a>) => {
    let (team1, team2) = p.match
    Js.Math.abs_float(CostModel.teamMuSum(team1) -. CostModel.teamMuSum(team2))
  }

  // Times this split's two partnerships have already occurred.
  let repeatsOf = (p: pricedMatch<'a>) => {
    let (team1, team2) = p.match
    let countOf = team =>
      switch team {
      | [a, b] => history.partnerCount->Map.get(CostModel.pairId(a, b))->Option.getOr(0)
      | _ => 0
      }
    countOf(team1) + countOf(team2)
  }

  let out = []
  byQuad->Map.forEach(splits => {
    // Gender counts here too: a 2F+2M foursome's most *balanced* split can be
    // the all-women-vs-all-men one, and in a mixed round the filter must keep
    // the mixed splits instead.
    let violationsOf = (p: pricedMatch<'a>) =>
      p.poolViolationCount + p.antiViolationCount + p.genderViolationCount
    let minViolations =
      splits->Array.reduce(999999, (acc, p) => Js.Math.min_int(acc, violationsOf(p)))
    let eligible = splits->Array.filter(p => violationsOf(p) == minViolations)
    // Random Balanced skips the novelty tier: its promise is the balanced
    // split, and partner variety there is a preference, not a contract.
    let eligible = if balanceFirst {
      eligible
    } else {
      let minRepeats =
        eligible->Array.reduce(999999, (acc, p) => Js.Math.min_int(acc, repeatsOf(p)))
      eligible->Array.filter(p => repeatsOf(p) == minRepeats)
    }
    let minGap = eligible->Array.reduce(infinity, (acc, p) => Js.Math.min_float(acc, gapOf(p)))
    // Ties kept (cold start: every split of every quad ties at 0), so novelty
    // and noise still pick among genuinely equal splits.
    eligible->Array.forEach(p =>
      if gapOf(p) <= minGap +. 0.000001 {
        out->Array.push(p)
      }
    )
  })
  out
}

// ---------------------------------------------------------------------------
// Result
// ---------------------------------------------------------------------------

type solvedMatch<'a> = {
  match: Match.t<'a>,
  // Empty = a clean match. Non-empty = a fallback the solver was forced into to
  // keep the court filled, rendered with a warning badge by the UI.
  fallbackReasons: array<violation>,
}

type roundResult<'a> = {
  matches: array<solvedMatch<'a>>,
  roundViolations: array<violation>,
  byePlayerIds: array<string>,
  status: string,
  objective: float,
  candidateCount: int,
  prunedEnumeration: bool,
  buildMs: float,
  solveMs: float,
}

// Everything up to (but not including) the solve. Exposed so tests can
// brute-force the optimum against the very coefficients the LP carries, and so
// the debug UI can inspect a model without solving it.
type prepared<'a> = {
  model: LpBuilder.lpModel<'a>,
  tiers: tiers,
  benefits: array<float>,
  history: CostModel.history,
  requiredPlayerIds: array<string>,
  // Players the model *requires* to play, as opposed to merely rewarding.
  mustPlayIds: array<string>,
  matchTarget: int,
  pruned: bool,
  buildMs: float,
}

// ---------------------------------------------------------------------------
// Model construction
// ---------------------------------------------------------------------------

let prepare = (
  ~players: array<Player.t<'a>>,
  ~rounds: array<array<completedMatchEntity<'a>>>,
  ~weights: CostModel.costWeights,
  ~numCourts: int,
  ~prng: SolverPrng.t,
  ~avoidAllPlayers: array<array<Player.t<'a>>>=[],
  ~teamConstraints: array<Set.t<string>>=[],
  ~requiredPlayerIds: array<string>=[],
  ~priorityPlayerIds: array<string>=[],
  ~genderMixed: bool=false,
  // Set when the exact-fill model came back infeasible: relaxes the court count
  // to `<=` and pays for filled courts through the objective instead.
  ~relaxFill: bool=false,
  // Columns kept per player; 0 disables shortlisting entirely (used by the test
  // that checks shortlisting does not move the optimum).
  ~shortlistSize: int=defaultShortlistSize,
  (),
): option<prepared<'a>> => {
  let numPlayers = players->Array.length
  if numCourts <= 0 || numPlayers < 4 {
    None
  } else {
    let buildStart = Js.Date.now()
    assertWeightContract(weights)

    let history = CostModel.buildHistory(~rounds, ~players)
    let {matches: enumerated, pruned} = enumerateCandidates(players)

    if enumerated->Array.length == 0 {
      None
    } else {
      let pools = pool_constraint_sets(players, teamConstraints)
      let prioritySet = priorityPlayerIds->Set.fromArray

      // Pass 1: regular cost plus the structural violations each candidate
      // carries. Violating candidates are enumerated rather than filtered out —
      // that is what lets the solver fill a court when nothing clean fits.
      let priced = enumerated->Array.map(match => {
        let noise = weights.wNoise > 0. ? SolverPrng.nextFloat(prng) : 0.
        let cost = costScale *. CostModel.candidateCost(~weights, ~history, ~match, ~noise)

        let violatedPools = poolViolatedTeams(match, pools)
        let violatedGroups = match->match_antiteam_violated_groups(avoidAllPlayers)
        // Gender-mixed is soft, like every other rule (§5): unmixed candidates
        // are admitted with a tier surcharge, so a pool short on women still
        // fills every court — mixing where it can, reporting where it cannot —
        // instead of going infeasible and leaving courts empty.
        let unmixedTeams = genderMixed ? match->match_unmixed_teams : []
        let matchPlayerIds = Match.players(match)->Array.map(p => p.id)->Set.fromArray

        let violations =
          violatedGroups
          ->Array.map(groupIndex => {
            let group = avoidAllPlayers->Array.getUnsafe(groupIndex)
            AntiTeam({
              groupIndex,
              playerIds: group
              ->Array.map(p => p.id)
              ->Array.filter(id => matchPlayerIds->Set.has(id)),
            })
          })
          ->Array.concat(
            violatedPools->Array.map(team => PartnerPool({
              teamPlayerIds: team->Array.map(p => p.id),
            })),
          )
          ->Array.concat(
            unmixedTeams->Array.map(team => NotGenderMixed({
              teamPlayerIds: team->Array.map(p => p.id),
            })),
          )

        {
          match,
          cost,
          violations,
          poolViolationCount: violatedPools->Array.length,
          antiViolationCount: violatedGroups->Array.length,
          genderViolationCount: unmixedTeams->Array.length,
        }
      })

      // Pass 1.5: with team balancing on, each foursome is reduced to its most
      // balanced split before anything else sees the candidates — including
      // the shortlist and the tier derivation below.
      let priced = weights.balanceTeams
        ? filterToBalancedSplits(priced, ~history, ~balanceFirst=weights.splitBalanceFirst)
        : priced

      // Tiers are derived from what the candidate set can actually do, so a
      // session with no avoid groups keeps a tight coefficient range.
      let maxPoolViolationsPerMatch =
        priced->Array.reduce(0, (acc, p) => Js.Math.max_int(acc, p.poolViolationCount))
      let maxAntiViolationsPerMatch =
        priced->Array.reduce(0, (acc, p) => Js.Math.max_int(acc, p.antiViolationCount))
      let maxGenderViolationsPerMatch =
        priced->Array.reduce(0, (acc, p) => Js.Math.max_int(acc, p.genderViolationCount))
      let presentRequiredIds =
        requiredPlayerIds->Array.filter(id => players->Array.some(p => p.id == id))

      // Courts to fill, and therefore seats available. Both are exact under the
      // full enumeration: any k disjoint quads can be drawn from 4k players.
      let matchTarget = Js.Math.min_int(numCourts, numPlayers / 4)
      let seats = 4 * matchTarget

      let satOutIds =
        players->Array.filter(p => history.satOutLastRound->Set.has(p.id))->Array.map(p => p.id)
      let requiredSet = presentRequiredIds->Set.fromArray
      let satOutOnly = satOutIds->Array.filter(id => !(requiredSet->Set.has(id)))

      // Promote as much of the penalty hierarchy as possible into hard
      // constraints. Seating everyone who sat out last round is achievable
      // whenever they fit, and making it a constraint keeps the corresponding
      // tier out of the objective entirely — which is most of why the solve is
      // fast. When the seats do not stretch that far, the rules degrade in
      // priority order: required players stay hard, back-to-back byes go soft
      // (and get reported).
      let (mustPlayIds, softRequiredIds, softSatOutIds) = if relaxFill {
        // Nothing is guaranteed seatable once the court count is relaxed.
        ([], presentRequiredIds, satOutOnly)
      } else if presentRequiredIds->Array.length > seats {
        ([], presentRequiredIds, satOutOnly)
      } else if presentRequiredIds->Array.length + satOutOnly->Array.length <= seats {
        (presentRequiredIds->Array.concat(satOutOnly), [], [])
      } else {
        (presentRequiredIds, [], satOutOnly)
      }
      let tiers = deriveTiers(
        ~weights,
        ~matchTarget,
        ~numSoftRequired=softRequiredIds->Array.length,
        ~numSoftSatOut=softSatOutIds->Array.length,
        ~maxPoolViolationsPerMatch,
        ~maxAntiViolationsPerMatch,
        ~maxGenderViolationsPerMatch,
      )

      // Pass 2: attach the tiered surcharges.
      let allCandidates: array<candidate<'a>> = priced->Array.map(p => {
        match: p.match,
        cost: p.cost,
        surcharge: p.antiViolationCount->Int.toFloat *. tiers.antiTeamPenalty +.
        p.poolViolationCount->Int.toFloat *. tiers.poolPenalty +.
        p.genderViolationCount->Int.toFloat *. tiers.genderPenalty,
        violations: p.violations,
      })

      // Pass 3: shortlist down to the columns worth solving over.
      let candidates =
        shortlistIndices(
          ~candidates=allCandidates,
          ~players,
          ~mustPlayIds,
          ~target=matchTarget,
          ~size=shortlistSize,
        )->Array.map(i => allCandidates->Array.getUnsafe(i))

      // Benefits carry the anti-back-to-back tier only for sat-out players the
      // model could not hard-constrain: since z is binary, a tier-sized benefit
      // is exactly a soft `z = 1`, with no extra variables.
      let softSatOutSet = softSatOutIds->Set.fromArray
      let benefits = players->Array.map(p =>
        costScale *.
        CostModel.playerBenefit(
          ~weights,
          ~history,
          ~player=p,
          ~isPriority=prioritySet->Set.has(p.id),
        ) +. (
          softSatOutSet->Set.has(p.id) ? tiers.backToBackBenefit : 0.
        )
      )

      let model = LpBuilder.build(
        ~candidates,
        ~players,
        ~benefits,
        ~fill=relaxFill
          ? LpBuilder.AtMostFill(matchTarget, tiers.courtReward)
          : LpBuilder.ExactFill(matchTarget),
        ~mustPlayIds,
        ~softRequiredIds,
        ~requiredPenalty=tiers.requiredPenalty,
      )
      Some({
        model,
        tiers,
        benefits,
        history,
        requiredPlayerIds: presentRequiredIds,
        mustPlayIds,
        matchTarget,
        pruned,
        buildMs: Js.Date.now() -. buildStart,
      })
    }
  }
}

// Objective value of an arbitrary selection of candidate indices, using exactly
// the (integer, offset) coefficients the LP carries. Lets the exactness test
// brute-force the optimum for small pools and compare it against HiGHS.
let objectiveOfSelection = (prepared: prepared<'a>, selection: array<int>): float => {
  let {model} = prepared
  let playing = Set.make()
  let costTotal = selection->Array.reduce(0., (acc, i) => {
    let c = model.candidates->Array.getUnsafe(i)
    Match.players(c.match)->Array.forEach(p => playing->Set.add(p.id))
    acc +. Js.Math.round(c.cost +. c.surcharge -. model.costOffset)
  })
  let benefitTotal = model.players->Array.reduceWithIndex(0., (acc, p, j) =>
    playing->Set.has(p.id)
      ? acc +. Js.Math.round(prepared.benefits->Array.getUnsafe(j) -. model.benefitOffset)
      : acc
  )
  let slackTotal = model.softRequiredPlayerIndices->Array.reduce(0., (acc, j) => {
    let player = model.players->Array.getUnsafe(j)
    playing->Set.has(player.id) ? acc : acc +. Js.Math.round(prepared.tiers.requiredPenalty)
  })
  costTotal -. benefitTotal +. slackTotal
}

// ---------------------------------------------------------------------------
// Decoding
// ---------------------------------------------------------------------------

let decode = (
  prepared: prepared<'a>,
  ~selected: array<int>,
  ~status: string,
  ~objective: float,
  ~solveMs: float,
): option<roundResult<'a>> => {
  let {model, history, requiredPlayerIds} = prepared
  let players = model.players

  let playing = Set.make()
  let duplicated = ref(false)
  let solvedMatches = selected->Array.map(i => {
    let c = model.candidates->Array.getUnsafe(i)
    Match.players(c.match)->Array.forEach(p => {
      if playing->Set.has(p.id) {
        duplicated := true
      }
      playing->Set.add(p.id)
    })
    {match: c.match, fallbackReasons: c.violations}
  })

  if duplicated.contents {
    // Only reachable through a malformed model; never ship a round that
    // double-books a player.
    Js.Console.error("[SolverRound] solution double-books a player; discarding")
    None
  } else if solvedMatches->Array.length == 0 {
    // The all-bye assignment is always feasible but never useful.
    None
  } else {
    let byePlayerIds = players->Array.filter(p => !(playing->Set.has(p.id)))->Array.map(p => p.id)

    let unseatedRequired =
      requiredPlayerIds
      ->Array.filter(id => !(playing->Set.has(id)))
      ->Array.map(playerId => RequiredPlayerUnseated({playerId: playerId}))

    let backToBackByes =
      byePlayerIds
      ->Array.filter(id => history.satOutLastRound->Set.has(id))
      ->Array.map(playerId => BackToBackBye({playerId: playerId}))

    Some({
      matches: solvedMatches,
      roundViolations: unseatedRequired->Array.concat(backToBackByes),
      byePlayerIds,
      status,
      objective,
      candidateCount: model.candidates->Array.length,
      prunedEnumeration: prepared.pruned,
      buildMs: prepared.buildMs,
      solveMs,
    })
  }
}

// Court order and team sides carry no cost in the model but are visible in the
// product. Left undisturbed, decoded matches follow candidate enumeration
// order, and every foursome containing the first-listed player enumerates
// before all others — so that player's match lands on court 1 for every seed.
//
// The product default is CourtsByLevel: court 1 is the strongest court,
// descending from there — matching the legacy engine's top-group-first order
// and giving court numbers a meaning. Because the ordering is cosmetic and
// composition varies per seed, this does not pin players: whoever draws the
// strongest foursome tops the board that round. ShuffledCourts (a seeded
// Fisher-Yates, canonical per seed) is kept as an alternative arrangement.
//
// Both keep the seeded per-match side swap, mirroring the greedy engine's
// cosmetic team randomisation.
type courtOrder =
  | ShuffledCourts
  | CourtsByLevel

let matchMuSum = (m: solvedMatch<'a>): float =>
  Match.players(m.match)->Array.reduce(0., (acc, p) => acc +. p.rating.mu)

let arrangeCourts = (
  result: roundResult<'a>,
  ~order: courtOrder,
  ~prng: SolverPrng.t,
): roundResult<'a> => {
  let matches = switch order {
  | ShuffledCourts => {
      let matches = result.matches->Array.copy
      let lastIndex = matches->Array.length - 1
      for i in 0 to lastIndex - 1 {
        let remaining = lastIndex - i + 1
        let j = i + (SolverPrng.nextFloat(prng) *. remaining->Int.toFloat)->Float.toInt
        let held = matches->Array.getUnsafe(i)
        matches->Array.setUnsafe(i, matches->Array.getUnsafe(j))
        matches->Array.setUnsafe(j, held)
      }
      matches
    }
  | CourtsByLevel => result.matches->Array.toSorted((a, b) => matchMuSum(b) -. matchMuSum(a))
  }
  let matches = matches->Array.map(m =>
    if SolverPrng.nextFloat(prng) < 0.5 {
      let (team1, team2) = m.match
      {...m, match: (team2, team1)}
    } else {
      m
    }
  )
  {...result, matches}
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

// `None` means "the solver could not produce a usable round" — unavailable
// wasm, a failed or empty solve, or a pool too small to seat anyone. Callers
// fall through to the greedy path unchanged.
let generateRound = async (
  ~players: array<Player.t<'a>>,
  ~rounds: array<array<completedMatchEntity<'a>>>,
  ~weights: CostModel.costWeights,
  ~numCourts: int,
  ~prng: SolverPrng.t,
  ~avoidAllPlayers: array<array<Player.t<'a>>>=[],
  ~teamConstraints: array<Set.t<string>>=[],
  ~requiredPlayerIds: array<string>=[],
  ~priorityPlayerIds: array<string>=[],
  ~genderMixed: bool=false,
  ~timeLimit: float=1.0,
  ~highs: option<HighsBindings.highs>=?,
  // Placed after ~highs so existing positional callers stay aligned.
  ~courtOrder: courtOrder=CourtsByLevel,
  (),
): option<roundResult<'a>> => {
  let solver = switch highs {
  | Some(h) => Some(h)
  | None => await HighsBindings.load()
  }

  switch solver {
  | None => None
  | Some(h) =>
    let seed = (SolverPrng.nextFloat(prng) *. 2147483000.)->Float.toInt
    let options = HighsBindings.defaultOptions(~timeLimit, ~seed)

    // The exact-fill model asserts that every court can be filled. That holds
    // for the full enumeration, but a pruned candidate set can make it false —
    // in which case the solver says "Infeasible" and we rebuild once with the
    // court count relaxed.
    let attempt = async (~relaxFill) =>
      switch prepare(
        ~players,
        ~rounds,
        ~weights,
        ~numCourts,
        ~prng=SolverPrng.make(seed),
        ~avoidAllPlayers,
        ~teamConstraints,
        ~requiredPlayerIds,
        ~priorityPlayerIds,
        ~genderMixed,
        ~relaxFill,
        (),
      ) {
      | None => None
      | Some(prepared) =>
        let solveStart = Js.Date.now()
        // Awaited: on the worker backend this is where the main thread is
        // handed back for the duration of the solve.
        let solved = await HighsBindings.solve(h, prepared.model.lp, options)
        let solveMs = Js.Date.now() -. solveStart
        Some((prepared, solved, solveMs))
      }

    let decodeAttempt = ((prepared, solved, solveMs)) =>
      switch solved {
      | None => None
      | Some((result: HighsBindings.solveResult)) if !HighsBindings.isUsableStatus(result.status) =>
        None
      | Some((result: HighsBindings.solveResult)) =>
        prepared->decode(
          ~selected=LpBuilder.selectedCandidateIndices(prepared.model, result.columns),
          ~status=result.status,
          ~objective=result.objectiveValue,
          ~solveMs,
        )
      }

    let decoded = switch await attempt(~relaxFill=false) {
    | None => None
    | Some((_, Some(result), _)) if result.status == "Infeasible" =>
      (await attempt(~relaxFill=true))->Option.flatMap(decodeAttempt)
    | Some(first) =>
      switch decodeAttempt(first) {
      | Some(result) => Some(result)
      | None =>
        let (_, solved, _) = first
        switch solved {
        | Some(result) => Js.Console.warn("[SolverRound] unusable solve status: " ++ result.status)
        | None => ()
        }
        None
      }
    }
    // `prng` has advanced exactly one draw (the solve seed) regardless of which
    // attempt succeeded, so the arrangement stream is deterministic per seed.
    decoded->Option.map(result => result->arrangeCourts(~order=courtOrder, ~prng))
  }
}

// Metrics for judging whether a *session* came out well, rather than whether a
// single round was optimal.
//
// Shared between the simulated-session tests and the round-summary line in the
// UI, so the numbers a developer tunes against are the numbers a user sees.

open Rating

// ---------------------------------------------------------------------------
// Per match
// ---------------------------------------------------------------------------

type matchMetrics = {
  muGap: float, // |sum mu team1 - sum mu team2|
  spread: float, // widest mu difference among the four players
  duprGap: float, // muGap expressed in DUPR points
  isEven: bool, // inside the favoured/underdog dead zone
}

// mu -> DUPR is linear (see `guessDupr`), so a *difference* in mu converts with
// the slope alone.
let muToDuprDelta = (deltaMu: float): float => guessDupr(25. +. deltaMu) -. guessDupr(25.)

let forMatch = (match: Match.t<'a>): matchMetrics => {
  let (team1, team2) = match
  let players = Match.players(match)
  let mus = players->Array.map(p => p.rating.mu)
  let maxMu = mus->Array.reduce(neg_infinity, (a, b) => Js.Math.max_float(a, b))
  let minMu = mus->Array.reduce(infinity, (a, b) => Js.Math.min_float(a, b))
  let muGap = Js.Math.abs_float(CostModel.teamMuSum(team1) -. CostModel.teamMuSum(team2))
  let (side1, _) = CostModel.matchSides(match)
  {
    muGap,
    spread: maxMu -. minMu,
    duprGap: muToDuprDelta(muGap),
    isEven: side1 == CostModel.Even,
  }
}

let mean = (values: array<float>): float =>
  values->Array.length == 0
    ? 0.
    : values->Array.reduce(0., (a, b) => a +. b) /. values->Array.length->Int.toFloat

// ---------------------------------------------------------------------------
// Per round (the optional summary line under a generated round)
// ---------------------------------------------------------------------------

type roundSummary = {
  repeatedPartnerships: int, // teams that have partnered before
  repeatedOpponents: int, // cross pairs that have met before
  meanMuGap: float,
  meanDuprGap: float,
  meanSpread: float,
}

let summarizeRound = (
  ~round: array<completedMatchEntity<'a>>,
  ~history: CostModel.history,
): roundSummary => {
  let metrics = round->Array.map(({match}) => forMatch(match))

  let repeatedPartnerships = round->Array.reduce(0, (acc, {match}) => {
    let (team1, team2) = match
    acc +
    [team1, team2]->Array.reduce(0, (inner, team) =>
      inner +
      array_combos(team)->Array.reduce(0, (n, (p1, p2)) =>
        history.partnerCount->Map.get(CostModel.pairId(p1, p2))->Option.getOr(0) > 0
          ? n + 1
          : n
      )
    )
  })

  let repeatedOpponents = round->Array.reduce(0, (acc, {match}) =>
    acc +
    noveltyOpponentPairIds(match)->Array.reduce(0, (n, id) =>
      history.opponentCount->Map.get(id)->Option.getOr(0) > 0 ? n + 1 : n
    )
  )

  {
    repeatedPartnerships,
    repeatedOpponents,
    meanMuGap: metrics->Array.map(m => m.muGap)->mean,
    meanDuprGap: metrics->Array.map(m => m.duprGap)->mean,
    meanSpread: metrics->Array.map(m => m.spread)->mean,
  }
}

// ---------------------------------------------------------------------------
// Per session
// ---------------------------------------------------------------------------

type sessionMetrics = {
  gamesPlayed: Map.t<string, int>,
  minGames: int,
  maxGames: int,
  // Partnerships formed more than once, counted as excess (a pair seen 3 times
  // contributes 2).
  excessPartnerRepeats: int,
  maxPartnerRepeat: int,
  // Mean fraction of the rest of the pool each player has faced.
  opponentCoverage: float,
  // Players given a bye in two consecutive rounds, summed over the session.
  backToBackByes: int,
  meanMuGap: float,
  meanSpread: float,
  meanDuprGap: float,
  evenMatchFraction: float,
  // Of the consecutive played-match pairs where both matches had a meaningful
  // favourite, the fraction where the player switched sides.
  alternationRate: float,
  alternationOpportunities: int,
}

let analyze = (
  ~rounds: array<array<completedMatchEntity<'a>>>,
  ~players: array<Player.t<'a>>,
): sessionMetrics => {
  let gamesPlayed = Map.make()
  let partnerCount = Map.make()
  let opponents = Map.make() // playerId -> Set of opponent ids
  let sidesByPlayer = Map.make() // playerId -> chronological sides
  let allMetrics = []
  let playedByRound = []

  players->Array.forEach(p => {
    gamesPlayed->Map.set(p.id, 0)
    opponents->Map.set(p.id, Set.make())
    sidesByPlayer->Map.set(p.id, [])
  })

  rounds->Array.forEach(round => {
    let played = Set.make()
    round->Array.forEach(({match}) => {
      let (team1, team2) = match
      allMetrics->Array.push(forMatch(match))

      [team1, team2]->Array.forEach(team =>
        array_combos(team)->Array.forEach(((p1, p2)) => {
          let key = CostModel.pairId(p1, p2)
          partnerCount->Map.set(key, partnerCount->Map.get(key)->Option.getOr(0) + 1)
        })
      )

      team1->Array.forEach(a =>
        team2->Array.forEach(b => {
          opponents->Map.get(a.id)->Option.forEach(s => s->Set.add(b.id))
          opponents->Map.get(b.id)->Option.forEach(s => s->Set.add(a.id))
        })
      )

      let (side1, side2) = CostModel.matchSides(match)
      team1->Array.forEach(p => sidesByPlayer->Map.get(p.id)->Option.forEach(a => a->Array.push(side1)))
      team2->Array.forEach(p => sidesByPlayer->Map.get(p.id)->Option.forEach(a => a->Array.push(side2)))

      Match.players(match)->Array.forEach(p => {
        played->Set.add(p.id)
        gamesPlayed->Map.set(p.id, gamesPlayed->Map.get(p.id)->Option.getOr(0) + 1)
      })
    })
    playedByRound->Array.push(played)
  })

  let counts = players->Array.map(p => gamesPlayed->Map.get(p.id)->Option.getOr(0))
  let minGames =
    counts->Array.reduce(counts->Array.get(0)->Option.getOr(0), (a, b) => Js.Math.min_int(a, b))
  let maxGames = counts->Array.reduce(0, (a, b) => Js.Math.max_int(a, b))

  let partnerCounts = partnerCount->Map.values->Array.fromIterator
  let excessPartnerRepeats =
    partnerCounts->Array.reduce(0, (acc, c) => acc + (c > 1 ? c - 1 : 0))
  let maxPartnerRepeat = partnerCounts->Array.reduce(0, (a, b) => Js.Math.max_int(a, b))

  let poolSize = players->Array.length
  let opponentCoverage = poolSize <= 1
    ? 0.
    : players
      ->Array.map(p =>
        opponents->Map.get(p.id)->Option.mapOr(0, s => s->Set.size)->Int.toFloat /.
          (poolSize - 1)->Int.toFloat
      )
      ->mean

  let backToBackByes = ref(0)
  playedByRound->Array.forEachWithIndex((played, index) =>
    if index > 0 {
      let previous = playedByRound->Array.getUnsafe(index - 1)
      players->Array.forEach(p =>
        if !(played->Set.has(p.id)) && !(previous->Set.has(p.id)) {
          backToBackByes := backToBackByes.contents + 1
        }
      )
    }
  )

  // Alternation only means something between two matches that both had a
  // favourite; dead-zone matches are skipped rather than counted as failures.
  let (alternations, opportunities) = players->Array.reduce((0, 0), ((alt, opp), p) => {
    let sides = sidesByPlayer->Map.get(p.id)->Option.getOr([])
    let meaningful = sides->Array.filter(s => s != CostModel.Even)
    meaningful->Array.reduceWithIndex((alt, opp), ((a, o), side, index) =>
      if index == 0 {
        (a, o)
      } else {
        let previous = meaningful->Array.getUnsafe(index - 1)
        (side != previous ? a + 1 : a, o + 1)
      }
    )
  })

  {
    gamesPlayed,
    minGames,
    maxGames,
    excessPartnerRepeats,
    maxPartnerRepeat,
    opponentCoverage,
    backToBackByes: backToBackByes.contents,
    meanMuGap: allMetrics->Array.map(m => m.muGap)->mean,
    meanSpread: allMetrics->Array.map(m => m.spread)->mean,
    meanDuprGap: allMetrics->Array.map(m => m.duprGap)->mean,
    evenMatchFraction: allMetrics->Array.length == 0
      ? 0.
      : allMetrics->Array.filter(m => m.isEven)->Array.length->Int.toFloat /.
          allMetrics->Array.length->Int.toFloat,
    alternationRate: opportunities == 0 ? 1. : alternations->Int.toFloat /. opportunities->Int.toFloat,
    alternationOpportunities: opportunities,
  }
}

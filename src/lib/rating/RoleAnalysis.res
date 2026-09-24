// Per-player role analysis for the matchmaking lab.
//
// Answers "which side of their matches was this player on, how often, in what
// streaks, with which partners — and how wrong did their rating end up?" from
// a lab run's recorded games and frames. Pure and read-only: used by the
// role-probe experiment (scripts/role-probe.ts) and its tests, never by the UI.
//
// Conventions shared with `SimLab.makeFrame`:
// - frames[k] is the state after round k and is what the matchmaker used to
//   build round k + 1; frame k is graded against truth at round k - 1.
// - In a game record, playerIndices[0..1] is team 1 and [2..3] is team 2, and
//   predictedWinProb is team 1's. Orientation is random, so a player's side is
//   always read from their seat.

open Rating

type side =
  | Favored
  | Unfavored
  | Even

type sideMode =
  // Even when own win probability is within this distance of 0.5.
  | WinProb(float)
  // The matchmaker's own definition (`CostModel.matchSides`), recomputed from
  // the ratings the round was built with.
  | CostModelExact

let seatOf = (g: SimLab.gameRecord, ~intId: int): option<int> =>
  switch g.playerIndices->Array.indexOf(intId) {
  | -1 => None
  | i => Some(i < 2 ? 0 : 1)
  }

let ownWinProb = (g: SimLab.gameRecord, ~intId: int): option<float> =>
  seatOf(g, ~intId)->Option.map(team =>
    team == 0 ? g.predictedWinProb : 1.0 -. g.predictedWinProb
  )

let ownWon = (g: SimLab.gameRecord, ~intId: int): option<bool> =>
  seatOf(g, ~intId)->Option.map(team =>
    team == 0 ? g.team1Score > g.team2Score : g.team2Score > g.team1Score
  )

let partnerOf = (g: SimLab.gameRecord, ~intId: int): option<int> =>
  switch g.playerIndices->Array.indexOf(intId) {
  | -1 => None
  | i => g.playerIndices->Array.get(i < 2 ? 1 - i : 5 - i)
  }

let opponentsOf = (g: SimLab.gameRecord, ~intId: int): array<int> =>
  switch seatOf(g, ~intId) {
  | Some(0) => g.playerIndices->Array.slice(~start=2, ~end=4)
  | Some(_) => g.playerIndices->Array.slice(~start=0, ~end=2)
  | None => []
  }

let sideOf = (~ownWinProb: float, ~band: float): side =>
  if Js.Math.abs_float(ownWinProb -. 0.5) <= band {
    Even
  } else if ownWinProb > 0.5 {
    Favored
  } else {
    Unfavored
  }

// `CostModel.matchSides` for one player, from the ratings before the round.
let costModelSide = (
  g: SimLab.gameRecord,
  ~intId: int,
  ~muBefore: array<float>,
  ~sigmaBefore: array<float>,
): side =>
  switch seatOf(g, ~intId) {
  | None => Even
  | Some(team) =>
    let mu = i => muBefore->Array.get(i)->Option.getOr(25.0)
    let sd = i => sigmaBefore->Array.get(i)->Option.getOr(25.0 /. 3.0)
    let ids = g.playerIndices
    let sumOf = (from, to_) =>
      ids->Array.slice(~start=from, ~end=to_)->Array.reduce(0.0, (a, i) => a +. mu(i))
    let gap1 = sumOf(0, 2) -. sumOf(2, 4)
    let gap = team == 0 ? gap1 : -.gap1
    let beta = CostModel.defaultBeta
    let c2 = ids->Array.reduce(0.0, (a, i) => a +. sd(i) *. sd(i) +. beta *. beta)
    let epsilon = CostModel.evenZ *. Js.Math.sqrt(c2)
    if Js.Math.abs_float(gap) < epsilon {
      Even
    } else if gap > 0.0 {
      Favored
    } else {
      Unfavored
    }
  }

let truthForFrame = (r: SimLab.labResult, f: SimLab.frame): array<float> =>
  SimLab.truthAt(~base=r.truth, ~roles=r.driftRoles, ~round=Js.Math.max_int(0, f.round - 1))

// Rank position minus true rank position, per player. Positive = overrated.
// Empty when the frame carries no ratings (trimmed archive detail).
let signedRankErrors = (r: SimLab.labResult, f: SimLab.frame): array<int> => {
  let truth = truthForFrame(r, f)
  if f.mu->Array.length != truth->Array.length {
    []
  } else {
    let rv = SimLab.ranksOf(f.mu)
    let rt = SimLab.ranksOf(truth)
    rv->Array.mapWithIndex((v, i) => v - rt->Array.getUnsafe(i))
  }
}

// Rating minus truth, both centred on the regular players' mean, in mu units.
// Positive = rated above where they belong relative to the club. Drop-ins are
// left out of the centre: they sit at the unrated default while away, which
// would drag everyone else's error around.
let signedMuErrors = (r: SimLab.labResult, f: SimLab.frame): array<float> => {
  let truth = truthForFrame(r, f)
  if f.mu->Array.length != truth->Array.length {
    []
  } else {
    let regular = i => !(r.dropIns->Array.get(i)->Option.getOr(false))
    let centre = (xs: array<float>) => {
      let total = ref(0.0)
      let count = ref(0)
      xs->Array.forEachWithIndex((v, i) =>
        if regular(i) {
          total := total.contents +. v
          count := count.contents + 1
        }
      )
      count.contents == 0 ? 0.0 : total.contents /. Float.fromInt(count.contents)
    }
    let muCentre = centre(f.mu)
    let truthCentre = centre(truth)
    f.mu->Array.mapWithIndex((m, i) => m -. muCentre -. (truth->Array.getUnsafe(i) -. truthCentre))
  }
}

// Inclusive, 1-based rounds; frames[k] is round k.
type window = {fromRound: int, toRound: int}

type playerRole = {
  intId: int,
  // At toRound, 0 = weakest.
  trueRank: int,
  trueRankQuantile: float,
  isDropIn: bool,
  gamesPlayed: int,
  wins: int,
  winRate: option<float>,
  // Mean own predicted win probability: with winRate, the calibration gap.
  meanOwnWinProb: option<float>,
  // Share of games with own win probability above 0.5.
  favoredShare: option<float>,
  // Games outside the Even band, and the favored share among them.
  meaningfulGames: int,
  meaningfulFavoredShare: option<float>,
  // Mean |own win probability - 0.5|: how much a typical game could teach.
  meanEdge: option<float>,
  // Over the chronological non-Even sides.
  maxRoleStreak: int,
  alternations: int,
  alternationOpportunities: int,
  alternationRate: option<float>,
  distinctPartners: int,
  // Mean truth[partner] - truth[self] and mean(truth[opponents]) - truth[self].
  partnerAdvantage: option<float>,
  opponentAdvantage: option<float>,
  // At toRound. None when the frame carries no ratings.
  signedRankError: option<int>,
  absRankError: option<int>,
  meanAbsRankError: option<float>,
  signedMuError: option<float>,
  finalSigma: option<float>,
}

let mean = (xs: array<float>): option<float> =>
  xs->Array.length == 0
    ? None
    : Some(xs->Array.reduce(0.0, (a, b) => a +. b) /. Float.fromInt(xs->Array.length))

let framesIn = (run: SimLab.strategyRun, ~window: window): array<SimLab.frame> => {
  let last = run.frames->Array.length - 1
  let from = Js.Math.max_int(1, window.fromRound)
  let to_ = Js.Math.min_int(last, window.toRound)
  from > to_ ? [] : run.frames->Array.slice(~start=from, ~end=to_ + 1)
}

let playerRole = (
  r: SimLab.labResult,
  ~strategyIndex: int,
  ~window: window,
  ~sideMode: sideMode=WinProb(0.05),
  ~intId: int,
): playerRole => {
  let run = r.runs->Array.getUnsafe(strategyIndex)
  let frames = framesIn(run, ~window)
  let probs = []
  let won = ref(0)
  let sides = []
  let partners = Set.make()
  let partnerDeltas = []
  let opponentDeltas = []
  frames->Array.forEach(f => {
    let truth = truthForFrame(r, f)
    let t = i => truth->Array.get(i)->Option.getOr(0.0)
    f.games->Array.forEach(g =>
      switch ownWinProb(g, ~intId) {
      | None => ()
      | Some(p) =>
        probs->Array.push(p)
        if ownWon(g, ~intId)->Option.getOr(false) {
          won := won.contents + 1
        }
        let side = switch sideMode {
        | WinProb(band) => sideOf(~ownWinProb=p, ~band)
        | CostModelExact =>
          let before = run.frames->Array.get(f.round - 1)
          costModelSide(
            g,
            ~intId,
            ~muBefore=before->Option.map(b => b.mu)->Option.getOr([]),
            ~sigmaBefore=before->Option.map(b => b.sigma)->Option.getOr([]),
          )
        }
        sides->Array.push(side)
        switch partnerOf(g, ~intId) {
        | Some(partner) =>
          partners->Set.add(partner)
          partnerDeltas->Array.push(t(partner) -. t(intId))
        | None => ()
        }
        switch opponentsOf(g, ~intId)->Array.map(t)->mean {
        | Some(m) => opponentDeltas->Array.push(m -. t(intId))
        | None => ()
        }
      }
    )
  })
  let played = probs->Array.length
  let meaningful = sides->Array.filter(s => s != Even)
  let favoredMeaningful = meaningful->Array.filter(s => s == Favored)->Array.length
  // Streaks and alternation over the sided games only: an Even game neither
  // breaks a streak nor is a chance to switch.
  let maxStreak = ref(0)
  let streak = ref(0)
  let alternations = ref(0)
  meaningful->Array.forEachWithIndex((s, i) => {
    switch meaningful->Array.get(i - 1) {
    | Some(prev) if prev == s => streak := streak.contents + 1
    | Some(_) =>
      alternations := alternations.contents + 1
      streak := 1
    | None => streak := 1
    }
    if streak.contents > maxStreak.contents {
      maxStreak := streak.contents
    }
  })
  let opportunities = Js.Math.max_int(0, meaningful->Array.length - 1)
  let n = r.truth->Array.length
  let endFrame = frames->Array.get(frames->Array.length - 1)
  let endTruth = switch endFrame {
  | Some(f) => truthForFrame(r, f)
  | None => SimLab.truthAt(~base=r.truth, ~roles=r.driftRoles, ~round=0)
  }
  let trueRank = SimLab.ranksOf(endTruth)->Array.get(intId)->Option.getOr(0)
  let signedRank =
    endFrame->Option.flatMap(f => signedRankErrors(r, f)->Array.get(intId))
  {
    intId,
    trueRank,
    trueRankQuantile: n <= 1 ? 0.0 : Float.fromInt(trueRank) /. Float.fromInt(n - 1),
    isDropIn: r.dropIns->Array.get(intId)->Option.getOr(false),
    gamesPlayed: played,
    wins: won.contents,
    winRate: played == 0 ? None : Some(Float.fromInt(won.contents) /. Float.fromInt(played)),
    meanOwnWinProb: mean(probs),
    favoredShare: played == 0
      ? None
      : Some(
          Float.fromInt(probs->Array.filter(p => p > 0.5)->Array.length) /. Float.fromInt(played),
        ),
    meaningfulGames: meaningful->Array.length,
    meaningfulFavoredShare: meaningful->Array.length == 0
      ? None
      : Some(Float.fromInt(favoredMeaningful) /. Float.fromInt(meaningful->Array.length)),
    meanEdge: mean(probs->Array.map(p => Js.Math.abs_float(p -. 0.5))),
    maxRoleStreak: maxStreak.contents,
    alternations: alternations.contents,
    alternationOpportunities: opportunities,
    alternationRate: opportunities == 0
      ? None
      : Some(Float.fromInt(alternations.contents) /. Float.fromInt(opportunities)),
    distinctPartners: partners->Set.size,
    partnerAdvantage: mean(partnerDeltas),
    opponentAdvantage: mean(opponentDeltas),
    signedRankError: signedRank,
    absRankError: signedRank->Option.map(e => e < 0 ? -e : e),
    meanAbsRankError: frames
    ->Array.filterMap(f =>
      signedRankErrors(r, f)->Array.get(intId)->Option.map(e => Float.fromInt(e < 0 ? -e : e))
    )
    ->mean,
    signedMuError: endFrame->Option.flatMap(f => signedMuErrors(r, f)->Array.get(intId)),
    finalSigma: endFrame->Option.flatMap(f => f.sigma->Array.get(intId)),
  }
}

// The player's side in every game they played in the window, in order. The
// raw material for streak analysis: `playerRole` summarises the same
// sequence.
let sideSequence = (
  r: SimLab.labResult,
  ~strategyIndex: int,
  ~window: window,
  ~sideMode: sideMode=WinProb(0.05),
  ~intId: int,
): array<side> => {
  let run = r.runs->Array.getUnsafe(strategyIndex)
  framesIn(run, ~window)->Array.flatMap(f =>
    f.games->Array.filterMap(g =>
      ownWinProb(g, ~intId)->Option.map(p =>
        switch sideMode {
        | WinProb(band) => sideOf(~ownWinProb=p, ~band)
        | CostModelExact =>
          let before = run.frames->Array.get(f.round - 1)
          costModelSide(
            g,
            ~intId,
            ~muBefore=before->Option.map(b => b.mu)->Option.getOr([]),
            ~sigmaBefore=before->Option.map(b => b.sigma)->Option.getOr([]),
          )
        }
      )
    )
  )
}

let playerRoles = (
  r: SimLab.labResult,
  ~strategyIndex: int,
  ~window: window,
  ~sideMode: sideMode=WinProb(0.05),
): array<playerRole> =>
  Belt.Array.makeBy(r.truth->Array.length, intId =>
    playerRole(r, ~strategyIndex, ~window, ~sideMode, ~intId)
  )

// How often a probe could and did hold its player to the target, rebuilt from
// the record: every split of each of the player's foursomes is re-scored from
// the ratings the round was built with.
type probeOutcome = {
  played: int,
  // Games where at least one split met the target.
  achievable: int,
  // Games actually played on the target side.
  achieved: int,
  meanEdge: option<float>,
}

let probeOutcome = (
  r: SimLab.labResult,
  ~strategyIndex: int,
  ~probe: SimLab.roleProbe,
): probeOutcome => {
  let run = r.runs->Array.getUnsafe(strategyIndex)
  let intId = probe.playerIntId
  let played = ref(0)
  let achievable = ref(0)
  let achieved = ref(0)
  let edges = []
  let last = ref(None)
  run.frames->Array.forEach(f =>
    switch (run.frames->Array.get(f.round - 1), f.round > 0) {
    | (Some(before), true) =>
      let rating = i =>
        Rating.make(
          before.mu->Array.get(i)->Option.getOr(25.0),
          before.sigma->Array.get(i)->Option.getOr(25.0 /. 3.0),
        )
      f.games->Array.forEach(g =>
        switch ownWinProb(g, ~intId) {
        | None => ()
        | Some(p) =>
          played := played.contents + 1
          edges->Array.push(Js.Math.abs_float(p -. 0.5))
          let others = g.playerIndices->Array.filter(i => i != intId)
          let possible = others->Array.someWithIndex((partner, k) => {
            let rest = others->Array.filterWithIndex((_, j) => j != k)
            let own =
              Rating.predictWin([[rating(intId), rating(partner)], rest->Array.map(rating)])
              ->Array.get(0)
              ->Option.getOr(0.5)
              ->SimLab.clampProb
            SimLab.probeAchieves(~probe, ~ownWinProb=own, ~lastOwnWinProb=last.contents)
          })
          if possible {
            achievable := achievable.contents + 1
          }
          if SimLab.probeAchieves(~probe, ~ownWinProb=p, ~lastOwnWinProb=last.contents) {
            achieved := achieved.contents + 1
          }
          if Js.Math.abs_float(p -. 0.5) > probe.margin {
            last := Some(p)
          }
        }
      )
    | _ => ()
    }
  )
  {
    played: played.contents,
    achievable: achievable.contents,
    achieved: achieved.contents,
    meanEdge: mean(edges),
  }
}

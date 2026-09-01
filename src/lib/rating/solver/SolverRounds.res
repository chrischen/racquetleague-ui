// Async multi-round generation: the solver-aware counterpart to
// `Rating.generateRounds`.
//
// Why it lives here rather than inside `Rating.generateRoundsRec`: the solver
// modules depend on `Rating` for `Player` / `Match` / `strategy`, so having
// `Rating` call back into them would be a module cycle. Instead `Rating` keeps
// the synchronous greedy engine (still directly callable, and still the
// fallback and A/B baseline), and this module dispatches:
//
//   solver strategy + wasm available  -> ILP round, byes decided by the model
//   anything else, or a failed solve  -> the legacy greedy path, unchanged

open Rating

@module("../../uuid") external randomUUID: unit => string = "randomUUID"

// Bound here because the solver-aware `generateRounds` below shadows the one
// `open Rating` brought in, and the two are easy to confuse at the call site.
let greedyGenerateRounds = generateRounds

// Hand the main thread back to the browser for one frame.
//
// This has to be a *macrotask*: the HiGHS solve is synchronous wasm, so a
// ten-round generation is one long block on the main thread. Awaiting an
// already-resolved promise only queues a microtask, and microtasks run before
// the browser paints — so React would commit the "generating" spinner and the
// user would never see it. (It appeared on the very first generation only
// because the wasm download genuinely suspended.) Yielding per round also keeps
// the page responsive while a draw is being built.
let yieldToBrowser: unit => promise<unit> = %raw(`function () {
  return new Promise(function (resolve) { setTimeout(resolve, 0); });
}`)

// Resolve only once the browser has actually painted the pending frame.
//
// Stronger than `yieldToBrowser`, and needed at the *start* of a generation:
// React commits the state change that triggered it (a recorded score, a spinner
// appearing) but a macrotask can still be picked up before the frame is drawn,
// so the user sees their click take effect only once the solver has finished.
// requestAnimationFrame runs just before paint, so a timeout nested inside it
// lands just after.
let afterPaint: unit => promise<unit> = %raw(`function () {
  if (typeof requestAnimationFrame !== "function") {
    return new Promise(function (resolve) { setTimeout(resolve, 0); });
  }
  return new Promise(function (resolve) {
    requestAnimationFrame(function () { setTimeout(resolve, 0); });
  });
}`)

type roundOutcome<'a> = {
  matches: array<completedMatchEntity<'a>>,
  // Keyed by match entity id. Non-empty means the solver was forced into a
  // rule-breaking match to keep the court filled; the UI badges those.
  matchViolations: Js.Dict.t<array<SolverTypes.violation>>,
  roundViolations: array<SolverTypes.violation>,
  byePlayerIds: array<string>,
  usedSolver: bool,
}

type sessionResult<'a> = {
  rounds: array<roundOutcome<'a>>,
  // True when a solver strategy was asked for but at least one round had to
  // fall back — the UI shows a dismissible "optimizer unavailable" notice.
  fellBackToGreedy: bool,
}

let emptyOutcome = (matches): roundOutcome<'a> => {
  matches,
  matchViolations: Js.Dict.empty(),
  roundViolations: [],
  byePlayerIds: [],
  usedSolver: false,
}

// Effective weights: the strategy's preset, overridden by any stored user
// configuration. Presets stay in code so retuning them applies retroactively.
// Competitive+ is the one preset that reads the pool: its profile is a live
// blend out of the calibration profile as the players' ratings settle.
let effectiveWeights = (
  ~strategy: strategy,
  ~weightConfig: option<CostModel.uiWeightConfig>,
  ~players: array<Player.t<'a>>,
  ~numCourts: int,
): CostModel.costWeights => {
  let base = switch (weightConfig, strategy) {
  | (Some(config), _) => CostModel.weightsFromConfig(config)
  | (None, SolverCompetitivePlus) => CostModel.adaptiveWeights(players)
  | (None, _) => CostModel.weightsForStrategy(strategy)
  }
  // Pool-aware split policy (see `SolverRound.splitBalanceIsFree`): in a roomy
  // pool the most even split is available for free, so the banded quality
  // modes take it and roughly halve their blowout rate.
  //
  // Round Robin is excluded on purpose — its unbalanced splits ARE its
  // recovery from rating-aligned error, and trading them for quality would
  // silently retire the operator remedy. A custom config is excluded too: an
  // explicit "Balanced, fresh partners first" choice must mean what it says.
  let mayUpgrade = switch (weightConfig, strategy) {
  | (None, SolverCompetitivePlusStatic | SolverCompetitivePlus) => true
  | _ => false
  }
  mayUpgrade &&
  !base.splitBalanceFirst &&
  SolverRound.splitBalanceIsFree(~numPlayers=players->Array.length, ~numCourts)
    ? {...base, splitBalanceFirst: true}
    : base
}

// Same 10-minute stagger `Rating.generateRoundsRec` applies.
let roundCreatedAt = (~startTime: Js.Date.t, ~roundIndex: int): Js.Date.t => {
  let minutesOffset = Float.fromInt(roundIndex + 1) *. 10.0 *. 60.0 *. 1000.0
  Js.Date.fromFloat(startTime->Js.Date.getTime +. minutesOffset)
}

let toEntities = (
  ~matches: array<SolverRound.solvedMatch<'a>>,
  ~createdAt: Js.Date.t,
): (array<completedMatchEntity<'a>>, Js.Dict.t<array<SolverTypes.violation>>) => {
  let violations = Js.Dict.empty()
  let entities = matches->Array.map(({match, fallbackReasons}) => {
    let id = randomUUID()
    if fallbackReasons->Array.length > 0 {
      violations->Js.Dict.set(id, fallbackReasons)
    }
    let entity: CompletedMatchEntity.t<'a> = {
      id,
      // The greedy engine stores each match with `incrementPlayCounts` applied,
      // so the embedded players count the current match as played — and the
      // play-count chips on match cards render that embedded count. Mirror it,
      // or solver rounds display one game behind legacy ones. Pool advancement
      // is unaffected: `updatePlayerState` counts match *membership*, never the
      // embedded values.
      match: match->Match.incrementPlayCounts,
      score: None,
      createdAt,
      synced: false,
    }
    entity
  })
  (entities, violations)
}

// One round through the legacy engine, byes included. Used both for non-solver
// strategies and as the per-round fallback when a solve fails.
let greedyRound = (
  ~availablePlayers: array<Player.t<'a>>,
  ~completedRounds: array<array<completedMatchEntity<'a>>>,
  ~strategy: strategy,
  ~courtCount: int,
  ~teamConstraints: option<array<Set.t<string>>>,
  ~avoidAllPlayers: array<array<Player.t<'a>>>,
  ~genderMixed: bool,
  ~startTime: Js.Date.t,
  ~roundIndex: int,
): option<array<completedMatchEntity<'a>>> =>
  generateRoundsRec(
    ~roundNumber=roundIndex + 1,
    ~roundsToGenerate=1,
    ~availablePlayers,
    ~completedRounds,
    ~strategy,
    ~courtCount,
    ~teamConstraints?,
    ~avoidAllPlayers,
    ~genderMixed,
    ~startTime,
    ~currentRoundIndex=roundIndex,
    (),
  )->Array.get(0)

// ---------------------------------------------------------------------------
// Entry points
// ---------------------------------------------------------------------------

// Generates `numberOfRounds` rounds, feeding each round's result back into the
// player state (play counts) exactly the way the greedy engine does.
//
// `seed` should be stable for a given event + generation request so that
// regenerating produces the same draw; the round index is mixed in per round.
let generateRounds = async (
  ~numberOfRounds: int,
  ~availablePlayers: array<Player.t<'a>>,
  ~completedRounds: array<array<completedMatchEntity<'a>>>,
  ~strategy: strategy,
  ~courtCount: int,
  ~startTime: Js.Date.t,
  ~weightConfig: option<CostModel.uiWeightConfig>=?,
  ~teamConstraints: option<array<Set.t<string>>>=?,
  ~avoidAllPlayers: array<array<Player.t<'a>>>=[],
  ~requiredPlayerIds: array<string>=[],
  ~priorityPlayerIds: array<string>=[],
  ~genderMixed: bool=false,
  ~startRoundIndex: int=0,
  ~seed: string="round",
  ~timeLimit: float=1.0,
  (),
): sessionResult<'a> => {
  if !(strategy->isSolverStrategy) {
    // Legacy strategies keep the synchronous engine verbatim, but still yield
    // first so a caller's pending "generating" state gets a chance to paint.
    await yieldToBrowser()
    {
      rounds: greedyGenerateRounds(
        ~startRoundNumber=startRoundIndex + 1,
        ~numberOfRounds,
        ~availablePlayers,
        ~completedRounds,
        ~strategy,
        ~courtCount,
        ~teamConstraints?,
        ~avoidAllPlayers,
        ~genderMixed,
        ~startTime,
        (),
      )->Array.map(emptyOutcome),
      fellBackToGreedy: false,
    }
  } else {
    let weights = effectiveWeights(
      ~strategy,
      ~weightConfig,
      ~players=availablePlayers,
      ~numCourts=courtCount,
    )
    // Court order: Round Robin bands first and Competitive+ is leveled by
    // definition, so both put the strongest court at court 1. Random Balanced
    // is the one mode that must *look* random, so its courts shuffle per seed.
    // The adaptive profile follows its blend: random-looking while it is still
    // calibrating, leveled once the competitive half dominates.
    let courtOrder = switch strategy {
    | SolverRandomBalanced => SolverRound.ShuffledCourts
    | SolverCompetitivePlus =>
      CostModel.adaptiveBlend(CostModel.readinessRatio(availablePlayers)) < 0.5
        ? SolverRound.ShuffledCourts
        : SolverRound.CourtsByLevel
    | _ => SolverRound.CourtsByLevel
    }
    // Loaded once and reused for every round in this request.
    let highs = await HighsBindings.load()

    let outcomes = []
    let fellBack = ref(highs->Option.isNone)
    let players = ref(availablePlayers)
    let accumulated = ref([])

    let roundsRemaining = ref(numberOfRounds)
    let roundIndex = ref(startRoundIndex)

    while roundsRemaining.contents > 0 && players.contents->Array.length >= courtCount * 4 {
      // Each round is a synchronous wasm solve; yield between them so the page
      // can paint and stay interactive.
      await yieldToBrowser()

      let allRounds = Array.concat(completedRounds, accumulated.contents)
      let prng = SolverPrng.fromSeedString(seed ++ "#" ++ roundIndex.contents->Int.toString)

      let solved = switch highs {
      | None => None
      | Some(h) =>
        await SolverRound.generateRound(
          ~players=players.contents,
          ~rounds=allRounds,
          ~weights,
          ~numCourts=courtCount,
          ~prng,
          ~avoidAllPlayers,
          ~teamConstraints=teamConstraints->Option.getOr([]),
          ~requiredPlayerIds,
          ~priorityPlayerIds,
          ~genderMixed,
          ~timeLimit,
          ~highs=h,
          ~courtOrder,
          (),
        )
      }

      let outcome = switch solved {
      | Some(result) =>
        let (matches, matchViolations) = toEntities(
          ~matches=result.matches,
          ~createdAt=roundCreatedAt(~startTime, ~roundIndex=roundIndex.contents),
        )
        Some({
          matches,
          matchViolations,
          roundViolations: result.roundViolations,
          byePlayerIds: result.byePlayerIds,
          usedSolver: true,
        })
      | None =>
        fellBack := true
        greedyRound(
          ~availablePlayers=players.contents,
          ~completedRounds=allRounds,
          ~strategy,
          ~courtCount,
          ~teamConstraints,
          ~avoidAllPlayers,
          ~genderMixed,
          ~startTime,
          ~roundIndex=roundIndex.contents,
        )->Option.map(emptyOutcome)
      }

      switch outcome {
      | None => roundsRemaining := 0 // nothing more can be generated
      | Some(outcome) =>
        outcomes->Array.push(outcome)
        accumulated := Array.concat(accumulated.contents, [outcome.matches])
        players :=
          updatePlayerState(
            ~players=players.contents,
            ~timeline=[TimelineEvent.Round(outcome.matches)],
          )
        roundIndex := roundIndex.contents + 1
        roundsRemaining := roundsRemaining.contents - 1
      }
    }

    {rounds: outcomes, fellBackToGreedy: fellBack.contents}
  }
}

// Regenerate a single round in place, mirroring `Rating.generateSingleRound`.
let generateSingleRound = async (
  ~roundIndex: int,
  ~rounds: array<array<completedMatchEntity<'a>>>,
  ~availablePlayers: array<Player.t<'a>>,
  ~strategy: strategy,
  ~courtCount: int,
  ~startTime: Js.Date.t,
  ~weightConfig: option<CostModel.uiWeightConfig>=?,
  ~teamConstraints: option<array<Set.t<string>>>=?,
  ~avoidAllPlayers: array<array<Player.t<'a>>>=[],
  ~requiredPlayerIds: array<string>=[],
  ~genderMixed: bool=false,
  ~seed: string="round",
  ~timeLimit: float=1.0,
  (),
): option<roundOutcome<'a>> => {
  let roundsBeforeThis = roundIndex == 0 ? [] : rounds->Array.slice(~start=0, ~end=roundIndex)
  let result = await generateRounds(
    ~numberOfRounds=1,
    ~availablePlayers,
    ~completedRounds=roundsBeforeThis,
    ~strategy,
    ~courtCount,
    ~startTime,
    ~weightConfig?,
    ~teamConstraints?,
    ~avoidAllPlayers,
    ~requiredPlayerIds,
    ~genderMixed,
    ~startRoundIndex=roundIndex,
    ~seed,
    ~timeLimit,
    (),
  )
  result.rounds->Array.get(0)
}

// Flatten a session result back into the plain round shape the rest of the app
// stores, keeping the violations in a single lookup for the UI.
let toRounds = (result: sessionResult<'a>): array<array<completedMatchEntity<'a>>> =>
  result.rounds->Array.map(r => r.matches)

let mergeViolations = (result: sessionResult<'a>): Js.Dict.t<array<SolverTypes.violation>> => {
  let merged = Js.Dict.empty()
  result.rounds->Array.forEach(round =>
    round.matchViolations
    ->Js.Dict.entries
    ->Array.forEach(((id, reasons)) => merged->Js.Dict.set(id, reasons))
  )
  merged
}

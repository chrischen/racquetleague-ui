// Storybook support for SeedAdjustmentTimeline.stories.tsx; the app never imports this.
// The amber marker EventManager draws on the round board where the organiser
// re-seeded players: collapsed it counts players moved up and down; expanded
// it lists each with the size of the move, and offers delete. Adjustments come
// from StoryFixturesSession; players from the shared match roster (read
// through EventManager's fragment, so avatars are real) plus two walk-ins.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

// Everyone re-seeded at once, walk-ins included: a dense grid with long names,
// and two players left where they were (shown as a dash).
let everyone = (players: array<Rating.Player.t<'a>>) =>
  players->Array.mapWithIndex((p, i): Rating.RatingAdjustment.t => {
    playerId: p.id,
    differential: Int.toFloat(mod(i * 7, 11) - 5) *. 0.45,
    sigmaDifferential: -1.5,
    appliedAtRound: -1,
    timestamp: StoryFixturesSession.seedTime,
  })

// The round board's page background, which the marker's label is cut out of.
module Board = {
  @react.component
  let make = (~children) => <div className="bg-slate-50 px-4 py-6"> children </div>
}

module RoundLabel = {
  @react.component
  let make = (~children) =>
    <div className="text-sm font-semibold text-slate-500 text-center"> children </div>
}

@genType @react.component
let make = (
  ~state: [#seeds | #singlePlayer | #everyone | #severalRounds]=#seeds,
  ~onDelete: option<string => unit>=?,
) => {
  let players = useManagerPlayers()->Array.concat(StoryFixturesSession.guests())
  let playersCache = React.useMemo1(() => players->Rating.PlayersCache.fromPlayers, [players])
  let timeline = (label, adjustments) =>
    <SeedAdjustmentTimeline
      key=label
      adjustments
      playersCache
      getUserFragmentRefs
      onDelete={() => onDelete->Option.forEach(f => f(label))}
    />

  <Board>
    {switch state {
    | #seeds => timeline("Before round 1", StoryFixturesSession.seedAdjustments)
    | #singlePlayer =>
      timeline("Before round 3", [StoryFixturesSession.round3Adjustments->Array.getUnsafe(0)])
    | #everyone => timeline("Before round 1", everyone(players))
    | #severalRounds =>
      <>
        <RoundLabel> {"Before round 1"->React.string} </RoundLabel>
        {timeline("Before round 1", StoryFixturesSession.seedAdjustments)}
        <RoundLabel> {"Before round 2"->React.string} </RoundLabel>
        {timeline("Before round 2", StoryFixturesSession.round2Adjustments)}
        <RoundLabel> {"Before round 3"->React.string} </RoundLabel>
        {timeline("Before round 3", StoryFixturesSession.round3Adjustments)}
      </>
    }}
  </Board>
}

// Storybook support for MatchesView.stories.tsx; the app never imports this.
// AiTetsu's full-screen session mode: the Queue tab (who's queued, playing or
// on a break), the Matches tab (drag-and-drop court cards) and the check-in
// slot, each with its bottom action bar. The wrapper keeps the queue, the
// matches and the tab in state and wires "Choose Match" to a real CompMatch,
// as AiTetsu does. Players come from the shared match roster
// (StoryFixturesMatch), read through AiTetsu's fragment.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

// Stand-ins for the slots AiTetsu fills with its own (private) components.
module CheckinSlot = {
  @react.component
  let make = (~players: array<Rating.Player.t<Rating.rsvpNode>>) =>
    <div className="rounded-lg bg-white p-4 text-sm text-gray-700">
      <p className="mb-3 text-xs uppercase tracking-wide text-gray-400">
        {"Check-in list (AiTetsu's Checkin fills this slot)"->React.string}
      </p>
      <ul className="grid grid-cols-2 gap-2 sm:grid-cols-3">
        {players
        ->Array.map(p =>
          <li key={p.id} className="flex items-center gap-2">
            <input type_="checkbox" defaultChecked=true readOnly=true />
            {p.name->React.string}
          </li>
        )
        ->React.array}
      </ul>
    </div>
}

module SelectedActionsSlot = {
  @react.component
  let make = (~players: array<Rating.Player.t<Rating.rsvpNode>>) =>
    <div className="mt-6 text-sm text-gray-700">
      <p className="mb-2 text-xs uppercase tracking-wide text-gray-400">
        {"Team actions for the queued players (AiTetsu fills this slot)"->React.string}
      </p>
      {players->Array.map(p => p.name)->Array.join(", ")->React.string}
    </div>
}

@genType @react.component
let make = (
  ~view: [#queue | #matches | #checkin]=#queue,
  ~state: [#typical | #noMatches | #readyToChoose]=#typical,
  ~onClose: option<unit => unit>=?,
  ~onSubmitResults: option<unit => unit>=?,
  ~onMatchUpdated: option<(string, option<(float, float)>) => unit>=?,
  ~onMatchCanceled: option<string => unit>=?,
) => {
  let all = useQueuePlayers()
  let players = React.useMemo1(() => all->Array.slice(~start=0, ~end=12), [all])
  let playersCache = React.useMemo1(() => players->Rating.PlayersCache.fromPlayers, [players])
  let (minRating, maxRating) = players->ratingRange
  let ids = indexes => indexes->Array.map(i => (players->at(i)).id)

  let (view, setView) = React.useState(() =>
    switch view {
    | #queue => MatchesView.Queue
    | #matches => MatchesView.Matches
    | #checkin => MatchesView.Checkin
    }
  )
  // Two courts in play, Sota and Sarah on a break, the rest free; Daniel and
  // Haruka already queued (four queued turns "Queue All" into "CHOOSE MATCH").
  let (matches, setMatches) = React.useState(() =>
    switch state {
    | #noMatches => []
    | #typical | #readyToChoose => [
        {Rating.id: "q-c1", match: doubles(players, (kenji, mai), (yuki, takumi))},
        {Rating.id: "q-c2", match: doubles(players, (chris, emily), (aiko, hiroshi))},
      ]
    }
  )
  let (queue, setQueue) = React.useState(() =>
    switch state {
    | #readyToChoose => ids([daniel, haruka, sota, sarah])->Set.fromArray
    | #typical | #noMatches => ids([daniel, haruka])->Set.fromArray
    }
  )
  let breakPlayers = React.useMemo0(() => ids([sota, sarah])->Set.fromArray)
  let (breakCount, setBreakCount) = React.useState(() => 3)
  let consumedPlayers =
    matches
    ->Array.flatMap(({match}) => match->Rating.Match.players)
    ->Array.map(p => p.id)
    ->Set.fromArray
  let queuedPlayers = players->Array.filter(p => queue->Set.has(p.id))

  <MatchesView
    view
    setView
    players
    availablePlayers=players
    playersCache
    checkin={<CheckinSlot players />}
    queue
    breakPlayers
    consumedPlayers
    togglePlayer={player =>
      setQueue(queue => {
        let next = Set.fromArray(queue->Set.values->Array.fromIterator)
        next->Set.has(player.id) ? next->Set.delete(player.id)->ignore : next->Set.add(player.id)
        next
      })}
    setQueue={ids => setQueue(_ => ids->Set.fromArray)}
    setRequiredPlayers={_ => ()}
    matches
    setMatches
    minRating
    maxRating
    handleMatchCanceled={index => {
      setMatches(matches => matches->Array.filterWithIndex((_, i) => i->Int.toString != index))
      onMatchCanceled->Option.forEach(f => f(index))
    }}
    handleMatchUpdated={((_, score), index) => onMatchUpdated->Option.forEach(f => f(index, score))}
    handleMatchesComplete={() => {
      onSubmitResults->Option.forEach(f => f())
      Promise.resolve()
    }}
    onClose={_ => onClose->Option.forEach(f => f())}
    selectAll={() => setQueue(_ => players->Array.map(p => p.id)->Set.fromArray)}
    breakCount
    onChangeBreakCount={n => setBreakCount(_ => Math.Int.max(0, n))}
    matchSelector={<CompMatch
      players=queuedPlayers
      session={session(players)}
      teams=None
      consumedPlayers
      seenTeams={Set.make()}
      seenMatches={Set.make()}
      lastRoundSeenTeams={Set.make()}
      lastRoundSeenMatches={Set.make()}
      defaultStrategy=Rating.CompetitivePlus
      setDefaultStrategy={_ => ()}
      priorityPlayers=[]
      onSelectMatch={(match, ~disablePlayers as _=?) => {
        setMatches(matches =>
          matches->Array.concat([
            {Rating.id: "q-c" ++ (matches->Array.length + 1)->Int.toString, match},
          ])
        )
        setQueue(_ => Set.make())
        setView(_ => MatchesView.Matches)
      }}
      courts={Util.NonZeroInt.make(breakCount - matches->Array.length)}
    />}
    selectedPlayersActions={players => <SelectedActionsSlot players />}
    sessionState={session(players)}
  />
}

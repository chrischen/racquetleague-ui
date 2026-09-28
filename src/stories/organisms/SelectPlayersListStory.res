// Storybook support for SelectPlayersList.stories.tsx; the app never imports this.
// The queue screen's roster table: tap a name to take a player in or out of
// tonight's pool, remove or re-enable someone who left, and sort by rating or
// by games played. Players come from the shared match roster read through
// AiTetsu's fragment, as the queue screens read them. The wrapper keeps the
// three sets in state so the table responds to clicks.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~state: [#empty | #typical | #withGuests]=#typical,
  ~onClick: option<string => unit>=?,
  ~onRemove: option<string => unit>=?,
  ~onEnable: option<string => unit>=?,
) => {
  let roster = useQueuePlayers()
  let players = switch state {
  | #empty => []
  | #typical => roster
  | #withGuests => roster->Array.concat(StoryFixturesSession.guests())
  }
  let session = React.useMemo1(() => session(players), [players])

  // In the pool: the 16 regulars (and any walk-ins). Of the rest, Maximilian
  // was removed earlier (struck through, "Enable"); the other three are simply
  // not in tonight's pool ("Remove").
  let (selected, setSelected) = React.useState(() =>
    StoryFixturesSession.checkedInWithGuests(players)
  )
  let (disabled, setDisabled) = React.useState(() => Set.fromArray(["user-maximilian"]))
  // On court now: the round-2 draw.
  let playing =
    round2(roster)
    ->Array.flatMap(m => {
      let (team1, team2) = m.match
      team1->Array.concat(team2)
    })
    ->Array.map(p => p.id)
    ->Set.fromArray

  let copy = set => set->Set.values->Array.fromIterator->Set.fromArray

  <SelectPlayersList
    players
    selected
    playing
    disabled
    session
    onClick={player => {
      setSelected(prev => {
        let next = copy(prev)
        prev->Set.has(player.id)
          ? next->Set.delete(player.id)->ignore
          : next->Set.add(player.id)->ignore
        next
      })
      onClick->Option.forEach(f => f(player.name))
    }}
    onRemove={player => {
      setDisabled(prev => {
        let next = copy(prev)
        next->Set.add(player.id)->ignore
        next
      })
      onRemove->Option.forEach(f => f(player.name))
    }}
    onEnable={player => {
      setDisabled(prev => {
        let next = copy(prev)
        next->Set.delete(player.id)->ignore
        next
      })
      onEnable->Option.forEach(f => f(player.name))
    }}
  />
}

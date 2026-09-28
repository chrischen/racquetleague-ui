// Storybook support for RoundSection.stories.tsx; the app never imports this.
// One round on the EventManager board: its header (active badge, rebalance,
// reset, full screen), the court cards, and the avatars of players sitting
// out. The wrapper keeps the round's matches in state, so tapping a team,
// saving a score, deleting a court or replacing a player updates the board.
// Players come from the shared match roster (StoryFixturesMatch), read through
// EventManager's fragment as the app does.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~state: [#current | #repeats | #past | #upcoming | #manyWaiting]=#current,
  ~debug=false,
  ~onRebalance: option<unit => unit>=?,
  ~onRebalanceMatch: option<string => unit>=?,
  ~onReset: option<bool => unit>=?,
  ~onFullScreen: option<unit => unit>=?,
  ~onMatchUpdated: option<(string, option<(float, float)>) => unit>=?,
  ~onMatchCanceled: option<string => unit>=?,
) => {
  let players = useManagerPlayers()
  let playersCache = React.useMemo1(() => players->Rating.PlayersCache.fromPlayers, [players])
  let checkedInPlayerIds = React.useMemo1(() => checkedInIds(players), [players])

  // (round index, is current, is past, the round's matches)
  let (index, isCurrentRound, isPastRound, initial) = switch state {
  | #current => (1, true, false, round2(players))
  // Round 3 as the active round: court 1 repeats round 1 exactly, court 2
  // reuses a round-2 pair.
  | #repeats => (2, true, false, round3(players))
  | #past => (0, false, true, round1(players))
  | #upcoming => (2, false, false, round3(players))
  // Two courts free up: eight players wait, more than the avatar strip shows.
  | #manyWaiting => (1, true, false, round2(players)->Array.slice(~start=0, ~end=2))
  }
  let (matches, setMatches) = React.useState(() => initial)
  let allRounds = rounds(players)->Array.mapWithIndex((round, i) => i == index ? matches : round)

  <RoundSection
    matches
    roundNumber={index + 1}
    isCurrentRound
    isPastRound
    playersCache
    checkedInPlayerIds
    handleMatchCanceled={matchId => {
      setMatches(matches => matches->Array.filter(m => m.id != matchId))
      onMatchCanceled->Option.forEach(f => f(matchId))
    }}
    handleMatchUpdated={((_, score), matchId) => {
      setMatches(matches => matches->Array.map(m => m.id == matchId ? {...m, score} : m))
      onMatchUpdated->Option.forEach(f => f(matchId, score))
    }}
    setMatches={update => setMatches(update)}
    setQueue={_ => ()}
    setRequiredPlayers={_ => ()}
    setShowMatchSelector={_ => ()}
    ?onRebalance
    ?onRebalanceMatch
    ?onReset
    ?onFullScreen
    debug
    getUserFragmentRefs
    allRounds
  />
}

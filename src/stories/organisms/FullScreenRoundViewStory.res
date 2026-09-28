// Storybook support for FullScreenRoundView.stories.tsx; the app never
// imports this. The TV view of the active round: one column per court, the
// serving team on top. Players come from the shared match roster
// (StoryFixturesMatch), read through EventManager's fragment as the app does.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~state: [#notStarted | #partlyScored | #twoCourts | #fourCourts | #longNames]=#notStarted,
  ~onClose=() => (),
) => {
  let players = useManagerPlayers()
  let (roundNumber, matches) = switch state {
  | #notStarted => (3, round3(players))
  // Court 1 is in, so it no longer shows who serves.
  | #partlyScored => (2, round2(players))
  | #twoCourts => (2, round2(players)->Array.slice(~start=1, ~end=3))
  | #fourCourts => (
      4,
      [
        entity(~id="evt-r4-c1", doubles(players, (kenji, sarah), (chris, naomi))),
        entity(~id="evt-r4-c2", doubles(players, (yuki, sota), (aiko, tom))),
        entity(~id="evt-r4-c3", doubles(players, (hiroshi, rina), (takumi, haruka))),
        entity(~id="evt-r4-c4", doubles(players, (emily, daniel), (mai, ren))),
      ],
    )
  | #longNames => (
      5,
      [
        entity(~id="evt-r5-c1", doubles(players, (alexandra, maximilian), (shinnosuke, yukiko))),
        entity(~id="evt-r5-c2", doubles(players, (kenji, yukiko), (alexandra, chris))),
        entity(~id="evt-r5-c3", doubles(players, (maximilian, mai), (shinnosuke, emily))),
      ],
    )
  }
  <FullScreenRoundView matches roundNumber onClose getUserFragmentRefs />
}

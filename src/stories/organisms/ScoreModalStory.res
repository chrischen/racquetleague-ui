// Storybook support for ScoreModal.stories.tsx; the app never imports this.
// The score entry modal MatchCard opens on a long-press, framed around the
// team that was pressed. Players come from the shared match roster
// (StoryFixturesMatch), read through EventManager's fragment as the app does.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~winningTeam: [#team1 | #team2]=#team1,
  ~state: [#typical | #longNames]=#typical,
  ~onSubmit: option<(int, int) => unit>=?,
  ~onClose=() => (),
) => {
  let players = useManagerPlayers()
  let match = switch state {
  | #typical => doubles(players, (kenji, mai), (yuki, takumi))
  | #longNames => doubles(players, (alexandra, maximilian), (shinnosuke, yukiko))
  }
  <ScoreModal
    match
    winningTeam={switch winningTeam {
    | #team1 => ScoreModal.Team1
    | #team2 => ScoreModal.Team2
    }}
    onSubmit={(team1, team2) => onSubmit->Option.forEach(f => f(team1, team2))}
    onClose
    getUserFragmentRefs
  />
}

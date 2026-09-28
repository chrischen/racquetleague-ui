// Storybook support for TeamManagementModal.stories.tsx; the app never imports this.
// The event manager's teams dialog: fixed partnerships ("Teams") and pairs the
// draw must keep apart ("Anti-Teams"), each edited in a player picker. Names
// follow EventManager, which labels teams by position ("Team 1", "Anti-Team 1").
// Players are the shared match roster plus tonight's two walk-ins.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

let team = (id, name, members: array<int>): TeamManagementModal.teamData => {
  id,
  name,
  playerIds: members->Array.map(StoryFixturesSession.idOf),
}

let teams = [
  team(0, "Team 1", [kenji, yuki]),
  team(1, "Team 2", [chris, emily]),
  team(2, "Team 3", [takumi, alexandra]),
]

let antiTeams = [
  // A couple who would rather not partner each other.
  team(0, "Anti-Team 1", [aiko, hiroshi]),
  // Three newcomers who should each be paired with someone experienced.
  team(1, "Anti-Team 2", [daniel, sarah, tom]),
]

// Summaries for the Actions panel: "Team 1: Kenji Tanaka, Yuki Sato".
let describe = (players: array<Rating.Player.t<'a>>, teams: array<TeamManagementModal.teamData>) =>
  teams->Array.map(team =>
    team.name ++
    ": " ++
    team.playerIds
    ->Array.filterMap(id => players->Array.find(p => p.id == id)->Option.map(p => p.name))
    ->Array.join(", ")
  )

@genType @react.component
let make = (
  ~state: [#empty | #teamsOnly | #typical]=#typical,
  ~onSave: option<(array<string>, array<string>) => unit>=?,
  ~onClose=() => (),
) => {
  let players = useManagerPlayers()->Array.concat(StoryFixturesSession.guests())
  let (teams, antiTeams) = switch state {
  | #empty => ([], [])
  | #teamsOnly => (teams, [])
  | #typical => (teams, antiTeams)
  }
  <TeamManagementModal
    teams
    antiTeams
    players
    onSave={(teams, antiTeams) =>
      onSave->Option.forEach(f => f(describe(players, teams), describe(players, antiTeams)))}
    onClose
  />
}

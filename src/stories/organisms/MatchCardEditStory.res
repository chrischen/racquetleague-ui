// Storybook support for MatchCardEdit.stories.tsx; the app never imports this.
// The card's edit mode on its own: the line-up as editable rows with the
// recorded score shown read-only. Players come from the shared match roster
// (StoryFixturesMatch), read through EventManager's fragment as the app does.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~state: [#unscored | #scored | #winnerPicked | #longNames]=#scored,
  ~courtNumber=1,
  ~onSave: option<option<(float, float)> => unit>=?,
  ~onCancel=() => (),
  ~onDelete: option<unit => unit>=?,
) => {
  let players = useManagerPlayers()
  let (minRating, maxRating) = players->ratingRange
  let balanced = ((kenji, mai), (yuki, takumi))
  let ((team1, team2), score) = switch state {
  | #unscored => (balanced, None)
  | #scored => (balanced, Some((11., 7.)))
  // A winner tapped without a score (1 to -1) shows as dashes, not "-1".
  | #winnerPicked => (balanced, Some((1., -1.)))
  | #longNames => (((alexandra, maximilian), (shinnosuke, yukiko)), Some((9., 11.)))
  }
  let match = doubles(players, team1, team2)
  let (team1Players, team2Players) = match

  // The line-up rows the round board's drag-and-drop containers render.
  let teamElement = (team: array<Rating.Player.t<_>>) =>
    team
    ->Array.map(player =>
      <PlayerRow
        key={player.id}
        player
        isEditing=true
        winner=None
        teamSide=PlayerRow.Left
        skillLevel={(player.rating.mu -. minRating) /. (maxRating -. minRating) *. 100.}
        getUserFragmentRefs
      />
    )
    ->React.array

  <div className="max-w-sm">
    <MatchCardEdit
      match
      courtNumber
      ?score
      ?onDelete
      onSave={((_, score)) => onSave->Option.forEach(f => f(score))}
      onCancel
      team1Element={teamElement(team1Players)}
      team2Element={teamElement(team2Players)}
    />
  </div>
}

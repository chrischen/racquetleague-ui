// Storybook support for MatchCard.stories.tsx; the app never imports this.
// One court's card from the round board. Players come from the shared match
// roster (StoryFixturesMatch), read through EventManager's fragment as the app
// does, so avatars get real fragment refs. The wrapper keeps the score in
// state, so tapping a team or saving the score modal updates the card.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~state: [
    | #unscored
    | #scored
    | #winnerPicked
    | #draw
    | #mismatch
    | #repeat
    | #lastRound
    | #longNames
  ]=#unscored,
  ~editing=false,
  ~debug=false,
  ~courtNumber=1,
  ~onDelete: option<unit => unit>=?,
  ~onRebalance: option<unit => unit>=?,
  ~onUpdated: option<option<(float, float)> => unit>=?,
) => {
  let players = useManagerPlayers()
  let (minRating, maxRating) = players->ratingRange

  let balanced = ((kenji, mai), (yuki, takumi))
  let ((team1, team2), initialScore, matchHistory, team1History, team2History) = switch state {
  | #unscored => (balanced, None, MatchCard.NoHistory, MatchCard.NoHistory, MatchCard.NoHistory)
  | #scored => (balanced, Some((11., 7.)), NoHistory, NoHistory, NoHistory)
  // Tapping a team records the winner as 1 to -1, with no score.
  | #winnerPicked => (balanced, Some((-1., 1.)), NoHistory, NoHistory, NoHistory)
  | #draw => (balanced, Some((11., 11.)), NoHistory, NoHistory, NoHistory)
  // The two strongest against the two weakest: a long prediction bar.
  | #mismatch => (((kenji, yuki), (tom, rina)), None, NoHistory, NoHistory, NoHistory)
  // Played together in an earlier round (not the last one).
  | #repeat => (balanced, None, PreviousRound, PreviousRound, PreviousRound)
  // The same four, same teams, as last round.
  | #lastRound => (balanced, None, LastRound, LastRound, LastRound)
  | #longNames => (
      ((alexandra, maximilian), (shinnosuke, yukiko)),
      None,
      NoHistory,
      NoHistory,
      NoHistory,
    )
  }
  let match = doubles(players, team1, team2)
  let (score, setScore) = React.useState(() => initialScore)

  // What the card shows in edit mode: the line-up rows the round board's
  // drag-and-drop containers render for each team.
  let teamElement = (key, team: array<Rating.Player.t<_>>) =>
    <div key className="space-y-2">
      {team
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
      ->React.array}
    </div>
  let (team1Players, team2Players) = match

  <div className="max-w-sm">
    <MatchCard
      key={editing ? "edit" : "view"}
      defaultView={editing ? MatchCard.SubmitMatch : MatchCard.Default}
      match
      ?score
      courtNumber
      minRating
      maxRating
      ?onDelete
      ?onRebalance
      onUpdated={((_, score)) => {
        setScore(_ => score)
        onUpdated->Option.forEach(f => f(score))
      }}
      debug
      getUserFragmentRefs
      team1History
      team2History
      matchHistory
      serviceKey={"evt-story-c" ++ courtNumber->Int.toString}>
      {[teamElement("team1", team1Players), teamElement("team2", team2Players)]}
    </MatchCard>
  </div>
}

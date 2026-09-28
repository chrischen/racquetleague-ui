// Storybook support for SortableSubmitMatch.stories.tsx; the app never
// imports this. The match card on MatchesView's "Matches" tab. There the team
// elements come from the drag-and-drop containers; here each team is the same
// SubmitMatch.PlayerView rows MatchesView renders into them. Players come from
// the shared match roster (StoryFixturesMatch), read through AiTetsu's fragment.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~state: [#rated | #guests | #longNames]=#rated,
  ~scoreEntry=false,
  ~onDelete: option<unit => unit>=?,
  ~onUpdated: option<option<(float, float)> => unit>=?,
) => {
  let players = useQueuePlayers()
  let (minRating, maxRating) = players->ratingRange
  let match = switch state {
  | #rated => doubles(players, (kenji, mai), (yuki, takumi))
  // Walk-ins have no account: Winner buttons instead of score inputs.
  | #guests => (
      [players->at(kenji), guest(~name="Taro (guest)", ~intId=21)],
      [players->at(yuki), guest(~name="Walk-in Sam", ~gender=Female, ~intId=22)],
    )
  | #longNames => doubles(players, (alexandra, maximilian), (shinnosuke, yukiko))
  }
  let (team1, team2) = match
  let teamElement = (key, team: array<Rating.Player.t<Rating.rsvpNode>>) =>
    <div key>
      {team
      ->Array.map(player => <SubmitMatch.PlayerView key={player.id} player minRating maxRating />)
      ->React.array}
    </div>

  <div className="max-w-md">
    <SortableSubmitMatch
      key={scoreEntry ? "score" : "card"}
      defaultView={scoreEntry ? SortableSubmitMatch.SubmitMatch : SortableSubmitMatch.Default}
      match
      minRating
      maxRating
      ?onDelete
      onUpdated={((_, score)) => onUpdated->Option.forEach(f => f(score))}>
      {[teamElement("team1", team1), teamElement("team2", team2)]}
    </SortableSubmitMatch>
  </div>
}

// Storybook support for SubmitMatch.stories.tsx; the app never imports this.
// The older AiTetsu match card: tap it to open score entry. Players come from
// the shared match roster (StoryFixturesMatch), read through AiTetsu's own
// fragment, so each name and avatar is a real EventMatchRsvpUser fragment.
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
  ~withScore=false,
  ~onDelete: option<unit => unit>=?,
  ~onComplete: option<(string, option<(float, float)>) => unit>=?,
) => {
  let players = useQueuePlayers()
  let (minRating, maxRating) = players->ratingRange
  let match = switch state {
  | #rated => doubles(players, (kenji, mai), (yuki, takumi))
  // Walk-ins added at the desk have no account, so the match can't be rated:
  // the score inputs become Winner buttons.
  | #guests => (
      [players->at(kenji), guest(~name="Taro (guest)", ~intId=21)],
      [players->at(yuki), guest(~name="Walk-in Sam", ~gender=Female, ~intId=22)],
    )
  | #longNames => doubles(players, (alexandra, maximilian), (shinnosuke, yukiko))
  }
  <div className="max-w-md">
    <SubmitMatch
      key={scoreEntry ? "score" : "card"}
      defaultView={scoreEntry ? SubmitMatch.SubmitMatch : SubmitMatch.Default}
      match
      score=?{withScore ? Some((11., 7.)) : None}
      minRating
      maxRating
      ?onDelete
      onComplete={((match, score)) => onComplete->Option.forEach(f => f(describe(match), score))}
    />
  </div>
}

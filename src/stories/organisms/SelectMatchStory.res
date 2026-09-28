// Storybook support for SelectMatch.stories.tsx; the app never imports this.
// AiTetsu's "manual team" picker: choose two players for each side from the
// queue (strongest first); with four chosen, "Queue Match" appears above a
// SubmitMatch card for the pairing, as AiTetsu renders it. Players come from
// the shared match roster (StoryFixturesMatch), read through AiTetsu's fragment.
open StoryFixturesMatch

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = StoryFixturesMatchQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~state: [#empty | #typical | #withGuests | #longNames]=#typical,
  ~onMatchQueued: option<string => unit>=?,
) => {
  let all = useQueuePlayers()
  // SelectMatch clears its picks whenever `players` changes identity.
  let players = React.useMemo2(() => {
    let pick = indexes => indexes->Array.map(i => all->at(i))
    switch state {
    | #empty => []
    | #typical => all->Array.slice(~start=0, ~end=12)
    | #withGuests =>
      all
      ->Array.slice(~start=0, ~end=8)
      ->Array.concat([
        guest(~name="Taro (guest)", ~intId=21),
        guest(~name="Walk-in Sam", ~gender=Female, ~mu=22., ~intId=22),
      ])
    | #longNames => pick([alexandra, shinnosuke, maximilian, yukiko, kenji, yuki])
    }
  }, (all, state))
  let (minRating, maxRating) = players->ratingRange

  <SelectMatch
    players onMatchQueued={match => onMatchQueued->Option.forEach(f => f(describe(match)))}>
    {match => <SubmitMatch match minRating maxRating />}
  </SelectMatch>
}

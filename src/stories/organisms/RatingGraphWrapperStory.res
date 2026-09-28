// Storybook support for RatingGraphWrapper.stories.tsx; the app never
// imports this. The query spreads the wrapper's fragment at the root with
// literal arguments, as LeaguePlayerPage does for the player it shows.
module Query = %relay(`
  query RatingGraphWrapperStoryQuery {
    ...RatingGraphWrapperFragment @arguments(activitySlug: "pickleball", userId: "user-kenji")
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = RatingGraphWrapperStoryQuery_graphql.node->Obj.magic

/** The player whose history the graph plots (a key in each match's playerMetadata). */
@genType
let playerId = "user-kenji"

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  <div className="max-w-4xl font-sans">
    <RatingGraphWrapper matches=data.fragmentRefs userId=playerId />
  </div>
}

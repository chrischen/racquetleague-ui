// Storybook support for MatchHistoryList.stories.tsx; the app never imports
// this. The query spreads the list's fragment at the root with literal
// arguments. From a player's page the list also gets that player, which puts
// their team on the left; an event page passes no player.
module Query = %relay(`
  query MatchHistoryListStoryQuery {
    ...MatchHistoryListFragment @arguments(activitySlug: "pickleball", userId: "user-kenji")
    user(id: "user-kenji") {
      ...MatchHistoryListUser_user
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = MatchHistoryListStoryQuery_graphql.node->Obj.magic

/** The player whose page the list sits on in the `player` perspective. */
@genType
let playerId = "user-kenji"

@genType @react.component
let make = (~perspective: [#player | #event]=#player) => {
  let data = Query.use(~variables=())
  let user = switch perspective {
  | #player => data.user->Option.map(u => u.fragmentRefs)
  | #event => None
  }
  <div className="max-w-3xl font-sans">
    <MatchHistoryList matches=data.fragmentRefs ?user />
  </div>
}

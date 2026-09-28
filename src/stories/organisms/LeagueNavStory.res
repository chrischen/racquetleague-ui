// Storybook support for LeagueNav.stories.tsx; the app never imports this.
// .storybook/relay.tsx fills the store before this renders.
module Query = %relay(`
  query LeagueNavStoryQuery {
    ...LeagueNav_query
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = LeagueNavStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  <LeagueNav query=data.fragmentRefs />
}

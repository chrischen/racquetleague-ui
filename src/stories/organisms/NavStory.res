// Storybook support for Nav.stories.tsx; the app never imports this.
// .storybook/relay.tsx fills the store before this renders.
module Query = %relay(`
  query NavStoryQuery {
    ...Nav_query
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = NavStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  <Nav query=data.fragmentRefs />
}

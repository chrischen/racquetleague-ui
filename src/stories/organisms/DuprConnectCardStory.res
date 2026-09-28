// Storybook support for DuprConnectCard.stories.tsx; the app never imports
// this. .storybook/relay.tsx fills the store before this renders.
module Query = %relay(`
  query DuprConnectCardStoryQuery {
    ...DuprConnectCard_query
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = DuprConnectCardStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~onChanged=() => ()) => {
  let data = Query.use(~variables=())
  <DuprConnectCard query=data.fragmentRefs onChanged />
}

// Storybook support for SettingsProfileForm.stories.tsx; the app never
// imports this. The query spreads the form's fragment at the root, as
// SettingsProfilePage does. .storybook/relay.tsx fills the store before this
// renders.
module Query = %relay(`
  query SettingsProfileFormStoryQuery {
    ...SettingsProfileForm_query
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = SettingsProfileFormStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  <div className="mx-auto max-w-2xl font-sans">
    <SettingsProfileForm query=data.fragmentRefs />
  </div>
}

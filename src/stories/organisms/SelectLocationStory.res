// Storybook support for SelectLocation.stories.tsx; the app never imports
// this. The venue picker: every known location as a link, and a form to add
// a new one.
module Query = %relay(`
  query SelectLocationStoryQuery {
    ...SelectLocation_query
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = SelectLocationStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  <div className="font-sans">
    <SelectLocation locations=data.fragmentRefs />
  </div>
}

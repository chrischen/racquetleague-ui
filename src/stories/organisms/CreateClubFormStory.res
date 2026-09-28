// Storybook support for CreateClubForm.stories.tsx; the app never imports
// this. The form only reads the activity list from the query; the created
// club goes to `onCreated` (its id, for the Actions panel).
module Query = %relay(`
  query CreateClubFormStoryQuery {
    ...CreateClubForm_activities
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = CreateClubFormStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~onCancel=() => (), ~onCreated: option<string => unit>=?) => {
  let data = Query.use(~variables=())
  <div className="max-w-xl font-sans">
    <CreateClubForm
      query=data.fragmentRefs
      onCancel
      onCreated={club => onCreated->Option.forEach(f => f(club.id))}
    />
  </div>
}

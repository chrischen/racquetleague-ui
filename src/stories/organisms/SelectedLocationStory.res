// Storybook support for SelectedLocation.stories.tsx; the app never imports
// this. The chosen venue on the event form, with a toggle that opens the
// venue search (AutocompleteLocation).
module Query = %relay(`
  query SelectedLocationStoryQuery {
    location(id: "loc-story-1") {
      ...SelectedLocation_location
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = SelectedLocationStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~onNewLocation=(_: string) => ()) => {
  let data = Query.use(~variables=())
  switch data.location {
  | Some(location) =>
    <div className="max-w-2xl font-sans">
      <SelectedLocation location=location.fragmentRefs onNewLocation />
    </div>
  | None => React.null
  }
}

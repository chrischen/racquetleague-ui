// Storybook support for EventLocation.stories.tsx; the app never imports this.
// EventLocation is the venue block on the event page's location tab: name,
// address (linked to the first map link), every link, and the venue notes.
module Query = %relay(`
  query EventLocationStoryQuery {
    location(id: "loc-story-1") {
      ...EventLocation_location
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventLocationStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~hideAddress=false) => {
  let data = Query.use(~variables=())
  switch data.location {
  | Some(location) =>
    <div className="max-w-xl font-sans">
      <EventLocation location=location.fragmentRefs hideAddress />
    </div>
  | None => React.null
  }
}

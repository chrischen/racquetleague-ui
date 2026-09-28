// Storybook support for EventDetails.stories.tsx; the app never imports this.
// EventDetails is the tabbed card under the event header: the organizer's
// description, and the venue (EventLocation plus its MediaList videos).
module Query = %relay(`
  query EventDetailsStoryQuery {
    event(id: "evt-story-1") {
      ...EventDetails_event
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventDetailsStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    <div className="max-w-2xl font-sans">
      <EventDetails event=event.fragmentRefs />
    </div>
  | None => React.null
  }
}

// Storybook support for PendingRsvps.stories.tsx; the app never imports this.
// The Pending list: RSVPs the organizer has not admitted yet (listType other
// than 0). It renders nothing when there are none.
module Query = %relay(`
  query PendingRsvpsStoryQuery {
    event(id: "evt-story-1") {
      ...PendingRsvps_event
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PendingRsvpsStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~activitySlug: [#pickleball | #badminton]=#pickleball,
  ~maxRating=38.6,
  // RSVP ids a Smart RSVP preview says the next run would admit.
  ~previewAdmittedIds: option<array<string>>=?,
) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    <div className="max-w-md font-sans">
      <PendingRsvps
        event=event.fragmentRefs
        activitySlug={(activitySlug :> string)}
        maxRating
        ?previewAdmittedIds
        className="mb-5"
      />
    </div>
  | None => React.null
  }
}

// Storybook support for RsvpWaitlist.stories.tsx; the app never imports this.
// The Waitlist: main-list RSVPs past the event's maxRsvps, in join order. It
// renders nothing when the event is not over capacity.
module Query = %relay(`
  query RsvpWaitlistStoryQuery {
    event(id: "evt-story-1") {
      ...RsvpWaitlist_event
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = RsvpWaitlistStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~activitySlug: [#pickleball | #badminton]=#pickleball, ~viewerId: option<string>=?) => {
  let data = Query.use(~variables=())
  let viewer: option<RSVPSection_user_graphql.Types.fragment> = viewerId->Option.map(id => {
    RSVPSection_user_graphql.Types.id,
    lineUsername: None,
    eventRating: None,
  })
  switch data.event {
  | Some(event) =>
    <div className="max-w-md font-sans">
      <RsvpWaitlist
        event=event.fragmentRefs
        ?viewer
        activitySlug={(activitySlug :> string)}
        maxRating=38.6
        className="mb-5"
      />
    </div>
  | None => React.null
  }
}

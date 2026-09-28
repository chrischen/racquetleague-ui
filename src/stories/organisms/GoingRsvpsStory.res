// Storybook support for GoingRsvps.stories.tsx; the app never imports this.
// The Going list on the classic event page's RSVP card.
module Query = %relay(`
  query GoingRsvpsStoryQuery {
    event(id: "evt-story-1") {
      ...GoingRsvps_event
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = GoingRsvpsStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~activitySlug: [#pickleball | #badminton]=#pickleball,
  // RSVPSection passes the highest mu among the RSVPs; the shared roster tops
  // out at 38.6.
  ~maxRating=38.6,
  ~viewerId: option<string>=?,
) => {
  let data = Query.use(~variables=())
  let viewer: option<RSVPSection_user_graphql.Types.fragment> = viewerId->Option.map(id => {
    RSVPSection_user_graphql.Types.id,
    lineUsername: None,
    eventRating: None,
  })
  switch data.event {
  | Some(event) =>
    <div className="max-w-md font-sans">
      <GoingRsvps
        event=event.fragmentRefs
        ?viewer
        activitySlug={(activitySlug :> string)}
        maxRating
        className="mb-5"
      />
    </div>
  | None => React.null
  }
}

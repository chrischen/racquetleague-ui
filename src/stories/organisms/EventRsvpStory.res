// Storybook support for EventRsvp.stories.tsx; the app never imports this.
// EventRsvp is one player on the classic event page's RSVP lists (GoingRsvps,
// RsvpWaitlist, PendingRsvps): avatar with a rating ring, a menu of RSVP
// actions (RsvpOptions), the player's message and, on a priced event, whether
// they paid. The wrapper lays out every RSVP on the event the way GoingRsvps
// does, so one story compares several players.
module Query = %relay(`
  query EventRsvpStoryQuery {
    event(id: "evt-story-1") {
      id
      rsvps(first: 20) {
        edges {
          node {
            id
            rating {
              mu
            }
            ...EventRsvp_rsvp
          }
        }
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventRsvpStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~activitySlug: [#pickleball | #badminton]=#pickleball,
  ~isAdmin=false,
  // The event's price in yen; any price shows the Paid / Not paid badges.
  ~eventPrice: option<int>=?,
  // Number the players as the waitlist does (#1, #2, ...).
  ~waitlist=false,
  // The signed-in player, whose entry is drawn larger.
  ~viewerId: option<string>=?,
) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    let nodes =
      event.rsvps
      ->Option.flatMap(c => c.edges)
      ->Option.getOr([])
      ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
    // As RSVPSection: the highest mu on the event is the full ring.
    let maxRating = nodes->Array.reduce(0., (max, node) => {
      let mu = node.rating->Option.flatMap(r => r.mu)->Option.getOr(0.)
      mu > max ? mu : max
    })
    let viewer: option<RSVPSection_user_graphql.Types.fragment> = viewerId->Option.map(id => {
      RSVPSection_user_graphql.Types.id,
      lineUsername: None,
      eventRating: None,
    })
    <div className="flex flex-wrap gap-3 max-w-3xl font-sans">
      {nodes
      ->Array.mapWithIndex((node, i) =>
        <EventRsvp
          key=node.id
          eventId=event.id
          rsvp=node.fragmentRefs
          viewer
          activitySlug={Some((activitySlug :> string))}
          maxRating
          isAdmin
          ?eventPrice
          waitlistPosition=?{waitlist ? Some(i + 1) : None}
        />
      )
      ->React.array}
    </div>
  | None => React.null
  }
}

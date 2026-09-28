// Storybook support for PkEventRsvp.stories.tsx; the app never imports this.
// PkEventRsvp is one player on the pickleball event page's RSVP section
// (PkRSVPSection): a chip on the confirmed, pending and invited lists, a
// numbered row on the waitlist. The wrapper lays out every RSVP on the event
// in the chosen list's container, as PkRSVPSection does.
module Query = %relay(`
  query PkEventRsvpStoryQuery {
    event(id: "evt-story-1") {
      id
      rsvps(first: 20) {
        edges {
          node {
            id
            user {
              id
              selfRating
              dupr {
                doubles
                doublesReliable
                doublesReliability
              }
            }
            rating {
              mu
              sigma
            }
            ...PkEventRsvp_rsvp
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
let query: concreteRequest = PkEventRsvpStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  ~list: [#confirmed | #waitlist | #pending | #invited]=#confirmed,
  ~isAdmin=false,
  ~chargesEnabled=false,
  // Competitive events show each player's rating; casual ones hide it.
  ~showRating=true,
  // The organizer's user id: their chip gets the host star.
  ~hostId: option<string>=?,
) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    let nodes =
      event.rsvps
      ->Option.flatMap(c => c.edges)
      ->Option.getOr([])
      ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
    // As PkRSVPSection: the highest combined-rating mu is the full ring.
    let maxRating = nodes->Array.reduce(0., (max, node) => {
      let mu =
        node.user
        ->Option.flatMap(user =>
          CombinedRating.resolve(
            ~pkuruMu=node.rating->Option.flatMap(r => r.mu),
            ~pkuruSigma=?node.rating->Option.flatMap(r => r.sigma),
            ~duprDoubles=user.dupr->Option.flatMap(d => d.doubles),
            ~duprReliability=?user.dupr->Option.flatMap(d => d.doublesReliability),
            ~duprReliable=user.dupr->Option.map(d => d.doublesReliable)->Option.getOr(false),
            ~selfMu=user.selfRating,
          )
        )
        ->Option.map(CombinedRating.mu)
        ->Option.getOr(0.)
      mu > max ? mu : max
    })
    let maxRating = maxRating == 0. ? 1. : maxRating
    let render = (node: PkEventRsvpStoryQuery_graphql.Types.response_event_rsvps_edges_node, i) => {
      let isHost =
        hostId
        ->Option.flatMap(hostId => node.user->Option.map(user => user.id == hostId))
        ->Option.getOr(false)
      <PkEventRsvp
        key=node.id
        eventId=event.id
        rsvp=node.fragmentRefs
        activitySlug="pickleball"
        maxRating
        isAdmin
        chargesEnabled
        isHost
        showRating
        waitlistPosition=?{list == #waitlist ? Some(i + 1) : None}
        isPending={list == #pending}
        isInvited={list == #invited}
        connectionKey="PkRSVPSection_event_rsvps"
      />
    }
    <div className="max-w-md font-sans">
      {switch list {
      | #waitlist =>
        <div className="flex flex-col gap-0.5">
          {nodes->Array.mapWithIndex(render)->React.array}
        </div>
      | #invited =>
        <ul className="flex flex-wrap gap-1.5">
          {nodes
          ->Array.mapWithIndex((node, i) =>
            <li key=node.id className="relative"> {render(node, i)} </li>
          )
          ->React.array}
        </ul>
      | #confirmed | #pending =>
        <div className="flex flex-wrap gap-1.5">
          {nodes->Array.mapWithIndex(render)->React.array}
        </div>
      }}
    </div>
  | None => React.null
  }
}

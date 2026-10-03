// Storybook support for EventInvites.stories.tsx; the app never imports this.
// EventInvites is the invite strip under PkRSVPSection's lists. It loads its
// own candidates (availabilityUsersForDay, inviteRecommendations) when the
// viewer can invite; the rest comes from the section as props. The wrapper
// reads the event's RSVPs the way the section does, under the same
// connection, so an invite sent from a story lands as a "sent" chip.
module Query = %relay(`
  query EventInvitesStoryQuery {
    event(id: "evt-story-1") {
      id
      rsvps(first: 50) @connection(key: "PkRSVPSection_event_rsvps") {
        edges {
          node {
            id
            listType
            user {
              id
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
let query: concreteRequest = EventInvitesStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  // The organizer (and not a venue-run shadow event). Players see only the
  // invites already sent.
  ~canInvite=true,
  // The signed-in viewer, never suggested to themselves.
  ~viewerId="user-kenji",
) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    let rsvps =
      event.rsvps
      ->Option.flatMap(c => c.edges)
      ->Option.getOr([])
      ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
    let invited = rsvps->Array.filter(n => n.listType == Some(2))
    <div className="mx-auto max-w-2xl bg-gray-50 py-3 dark:bg-[#18191c]">
      <div
        className="mx-3 rounded-xl border border-gray-200 bg-white px-4 py-4 dark:border-[#2a2b30] dark:bg-[#1e1f23]">
        <EventInvites
          eventId=event.id
          canInvite
          activityId=Some("act-pickleball")
          activitySlug=Some("pickleball")
          clubId=None
          eventTitle="Thursday Night Doubles"
          venueName="Ariake Tennis Forest Park"
          startDate=Some(Date.fromString(StoryFixturesEvent.startDate)->Util.Datetime.fromDate)
          endDate=Some(Date.fromString(StoryFixturesEvent.endDate)->Util.Datetime.fromDate)
          timezone="Asia/Tokyo"
          participantUserIds={rsvps
          ->Array.filterMap(n => n.user->Option.map(u => u.id))
          ->Array.concat([viewerId])}
          invitedCount={invited->Array.length}
          invitedChips={_threadUserIds =>
            invited
          ->Array.map(node =>
            <li key=node.id className="relative">
              <PkEventRsvp
                eventId=event.id
                rsvp=node.fragmentRefs
                activitySlug="pickleball"
                // The shared roster's strongest mu, as the section computes it.
                maxRating=38.6
                isAdmin=canInvite
                chargesEnabled=false
                isInvited=true
                showRating=false
                connectionKey="PkRSVPSection_event_rsvps"
              />
            </li>
          )
          ->React.array}
        />
      </div>
    </div>
  | None => React.null
  }
}

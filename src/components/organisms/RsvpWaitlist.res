%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment RsvpWaitlist_event on Event
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 80 }
  )
  {
    id
    maxRsvps
    viewerIsAdmin
    rsvps(after: $after, first: $first, before: $before)
      @connection(key: "RSVPSection_event_rsvps") {
      edges {
        node {
          id
          ...EventRsvp_rsvp
          ...MiniEventRsvp_rsvp
          user {
            id
            picture
            lineUsername
          }
          rating {
            ordinal
            mu
            sigma
          }
          listType
          message
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
      }
      }
  }
`)

@react.component
let make = (
  ~event: RescriptRelay.fragmentRefs<[> #RsvpWaitlist_event]>,
  ~viewer: option<RSVPSection_user_graphql.Types.fragment>=?,
  ~activitySlug: option<string>=?,
  ~className: option<string>=?,
) => {
  let eventData = Fragment.use(event)
  let rsvps = eventData.rsvps->Fragment.getConnectionNodes

  // Calculate waitlist based on maxRsvps - logic from RSVPSection
  let isWaitlist = count => {
    eventData.maxRsvps->Option.map(max => count >= max)->Option.getOr(false)
  }

  let waitlistRsvps = rsvps->Array.filterWithIndex((_, i) => isWaitlist(i))

  if waitlistRsvps->Array.length == 0 {
    React.null
  } else {
    <div ?className>
      <RsvpListTitle
        title={t`Waitlist`} count={waitlistRsvps->Array.length} className=?Some("mb-3")
      />
      <OrderedRsvpList items=waitlistRsvps>
        {(~index as _index, ~item as rsvp) =>
          <EventRsvp
            eventId=eventData.id
            rsvp={rsvp.fragmentRefs}
            viewer
            activitySlug
            maxRating={0.0}
            isAdmin=eventData.viewerIsAdmin
          />}
      </OrderedRsvpList>
    </div>
  }
}

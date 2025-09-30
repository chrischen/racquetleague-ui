%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment PendingRsvps_event on Event
  @argumentDefinitions(
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 80 }
  )
  {
    id
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

let isRestrictedRsvp = listType => listType != Some(0) && listType != None

@react.component
let make = (
  ~event: RescriptRelay.fragmentRefs<[> #PendingRsvps_event]>,
  ~viewer: option<RSVPSection_user_graphql.Types.fragment>=?,
  ~activitySlug: option<string>=?,
  ~maxRating: float,
  ~className: option<string>=?,
) => {
  let eventData = Fragment.use(event)
  let rsvps = eventData.rsvps->Fragment.getConnectionNodes

  // Filter to only show restricted/pending RSVPs
  let restrictedRsvps = rsvps->Array.filter(edge => isRestrictedRsvp(edge.listType))

  // Only render if there are pending RSVPs
  if restrictedRsvps->Array.length == 0 {
    React.null
  } else {
    <div ?className>
      <RsvpListTitle
        title={t`Pending`} count={restrictedRsvps->Array.length} className=?Some("mb-3")
      />
      <div className="flex flex-wrap gap-3">
        {restrictedRsvps
        ->Array.map(edge =>
          <EventRsvp
            eventId=eventData.id
            key={edge.id}
            rsvp={edge.fragmentRefs}
            viewer
            activitySlug
            maxRating
            isAdmin=eventData.viewerIsAdmin
          />
        )
        ->React.array}
      </div>
    </div>
  }
}

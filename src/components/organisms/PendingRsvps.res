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
    price
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
          paid
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
  // From a Smart RSVP preview: the ids of the RSVPs here the next run would
  // admit. They are marked; nothing has moved.
  ~previewAdmittedIds: option<array<string>>=?,
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
        ->Array.map(edge => {
          let card =
            <EventRsvp
              eventId=eventData.id
              key={edge.id}
              rsvp={edge.fragmentRefs}
              viewer
              activitySlug
              maxRating
              isAdmin=eventData.viewerIsAdmin
              eventPrice=?eventData.price
            />
          let wouldBeAdmitted =
            previewAdmittedIds->Option.map(ids => ids->Array.includes(edge.id))->Option.getOr(false)
          // The badge sits in the flow, straddling the ring, so the entry is
          // at least as wide as the badge and the card sits below it.
          wouldBeAdmitted
            ? <div
                key={edge.id}
                className="relative flex flex-col items-start rounded-xl ring-2 ring-emerald-500 ring-offset-2 dark:ring-offset-gray-900">
                <span
                  className="relative z-10 -mt-2 ml-2 whitespace-nowrap rounded-full bg-emerald-600 px-2 py-0.5 text-[10px] font-semibold text-white">
                  {t`Would be admitted`}
                </span>
                card
              </div>
            : card
        })
        ->React.array}
      </div>
    </div>
  }
}

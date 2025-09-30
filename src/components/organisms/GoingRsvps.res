%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment GoingRsvps_event on Event
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
  ~event: RescriptRelay.fragmentRefs<[> #GoingRsvps_event]>,
  ~viewer: option<RSVPSection_user_graphql.Types.fragment>=?,
  ~activitySlug: option<string>=?,
  ~maxRating: float,
  ~className: option<string>=?,
) => {
  let ts = Lingui.UtilString.t
  let eventData = Fragment.use(event)
  let rsvps = eventData.rsvps->Fragment.getConnectionNodes

  // UI state for expansion
  let (expanded, setExpanded) = React.useState(() => false)
  let initialDisplayCount = 3

  // Calculate waitlist threshold and filter confirmed RSVPs
  let isWaitlist = count => {
    eventData.maxRsvps->Option.map(max => count >= max)->Option.getOr(false)
  }

  let mainList = rsvps->Array.filter(edge => edge.listType == None || edge.listType == Some(0))
  let confirmedRsvps =
    mainList
    ->Array.filterWithIndex((_, i) => !isWaitlist(i))
    ->Array.toSorted((a, b) => {
      let userA = a.rating->Option.flatMap(rating => rating.mu)->Option.getOr(0.)
      let userB = b.rating->Option.flatMap(rating => rating.mu)->Option.getOr(0.)
      userB > userA ? 1. : userB < userA ? -1. : 0.
    })

  let displayedGoingRsvps = expanded
    ? confirmedRsvps
    : confirmedRsvps->Array.slice(~start=0, ~end=initialDisplayCount)

  <div ?className>
    <div className="flex justify-between items-center mb-3">
      <RsvpListTitle
        title={t`Going`} count={confirmedRsvps->Array.length} max=?{eventData.maxRsvps}
      />
    </div>
    <div className="flex flex-wrap gap-3">
      {displayedGoingRsvps
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
      {!expanded && confirmedRsvps->Array.length > initialDisplayCount
        ? <div
            className="flex items-center cursor-pointer text-blue-600 hover:text-blue-800 bg-blue-50 hover:bg-blue-100 rounded-full px-3 py-1"
            onClick={_ => setExpanded(_ => true)}>
            <span className="text-sm font-medium">
              {(
                ts`+${(confirmedRsvps->Array.length - initialDisplayCount)->Int.toString} more`
              )->React.string}
            </span>
            <Lucide.ChevronDown size=16 className="ml-1" />
          </div>
        : React.null}
      {!expanded &&
      confirmedRsvps->Array.length <= initialDisplayCount &&
      confirmedRsvps->Array.length > 0
        ? <div
            className="flex items-center cursor-pointer text-blue-600 hover:text-blue-800 bg-blue-50 hover:bg-blue-100 rounded-full px-3 py-1"
            onClick={_ => setExpanded(_ => true)}>
            <span className="text-sm font-medium"> {t`See all`} </span>
            <Lucide.ChevronDown size=16 className="ml-1" />
          </div>
        : React.null}
      {expanded
        ? <div className="text-center mt-3">
            <a
              className="text-sm font-medium text-blue-600 hover:text-blue-800 cursor-pointer"
              onClick={_ => setExpanded(_ => false)}>
              {t`Show less`}
            </a>
          </div>
        : React.null}
    </div>
  </div>
}

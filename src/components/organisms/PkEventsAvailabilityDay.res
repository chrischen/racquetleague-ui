%%raw("import { t } from '@lingui/macro'")

// Client-only availability row for one events-list day bucket.
// Mounted only after the geolocation permission prompt resolves (granted or
// denied) — see UseUserLocation.useStatus — so `location` is the resolved
// coords (or the fallback). Every Day mounts this with identical variables,
// so Relay dedupes the concurrent requests into one and all instances read
// the same root store fields.
module Query = %relay(`
  query PkEventsAvailabilityDayQuery(
    $activityId: ID!
    $fromDate: String!
    $toDate: String!
    $location: LocationInput!
    $locationId: ID!
    $byLocation: Boolean!
  ) {
    viewer {
      user {
        id
      }
      availability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate) {
        id
        localDate
        intervals {
          startHour
          endHour
        }
        ...PlayIntentRow_availabilityDay
      }
      events(first: 100, _filters: {viewer: true}) {
        edges {
          node {
            id
            title
            startDate
            endDate
            timezone
          }
        }
      }
    }
    availabilityUsersForDateRange(
      fromDate: $fromDate
      toDate: $toDate
      location: $location
      scope: {activityId: $activityId}
    ) {
      id
      localDate
      user {
        id
        lineUsername
        picture
      }
      intervals {
        startHour
        endHour
      }
    }
    locationsAvailability(
      activityId: $activityId
      fromDate: $fromDate
      toDate: $toDate
      location: $location
    ) @skip(if: $byLocation) {
      id
      localDate
      link
      location {
        id
        name
      }
      intervals {
        startHour
        endHour
      }
      hourly {
        hour
        indoorCount
        outdoorCount
        priceMin
        priceMax
      }
    }
    locationAvailability(
      activityId: $activityId
      fromDate: $fromDate
      toDate: $toDate
      locationId: $locationId
    ) @include(if: $byLocation) {
      id
      localDate
      link
      location {
        id
        name
      }
      intervals {
        startHour
        endHour
      }
      hourly {
        hour
        indoorCount
        outdoorCount
        priceMin
        priceMax
      }
    }
  }
`)

// Uniform court-availability row, projected from whichever source the query
// fetched: coordinate-scoped `locationsAvailability` (Discover) or single-
// location `locationAvailability` (a location's events list). Both fields carry
// identical selections but are nominally distinct generated types, so we
// normalize them here.
type courtRow = {
  id: string,
  localDate: string,
  link: option<string>,
  locationId: option<string>,
  locationName: option<string>,
  intervals: array<(int, int)>,
  hourlyStats: array<TimeWindow.hourStat>,
}

let courtRowsFromData = (
  data: PkEventsAvailabilityDayQuery_graphql.Types.response,
): array<courtRow> =>
  Belt.Array.concat(
    data.locationsAvailability
    ->Option.getOr([])
    ->Array.map((r): courtRow => {
      id: r.id,
      localDate: r.localDate,
      link: r.link,
      locationId: r.location->Option.map(l => l.id),
      locationName: r.location->Option.flatMap(l => l.name),
      intervals: r.intervals->Array.map(iv => (iv.startHour, iv.endHour)),
      hourlyStats: r.hourly->Array.map((h): TimeWindow.hourStat => {
        hour: h.hour,
        indoorCount: h.indoorCount,
        outdoorCount: h.outdoorCount,
        priceMin: h.priceMin,
        priceMax: h.priceMax,
      }),
    }),
    data.locationAvailability
    ->Option.getOr([])
    ->Array.map((r): courtRow => {
      id: r.id,
      localDate: r.localDate,
      link: r.link,
      locationId: r.location->Option.map(l => l.id),
      locationName: r.location->Option.flatMap(l => l.name),
      intervals: r.intervals->Array.map(iv => (iv.startHour, iv.endHour)),
      hourlyStats: r.hourly->Array.map((h): TimeWindow.hourStat => {
        hour: h.hour,
        indoorCount: h.indoorCount,
        outdoorCount: h.outdoorCount,
        priceMin: h.priceMin,
        priceMax: h.priceMax,
      }),
    }),
  )

// Map the day's court rows to court entities. A row may not have a resolved
// Location yet (the scraper keyed availability before the venue was
// registered); fall back to the booking `link` as a stable per-venue identity
// so those courts still render and reserve. Shared with PkEventsDayFeed so the
// picker and the inline pseudo-event rows agree.
let courtAvailabilityForDate = (
  rows: array<courtRow>,
  ~localDate: string,
  ~genericCourtName: string,
): array<TimeWindow.courtAvailability> =>
  rows
  ->Array.filter(d => d.localDate == localDate)
  ->Array.map((d): TimeWindow.courtAvailability => {
    let locId = d.locationId->Option.orElse(d.link)->Option.getOr(d.id)
    {
      id: d.id,
      location: {
        id: locId,
        name: d.locationName->Option.getOr(genericCourtName),
        reservationUrl: d.link,
      },
      courtName: None,
      hourlyStats: d.hourlyStats,
      intents: d.intervals->Array.mapWithIndex(
        ((s, e), i): TimeWindow.playIntent => {
          id: i,
          start: s->Float.fromInt,
          end: e->Float.fromInt,
        },
      ),
    }
  })

@react.component
let make = (
  ~localDate: string,
  ~dateGroup: string,
  ~fromDate: string,
  ~toDate: string,
  ~activityId: string,
  ~location: UseUserLocation.location,
  ~fetchKey: int,
  ~onRefetchNeeded: unit => unit,
  ~isLoggedIn: bool,
  ~onCreateEvent: unit => unit,
  ~renderHeader: React.element => React.element,
  // When set, court availability is scoped to this single location (a location's
  // events list) via `locationAvailability`; otherwise it's coordinate-scoped.
  ~locationId: option<string>=?,
) => {
  let fetchPolicy = fetchKey > 0 ? RescriptRelay.StoreAndNetwork : RescriptRelay.StoreOrNetwork
  let data = Query.use(
    ~variables={
      activityId,
      fromDate,
      toDate,
      location,
      locationId: locationId->Option.getOr(""),
      byLocation: locationId->Option.isSome,
    },
    ~fetchKey=Int.toString(fetchKey),
    ~fetchPolicy,
  )

  let viewerUserId = data.viewer->Option.flatMap(v => v.user)->Option.map(u => u.id)

  let allUserDays = data.availabilityUsersForDateRange->Array.map((d): PlayIntentRow.userDay => {
    id: d.id,
    localDate: d.localDate,
    user: d.user->Option.map((u): PlayIntentRow.userDayUser => {
      id: u.id,
      lineUsername: u.lineUsername,
      picture: u.picture,
    }),
    intervals: d.intervals->Array.map((iv): PlayIntentRow.userDayInterval => {
      startHour: iv.startHour,
      endHour: iv.endHour,
    }),
  })

  let userDays =
    allUserDays
    ->Array.filter(d => d.localDate == localDate)
    ->Array.filter(d =>
      switch viewerUserId {
      | None => true
      | Some(vid) => d.user->Option.map(u => u.id)->Option.getOr("") != vid
      }
    )

  let availabilityDay =
    data.viewer
    ->Option.flatMap(v => v.availability->Array.find(d => d.localDate == localDate))
    ->Option.map(d => d.fragmentRefs)

  // Court (venue) open hours near the caller for this day bucket.
  let genericCourtName = Lingui.UtilString.t`Court`
  let courtAvailability = courtAvailabilityForDate(
    courtRowsFromData(data),
    ~localDate,
    ~genericCourtName,
  )

  // The viewer's own RSVP'd events for this day, rendered as the amber layer of
  // the picker's russian-doll timeline. Hours are resolved per-event-timezone
  // via the shared EventTimeline helper, then filtered to this day bucket.
  let intl = ReactIntl.useIntl()
  let events =
    data.viewer
    ->Option.map(v =>
      v.events.edges
      ->Option.getOr([])
      ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
      ->Array.map((node): EventTimeline.rawEvent => {
        id: node.id,
        title: node.title,
        startDate: node.startDate,
        endDate: node.endDate,
        timezone: node.timezone,
      })
      ->(raw => EventTimeline.byDate(intl, raw))
    )
    ->Option.getOr(Js.Dict.empty())
    ->Js.Dict.get(localDate)
    ->Option.getOr([])

  let onAvailabilityCommitted = (updatedDay: option<PlayIntentRow.userDay>) => {
    let needsRefetch = switch updatedDay {
    | None => true // deletion: Relay won't remove the node from linked arrays
    | Some(day) => !(allUserDays->Array.some(d => d.id == day.id)) // new node
    }
    if needsRefetch {
      onRefetchNeeded()
    }
  }

  <PlayIntentRow
    localDate
    dateGroup
    ?availabilityDay
    activityId
    userDays
    courtAvailability
    events
    onAvailabilityCommitted
    onChange={_ => ()}
    isLoggedIn
    onCreateEvent
    renderHeader
  />
}

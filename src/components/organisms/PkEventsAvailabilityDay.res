%%raw("import { t } from '@lingui/macro'")

// Availability row for one events-list day bucket, fed from the host page's
// root query (spread this fragment there) — no geolocation gate. Scope follows
// the server's location-input → user.coords → Tokyo precedence: the page loader
// fills the `location` argument from the `coords` URL param (the location
// filter — see LocationFilterControl) when present, and leaves it null otherwise
// so the server falls back to the viewer's stored coords, then Tokyo. Changing
// the filter rewrites that param and re-runs the loader, which re-scopes.
module Fragment = %relay(`
  fragment PkEventsAvailabilityDay_query on Query
  @refetchable(queryName: "PkEventsAvailabilityDayRefetchQuery")
  @argumentDefinitions(
    activityId: { type: "ID", defaultValue: "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61" }
    fromDate: { type: "String!" }
    toDate: { type: "String!" }
    # No default: an absent/null location tells the server to resolve scope from
    # the viewer's stored coords (user.coords), then Tokyo — matching its
    # location-input → user.coords → Tokyo precedence.
    location: { type: "LocationInput" }
    locationId: { type: "ID", defaultValue: "" }
    byLocation: { type: "Boolean", defaultValue: false }
  )
  {
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
  data: PkEventsAvailabilityDay_query_graphql.Types.fragment,
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
  // The host page's fragment data, read once by PkEventsList and shared by
  // every Day bucket. Court scoping (coordinate- vs single-location) is fixed
  // by the page query's fragment arguments (`byLocation` / `locationId`).
  ~data: PkEventsAvailabilityDay_query_graphql.Types.fragment,
  ~localDate: string,
  ~dateGroup: string,
  ~activityId: string,
  ~onRefetchNeeded: unit => unit,
  ~isLoggedIn: bool,
  ~onCreateEvent: unit => unit,
  ~renderHeader: React.element => React.element,
  ~requireProfile: (unit => unit) => unit=action => action(),
) => {
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
    requireProfile
  />
}

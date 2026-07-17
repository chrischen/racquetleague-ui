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
  ) {
    viewer {
      user {
        id
      }
      availability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate) {
        id
        localDate
        ...PlayIntentRow_availabilityDay
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
  }
`)

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
) => {
  let fetchPolicy = fetchKey > 0 ? RescriptRelay.StoreAndNetwork : RescriptRelay.StoreOrNetwork
  let data = Query.use(
    ~variables={activityId, fromDate, toDate, location},
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
    onAvailabilityCommitted
    onChange={_ => ()}
    isLoggedIn
    onCreateEvent
    renderHeader
  />
}

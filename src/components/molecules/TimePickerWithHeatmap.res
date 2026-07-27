module HourlyCountsQuery = %relay(`
  query TimePickerWithHeatmapHourlyCountsQuery(
    $localDate: String!
    $activityId: ID!
    $clubId: ID
    $location: LocationInput
  ) {
    availabilityHourlyCounts(
      localDate: $localDate
      activityId: $activityId
      clubId: $clubId
      location: $location
    ) {
      hour
      count
    }
  }
`)

let defaultActivityId = "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"

@react.component
let make = (
  ~localDate: string,
  ~draft: array<TimeWindow.playIntent>,
  ~onChange: array<TimeWindow.playIntent> => unit,
  ~activityId: option<string>=?,
  ~clubId: option<string>=?,
  ~courtAvailability: array<TimeWindow.courtAvailability>=[],
  ~existingEvents: array<TimeWindowPicker.existingEvent>=[],
) => {
  let resolvedActivityId = activityId->Option.getOr(defaultActivityId)
  // Send the geolocation-resolved coords only when actually granted (as a coords
  // LocationInput); otherwise leave `location` out so the server resolves the
  // viewer's stored coords, then the default (location-input → user.coords → ...).
  let location = UseUserLocation.useOption()->Option.map(UseUserLocation.locationInputOfCoords)
  let queryData = HourlyCountsQuery.use(
    ~variables={localDate, activityId: resolvedActivityId, ?clubId, ?location},
  )
  let hourCounts = queryData.availabilityHourlyCounts
  let maxCount = hourCounts->Array.reduce(0, (acc, hc) => Js.Math.max_int(acc, hc.count))

  <TimeWindowPicker
    intents=draft
    onChange
    demandCounts={hourCounts->Array.map((hc): TimeWindowPicker.hourCount => {
      hour: hc.hour,
      count: hc.count,
    })}
    maxDemand=maxCount
    courtAvailability
    existingEvents
  />
}

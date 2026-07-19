module HourlyCountsQuery = %relay(`
  query TimePickerWithHeatmapHourlyCountsQuery(
    $localDate: String!
    $activityId: ID!
    $clubId: ID
    $location: LocationInput!
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
  ~draft: array<TimeWindowPicker.playIntent>,
  ~onChange: array<TimeWindowPicker.playIntent> => unit,
  ~activityId: option<string>=?,
  ~clubId: option<string>=?,
  ~courtAvailability: array<TimeWindowPicker.courtAvailability>=[],
  ~onUseCourtSlot: option<TimeWindowPicker.courtSlotGroup => unit>=?,
) => {
  let resolvedActivityId = activityId->Option.getOr(defaultActivityId)
  // Only mounted from the availability editor, i.e. after the geolocation
  // permission has resolved, so this is the resolved location (or fallback).
  let location = UseUserLocation.use()
  let queryData = HourlyCountsQuery.use(
    ~variables={localDate, activityId: resolvedActivityId, ?clubId, location},
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
    ?onUseCourtSlot
  />
}

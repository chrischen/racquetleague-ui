module HourlyCountsQuery = %relay(`
  query TimePickerWithHeatmapHourlyCountsQuery(
    $localDate: String!
    $activityId: ID!
    $clubId: ID
  ) {
    availabilityHourlyCounts(
      localDate: $localDate
      activityId: $activityId
      clubId: $clubId
    ) {
      hour
      count
    }
  }
`)

let defaultActivityId = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"

@react.component
let make = (
  ~localDate: string,
  ~draft: array<TimeWindowPicker.playIntent>,
  ~onChange: array<TimeWindowPicker.playIntent> => unit,
  ~activityId: option<string>=?,
  ~clubId: option<string>=?,
) => {
  let resolvedActivityId = activityId->Option.getOr(defaultActivityId)
  let queryData = HourlyCountsQuery.use(~variables={localDate, activityId: resolvedActivityId, ?clubId})
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
  />
}

// Shared setAvailabilityDay mutation hook — the one place that owns the
// mutation document and input construction for marking the viewer available
// on a day. The selection is the union of every consumer's needs (PlayIntentRow
// maps day.user/intervals to a userDay; others only check day presence), and
// completion behavior stays caller-owned via ~onCompleted since each surface
// reacts differently (refetch, store invalidation, result mapping).
//
// `location` is sourced from UseUserLocation internally: availability writes
// are always keyed by the viewer's resolved coords (or the fallback), same as
// every previous call site.

module Mutation = %relay(`
  mutation UseSetAvailabilityDayMutation($input: SetAvailabilityDayInput!) {
    setAvailabilityDay(input: $input) {
      day {
        id
        localDate
        user {
          id
          picture
          lineUsername
        }
        intervals {
          startHour
          endHour
        }
      }
      errors {
        message
      }
    }
  }
`)

// Convert picker intents (float hours) to mutation interval inputs. Whole-hour
// snapping upstream makes truncation exact.
let intervalsOfIntents = (
  intents: array<TimeWindow.playIntent>,
): array<RelaySchemaAssets_graphql.input_IntervalInput> =>
  intents->Array.map((i): RelaySchemaAssets_graphql.input_IntervalInput => {
    startHour: i.start->Float.toInt,
    endHour: i.end->Float.toInt,
  })

let use = () => {
  let (commit, isMutating) = Mutation.use()
  let location = UseUserLocation.use()
  let commitDay = (
    ~localDate: string,
    ~activityId: string,
    ~intervals: array<RelaySchemaAssets_graphql.input_IntervalInput>,
    ~onCompleted: option<
      (
        UseSetAvailabilityDayMutation_graphql.Types.response,
        option<array<RescriptRelay.mutationError>>,
      ) => unit,
    >=?,
  ) =>
    commit(
      ~variables={input: {localDate, activityId, location, intervals}},
      ~onCompleted=?onCompleted,
    )
  (commitDay, isMutating)
}

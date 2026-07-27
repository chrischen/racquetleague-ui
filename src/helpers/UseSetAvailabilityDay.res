// Shared setAvailabilityDay mutation hook — the one place that owns the
// mutation document and input construction for marking the viewer available
// on a day. The selection is the union of every consumer's needs (PlayIntentRow
// maps day.user/intervals to a userDay; others only check day presence), and
// completion behavior stays caller-owned via ~onCompleted since each surface
// reacts differently (refetch, store invalidation, result mapping).
//
// No location input: the server keys availability off the viewer's stored
// coords (User.coords), so callers only supply the day, activity, and intervals.

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
      ~variables={input: {localDate, activityId, intervals}},
      ~onCompleted=?onCompleted,
    )
  (commitDay, isMutating)
}

// Batch variant — one activity, many days, one round-trip (see the events
// availability grid, which saves every edited day at once). `location` is
// omitted for the same reason as the singular: the server keys off the viewer's
// stored coords.
module DaysMutation = %relay(`
  mutation UseSetAvailabilityDaysMutation($input: SetAvailabilityDaysInput!) {
    setAvailabilityDays(input: $input) {
      days {
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

let useSetDays = () => {
  let (commit, isMutating) = DaysMutation.use()
  let commitDays = (
    ~activityId: string,
    ~days: array<RelaySchemaAssets_graphql.input_AvailabilityDayInput>,
    ~onCompleted: option<
      (
        UseSetAvailabilityDaysMutation_graphql.Types.response,
        option<array<RescriptRelay.mutationError>>,
      ) => unit,
    >=?,
  ) =>
    commit(
      ~variables={input: {activityId, days}},
      ~onCompleted=?onCompleted,
    )
  (commitDays, isMutating)
}

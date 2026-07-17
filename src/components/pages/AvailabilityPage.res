%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query AvailabilityPageQuery($activityId: ID!, $fromDate: String!, $toDate: String!, $afterDate: Datetime, $location: LocationInput!) {
    availabilityUsersForDateRange(
      fromDate: $fromDate
      toDate: $toDate
      location: $location
      scope: {activityId: "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"}
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
    viewer {
      availability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate) {
        id
        localDate
        intervals {
          startHour
          endHour
        }
      }
      events(first: 100, _filters: {viewer: true}, afterDate: $afterDate) {
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
  }
`)

module SetAvailabilityMutation = %relay(`
  mutation AvailabilityPageSetAvailabilityMutation($input: SetAvailabilityDayInput!) {
    setAvailabilityDay(input: $input) {
      day {
        id
        localDate
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

let defaultActivityId = "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"

let getDateRange = () => {
  let now = Js.Date.make()
  let fmtDate = (d: Js.Date.t) => {
    let y = d->Js.Date.getFullYear->Float.toInt->Int.toString
    let m = (d->Js.Date.getMonth->Float.toInt + 1)->Int.toString->String.padStart(2, "0")
    let day = d->Js.Date.getDate->Float.toInt->Int.toString->String.padStart(2, "0")
    y ++ "-" ++ m ++ "-" ++ day
  }
  let fromDate = fmtDate(now)
  let toDate = fmtDate(Js.Date.fromFloat(now->Js.Date.getTime +. Float.fromInt(14 * 86400000)))
  (fromDate, toDate)
}

module AvailabilityContent = {
  @react.component
  let make = () => {
    let (fromDate, toDate) = React.useMemo0(getDateRange)
    let location = UseUserLocation.use()
    let {viewer, availabilityUsersForDateRange} = Query.use(
      ~variables={
        activityId: defaultActivityId,
        fromDate,
        toDate,
        afterDate: Util.Datetime.fromDate(Js.Date.make()),
        location,
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    )
    let intl = ReactIntl.useIntl()
    let (isSaving, setIsSaving) = React.useState(() => false)
    let (commitSetAvailability, _) = SetAvailabilityMutation.use()
    let env = RescriptRelay.useEnvironmentFromContext()

    let getWeekDays = () => {
      let now = Js.Date.make()
      Belt.Array.makeBy(15, i => {
        let d = Js.Date.fromFloat(now->Js.Date.getTime +. Float.fromInt(i * 86400000))
        let y = d->Js.Date.getFullYear->Float.toInt->Int.toString
        let m = (d->Js.Date.getMonth->Float.toInt + 1)->Int.toString->String.padStart(2, "0")
        let day = d->Js.Date.getDate->Float.toInt->Int.toString->String.padStart(2, "0")
        let isoDate = y ++ "-" ++ m ++ "-" ++ day
        let shortLabel =
          intl->ReactIntl.Intl.formatDateWithOptions(
            d,
            ReactIntl.dateTimeFormatOptions(~weekday=#short, ()),
          )
        let dateLabel =
          intl->ReactIntl.Intl.formatDateWithOptions(
            d,
            ReactIntl.dateTimeFormatOptions(~month=#short, ~day=#numeric, ()),
          )
        let dow = d->Js.Date.getDay->Float.toInt
        let isWeekend = dow === 0 || dow === 6
        (shortLabel, dateLabel, isoDate, isWeekend, i === 0)
      })
    }
    let availByDate =
      viewer
      ->Option.map(v => v.availability)
      ->Option.getOr([])
      ->Array.reduce(Js.Dict.empty(), (acc, day) => {
        acc->Js.Dict.set(day.localDate, day.intervals)
        acc
      })

    // Build per-ISO-date map of existing events (viewer's RSVPs)
    let existingEvents: Js.Dict.t<array<AvailabilityGrid.existingEvent>> =
      viewer
      ->Option.map(v =>
        v.events.edges
        ->Option.getOr([])
        ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
        ->Array.reduce(Js.Dict.empty(), (acc, node) => {
          switch (node.startDate, node.endDate) {
          | (Some(startDt), Some(endDt)) =>
            let tz = node.timezone->Option.getOr("Asia/Tokyo")
            let startDate = startDt->Util.Datetime.toDate
            let endDate = endDt->Util.Datetime.toDate
            let opts = ReactIntl.dateTimeFormatOptions(
              ~year=#numeric,
              ~month=#"2-digit",
              ~day=#"2-digit",
              ~hour=#"2-digit",
              ~hour12=false,
              ~timeZone=tz,
              (),
            )
            let parts = intl->ReactIntl.Intl.formatDateWithOptionsToParts(startDate, opts)
            let getVal = t =>
              parts
              ->Array.find(p => p.ReactIntl.type_ === t)
              ->Option.map(p => p.ReactIntl.value)
              ->Option.getOr("0")
            let year = getVal("year")
            let month = getVal("month")
            let day = getVal("day")
            let isoDate = year ++ "-" ++ month ++ "-" ++ day
            // startHour: get just the hour part
            let hourStr = getVal("hour")
            let startHour = hourStr->Int.fromString->Option.getOr(0)->Float.fromInt
            // endHour: format endDate the same way
            let endParts = intl->ReactIntl.Intl.formatDateWithOptionsToParts(endDate, opts)
            let endHourStr =
              endParts
              ->Array.find(p => p.ReactIntl.type_ === "hour")
              ->Option.map(p => p.ReactIntl.value)
              ->Option.getOr("0")
            let endHour = endHourStr->Int.fromString->Option.getOr(0)->Float.fromInt
            let ev: AvailabilityGrid.existingEvent = {
              id: node.id,
              title: node.title->Option.getOr(""),
              startHour,
              endHour: endHour <= startHour ? endHour +. 24.0 : endHour,
            }
            let existing = acc->Js.Dict.get(isoDate)->Option.getOr([])
            acc->Js.Dict.set(isoDate, Belt.Array.concat(existing, [ev]))
            acc
          | _ => acc
          }
        })
      )
      ->Option.getOr(Js.Dict.empty())

    let weekDays = getWeekDays()

    let days: array<AvailabilityGrid.dayData> = weekDays->Array.mapWithIndex((
      (shortLabel, dateLabel, isoDate, isWeekend, isToday),
      i,
    ) => {
      let intervals =
        availByDate
        ->Js.Dict.get(isoDate)
        ->Option.map(ivs =>
          ivs->Array.map(
            iv => {
              let r: AvailabilityGrid.interval = {startHour: iv.startHour, endHour: iv.endHour}
              r
            },
          )
        )
        ->Option.getOr([])

      let r: AvailabilityGrid.dayData = {
        dayIdx: i,
        label: shortLabel,
        dateLabel,
        isoDate,
        isWeekend,
        isToday,
        initialIntervals: intervals,
      }
      r
    })

    // Build per-ISO-date demand dict from other players' availability
    let demand: Js.Dict.t<array<VerticalAvailabilityGrid.playerDemand>> =
      availabilityUsersForDateRange->Array.reduce(Js.Dict.empty(), (acc, d) => {
        let pd: VerticalAvailabilityGrid.playerDemand = {
          id: d.id->String.length, // use string hash as int id
          intents: d.intervals->Array.mapWithIndex((iv, i): TimeWindowPicker.playIntent => {
            id: i,
            start: iv.startHour->Float.fromInt,
            end: iv.endHour->Float.fromInt,
          }),
        }
        let existing = acc->Js.Dict.get(d.localDate)->Option.getOr([])
        acc->Js.Dict.set(d.localDate, Belt.Array.concat(existing, [pd]))
        acc
      })

    let handleSave = (changes: array<AvailabilityGrid.intervalUpdate>) => {
      setIsSaving(_ => true)
      let pending = ref(changes->Array.length)
      changes->Array.forEach(change => {
        let _ = commitSetAvailability(
          ~variables={
            input: {
              localDate: change.isoDate,
              activityId: defaultActivityId,
              location,
              intervals: change.intervals->Array.map(
                iv => {
                  let r: RelaySchemaAssets_graphql.input_IntervalInput = {
                    startHour: iv.startHour,
                    endHour: iv.endHour,
                  }
                  r
                },
              ),
            },
          },
          ~onCompleted=(_res, _err) => {
            pending := pending.contents - 1
            if pending.contents <= 0 {
              setIsSaving(_ => false)
              RescriptRelay.commitLocalUpdate(
                ~environment=env,
                ~updater=store =>
                  store
                  ->RescriptRelay.RecordSourceSelectorProxy.getRoot
                  ->RescriptRelay.RecordProxy.invalidateRecord,
              )
            }
          },
        )
      })
    }

    <VerticalAvailabilityGrid.make days onSave=handleSave isSaving existingEvents demand />
  }
}

@react.component
let make = () => {
  // Availability is client-only: nothing renders during SSR/hydration, then
  // the page loads once the location permission prompt resolves either way.
  let geoStatus = UseUserLocation.useStatus()
  <WaitForMessages>
    {() =>
      switch geoStatus {
      | Resolving => React.null
      | Resolved(_) =>
        <React.Suspense fallback={React.null}>
          <AvailabilityContent />
        </React.Suspense>
      }}
  </WaitForMessages>
}

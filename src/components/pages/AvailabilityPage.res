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
    locationsAvailability(
      activityId: $activityId
      fromDate: $fromDate
      toDate: $toDate
      location: $location
    ) {
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
    viewer {
      user {
        id
        coords {
          lat
          lng
        }
      }
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

type loaderData = AvailabilityPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

module AvailabilityContent = {
  @react.component
  let make = (~queryRef: AvailabilityPageQuery_graphql.queryRef) => {
    let {viewer, availabilityUsersForDateRange, locationsAvailability} = Query.usePreloaded(
      ~queryRef,
    )
    let intl = ReactIntl.useIntl()
    let (isSaving, setIsSaving) = React.useState(() => false)
    let (commitSetAvailability, _) = UseSetAvailabilityDay.use()
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

    // Build per-ISO-date map of existing events (viewer's RSVPs). Timezone-aware
    // hour extraction is shared with the inline picker via EventTimeline.
    let existingEvents: Js.Dict.t<array<AvailabilityGrid.existingEvent>> =
      viewer
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

    // Build per-ISO-date dict of court (venue) open hours near the caller.
    // Each row carries its resolved Location and, when the scraper captured
    // one, a booking `link`; rows without a location are skipped.
    let genericCourtName = Lingui.UtilString.t`Court`
    let courtAvailability: Js.Dict.t<
      array<VerticalAvailabilityGrid.courtAvailability>,
    > = locationsAvailability->Array.reduce(Js.Dict.empty(), (acc, day) => {
      // A row may lack a resolved Location (scraped before the venue was
      // registered); fall back to the booking `link` as a stable per-venue
      // identity so the court still renders and reserves.
      let locId = day.location->Option.map(l => l.id)->Option.orElse(day.link)->Option.getOr(day.id)
      let court: VerticalAvailabilityGrid.courtAvailability = {
        id: day.id,
        location: {
          id: locId,
          name: day.location->Option.flatMap(l => l.name)->Option.getOr(genericCourtName),
          reservationUrl: day.link,
        },
        courtName: None,
        hourlyStats: day.hourly->Array.map((h): TimeWindow.hourStat => {
          hour: h.hour,
          indoorCount: h.indoorCount,
          outdoorCount: h.outdoorCount,
          priceMin: h.priceMin,
          priceMax: h.priceMax,
        }),
        intents: day.intervals->Array.mapWithIndex((iv, i): TimeWindow.playIntent => {
          id: i,
          start: iv.startHour->Float.fromInt,
          end: iv.endHour->Float.fromInt,
        }),
      }
      let existing = acc->Js.Dict.get(day.localDate)->Option.getOr([])
      acc->Js.Dict.set(day.localDate, Belt.Array.concat(existing, [court]))
      acc
    })

    // Build per-ISO-date demand dict from other players' availability
    let demand: Js.Dict.t<
      array<VerticalAvailabilityGrid.playerDemand>,
    > = availabilityUsersForDateRange->Array.reduce(Js.Dict.empty(), (acc, d) => {
      let pd: VerticalAvailabilityGrid.playerDemand = {
        id: d.id->String.length, // use string hash as int id
        intents: d.intervals->Array.mapWithIndex((iv, i): TimeWindow.playIntent => {
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
          ~localDate=change.isoDate,
          ~activityId=defaultActivityId,
          ~intervals=change.intervals->Array.map(
            iv => {
              let r: RelaySchemaAssets_graphql.input_IntervalInput = {
                startHour: iv.startHour,
                endHour: iv.endHour,
              }
              r
            },
          ),
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

    // Logged-in viewer with no stored home coords: capture them via the browser
    // geolocation prompt (renders nothing). The SSR'd query was scoped by the
    // default location; saving updates User.coords in the store (unmounting
    // this) and invalidates the root so the next load re-scopes to the real
    // location.
    let needsLocationCapture =
      viewer
      ->Option.flatMap(v => v.user)
      ->Option.map(u => u.coords->Option.isNone)
      ->Option.getOr(false)

    <>
      {needsLocationCapture
        ? <ViewerLocationPrompt
            onSaved={() =>
              RescriptRelay.commitLocalUpdate(
                ~environment=env,
                ~updater=store =>
                  store
                  ->RescriptRelay.RecordSourceSelectorProxy.getRoot
                  ->RescriptRelay.RecordProxy.invalidateRecord,
              )}
          />
        : React.null}
      <VerticalAvailabilityGrid.make
        days onSave=handleSave isSaving existingEvents demand courtAvailability
      />
    </>
  }
}

@react.component
let make = () => {
  // Standard SSR page: the route loader preloads the query scoped by the
  // default location — the server substitutes the viewer's stored coords
  // (User.coords) when it knows them; ViewerLocationPrompt captures them
  // (inside AvailabilityContent) when it doesn't.
  let query = useLoaderData()
  <WaitForMessages>
    {() =>
      <React.Suspense fallback={React.null}>
        <AvailabilityContent queryRef=query.data />
      </React.Suspense>}
  </WaitForMessages>
}

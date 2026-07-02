%%raw("import { t, plural } from '@lingui/macro'")

module Fragment = %relay(`
  fragment PkEventsListFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    afterDate: { type: "Datetime" }
    filters: { type: "EventFilters" }
    availabilityFromDate: { type: "String!" }
    availabilityToDate: { type: "String!" }
  )
  @refetchable(queryName: "PkEventsListRefetchQuery")
  {
    ...PkEventRow_query
    viewer {
      user {
        id
        ...PkEventRow_user
      }
      clubs(first: 100) {
        edges {
          node {
            id
          }
        }
      }
      availability(activityId: "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61", fromDate: $availabilityFromDate, toDate: $availabilityToDate) {
        localDate
        ...PlayIntentRow_availabilityDay
      }
    }
    availabilityUsersForDateRange(
      fromDate: $availabilityFromDate
      toDate: $availabilityToDate
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
    events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate)
    @connection(key: "PkEventsListFragment_events") {
      edges {
        node {
          id
          startDate
          timezone
          location { id }
          shadow
          listed
          deleted
          club { id }
          maxRsvps
          rsvps(first: 100) {
            edges {
              node {
                id
                listType
              }
            }
          }
          ...PkEventRow_event
        }
      }
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
        startCursor
      }
    }
  }
`)

let defaultActivityId = "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"

let ts = Lingui.UtilString.t

module Day = {
  open Lingui.Util
  @react.component
  let make = (
    ~label: string,
    ~dateDetails: string,
    ~date: Js.Date.t,
    ~events: array<PkEventsListFragment_graphql.Types.fragment_events_edges_node>,
    ~viewer: option<PkEventsListFragment_graphql.Types.fragment_viewer>,
    ~query: RescriptRelay.fragmentRefs<[> #PkEventRow_query]>,
    ~onEventClick: option<string => unit>=?,
    ~onHoverLocation: option<option<string> => unit>=?,
    ~activityId: option<string>=?,
    ~userDays: array<PlayIntentRow.userDay>,
    ~onAvailabilityCommitted: option<PlayIntentRow.userDay> => unit,
    ~shouldHideEvent: option<
      (
        PkEventsListFragment_graphql.Types.fragment_events_edges_node,
        option<PkEventsListFragment_graphql.Types.fragment_viewer>,
      ) => bool,
    >=?,
  ) => {
    let isoDate = {
      let y = date->Js.Date.getFullYear->Float.toInt->Int.toString
      let m = (date->Js.Date.getMonth->Float.toInt + 1)->Int.toString->String.padStart(2, "0")
      let d = date->Js.Date.getDate->Float.toInt->Int.toString->String.padStart(2, "0")
      y ++ "-" ++ m ++ "-" ++ d
    }
    let navigate = LangProvider.Router.useNavigate()
    let (showShadow, setShowShadow) = React.useState(() => false)
    let {pathname} = Router.useLocation()

    let isLoggedIn = viewer->Option.flatMap(v => v.user)->Option.isSome

    let availabilityDay =
      viewer
      ->Option.flatMap(v => v.availability->Array.find(d => d.localDate == isoDate))
      ->Option.map(d => d.fragmentRefs)

    let defaultHide = (
      edge: PkEventsListFragment_graphql.Types.fragment_events_edges_node,
      _viewer,
    ) => edge.shadow->Option.getOr(false)

    let hideCheck = shouldHideEvent->Option.getOr(defaultHide)

    let hiddenEvents = events->Array.filter(edge => hideCheck(edge, viewer))
    let totalHiddenCount = hiddenEvents->Array.length

    let visibleEvents = if showShadow {
      events
    } else {
      events->Array.filter(edge => !hideCheck(edge, viewer))
    }

    let getWaitlistCount = (edge: PkEventsListFragment_graphql.Types.fragment_events_edges_node) =>
      switch edge.maxRsvps {
      | None => 0
      | Some(max) =>
        let mainList =
          edge.rsvps
          ->Option.flatMap(r => r.edges)
          ->Option.getOr([])
          ->Array.filterMap(e => e)
          ->Array.filterMap(e => e.node)
          ->Array.filter(n => n.listType == None || n.listType == Some(0))
        Js.Math.max_int(0, mainList->Array.length - max)
      }

    let hasHiddenPreview = totalHiddenCount > 0 && !showShadow
    let previewHiddenEvent = hiddenEvents->Belt.Array.get(0)

    let handleSaveAvailability = (_newIntents: array<TimeWindowPicker.playIntent>) => ()

    <WaitForMessages>
      {() => {
        let renderHeader = (trigger: React.element) =>
          <div className="px-4 md:px-6 py-3 flex items-center justify-between">
            <div className="flex items-baseline gap-3">
              <h3 className="font-semibold text-gray-900 dark:text-gray-100">
                {label->React.string}
              </h3>
              <span className="font-mono text-xs text-gray-400 dark:text-gray-500">
                {(dateDetails ++
                " · " ++
                Int.toString(events->Array.filter(e => e.deleted->Option.isNone)->Array.length) ++
                " " ++
                Lingui.UtilString.plural(
                  events->Array.filter(e => e.deleted->Option.isNone)->Array.length,
                  {one: ts`event`, other: ts`events`},
                ))->React.string}
              </span>
            </div>
            {trigger}
          </div>
        <>
          <React.Suspense fallback={renderHeader(React.null)}>
            <PlayIntentRow
              localDate=isoDate
              dateGroup=label
              ?availabilityDay
              ?activityId
              userDays
              onAvailabilityCommitted
              onChange=handleSaveAvailability
              isLoggedIn
              onCreateEvent={() => navigate("/events/create?date=" ++ isoDate, None)}
              renderHeader
            />
          </React.Suspense>
          {visibleEvents
          ->Array.mapWithIndex((edge, idx) => {
            let waitlistCount = getWaitlistCount(edge)
            <PkEventRow
              key=edge.id
              event=edge.fragmentRefs
              user={viewer->Option.flatMap(v => v.user->Option.map(u => u.fragmentRefs))}
              isLastInGroup={idx == Array.length(visibleEvents) - 1 && !hasHiddenPreview}
              waitlistCount
              query
              ?onEventClick
              ?onHoverLocation
            />
          })
          ->React.array}
          {hasHiddenPreview
            ? previewHiddenEvent
              ->Option.map(edge => {
                let waitlistCount = getWaitlistCount(edge)
                <div
                  className="relative h-[68px] overflow-hidden border-b border-gray-100 dark:border-[#2a2b30]">
                  <div className="pointer-events-none">
                    <PkEventRow
                      key={edge.id ++ "-hidden-preview"}
                      event=edge.fragmentRefs
                      user={viewer->Option.flatMap(v => v.user->Option.map(u => u.fragmentRefs))}
                      isLastInGroup=true
                      waitlistCount
                      query
                      ?onEventClick
                      ?onHoverLocation
                      dimmed=true
                    />
                  </div>
                  <div
                    className="absolute inset-0 bg-gradient-to-b from-transparent via-white/75 to-white dark:via-[#222326]/80 dark:to-[#222326]"
                  />
                  <div className="absolute inset-0 flex items-end justify-center pb-2">
                    <button
                      className="px-3 py-1 rounded-full text-xs font-mono border border-gray-300 dark:border-[#3a3b40] bg-white/90 dark:bg-[#222326]/90 text-gray-700 dark:text-gray-200 hover:text-black dark:hover:text-white transition-colors"
                      onClick={_ => setShowShadow(_ => true)}>
                      {t`Show ${totalHiddenCount->Int.toString} more`}
                    </button>
                  </div>
                </div>
              })
              ->Option.getOr(React.null)
            : React.null}
        </>
      }}
    </WaitForMessages>
  }
}

@react.component
let make = (
  ~events,
  ~onHoverLocation: option<option<string> => unit>=?,
  ~selectedLocationId: option<string>=?,
  ~activityId: option<string>=?,
  ~shouldHideEvent: option<
    (
      PkEventsListFragment_graphql.Types.fragment_events_edges_node,
      option<PkEventsListFragment_graphql.Types.fragment_viewer>,
    ) => bool,
  >=?,
) => {
  let {data, hasNext, isLoadingNext: _, isLoadingPrevious, refetch} = Fragment.usePagination(events)
  let viewer = data.viewer
  let events = data.events->Fragment.getConnectionNodes
  let pageInfo = data.events.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage

  let ctx = DrawerContext.use()

  let (searchParams, setSearchParams) = Router.useSearchParamsFunc()

  let selectedDate =
    searchParams
    ->Router.ImmSearchParams.fromSearchParams
    ->Router.ImmSearchParams.get("afterDate")
    ->Option.map(d => Js.Date.fromString(d))

  let onSelectDate = (date: Js.Date.t) => {
    setSearchParams(prevParams => {
      EventsListUtils.Filter.ByAfterDate(date)
      ->EventsListUtils.Filter.updateParams(prevParams->Router.ImmSearchParams.fromSearchParams)
      ->Router.ImmSearchParams.toSearchParams
    })
  }

  let onClearDate = () => {
    setSearchParams(prevParams => {
      prevParams->Router.SearchParams.delete("afterDate")
      prevParams
    })
  }

  let bucketSetup = EventsListUtils.makeBucketSetup()
  let intl = ReactIntl.useIntl()

  let isoDateOf = (date: Js.Date.t): string => {
    let y = date->Js.Date.getFullYear->Float.toInt->Int.toString
    let m = (date->Js.Date.getMonth->Float.toInt + 1)->Int.toString->String.padStart(2, "0")
    let d = date->Js.Date.getDate->Float.toInt->Int.toString->String.padStart(2, "0")
    y ++ "-" ++ m ++ "-" ++ d
  }
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
  let onAvailabilityCommitted = (updatedDay: option<PlayIntentRow.userDay>) => {
    let needsRefetch = switch updatedDay {
    | None => true // deletion: Relay won't remove the node from linked arrays
    | Some(day) => !(allUserDays->Array.some(d => d.id == day.id)) // new node
    }
    if needsRefetch {
      let _ = refetch(
        ~variables=Fragment.makeRefetchVariables(),
        ~fetchPolicy=RescriptRelay.NetworkOnly,
        ~onComplete=_ => (),
      )
    }
  }

  let formatDate = (date: Js.Date.t): string =>
    intl->ReactIntl.Intl.formatDateWithOptions(
      date,
      ReactIntl.dateTimeFormatOptions(~month=#short, ~day=#numeric, ()),
    )

  let getBucketMeta = (key: string): (string, string, Js.Date.t) =>
    switch key {
    | "today" => (
        ts`Today`,
        formatDate(bucketSetup.dateFromOffset(0.)),
        bucketSetup.dateFromOffset(0.),
      )
    | "tomorrow" => (
        ts`Tomorrow`,
        formatDate(bucketSetup.dateFromOffset(1.)),
        bucketSetup.dateFromOffset(1.),
      )
    | _ =>
      let (isNextWeek, dayIndex, date) = EventsListUtils.getBucketDateDetails(
        ~setup=bucketSetup,
        key,
      )
      let n = key->Int.fromString->Option.getOr(0)
      let dayName = switch dayIndex {
      | 0 => ts`Sunday`
      | 1 => ts`Monday`
      | 2 => ts`Tuesday`
      | 3 => ts`Wednesday`
      | 4 => ts`Thursday`
      | 5 => ts`Friday`
      | 6 => ts`Saturday`
      | _ => ""
      }
      let label = if n == -1 {
        ts`Yesterday`
      } else if isNextWeek {
        ts`Next ${dayName}`
      } else {
        dayName
      }
      (label, formatDate(date), date)
    }

  let bucketEventsDict = EventsListUtils.bucketEvents(
    ~setup=bucketSetup,
    ~getStartDate={
      (e: PkEventsListFragment_graphql.Types.fragment_events_edges_node) => e.startDate
    },
    ~filterByDate=None,
    events,
  )

  let buckets = EventsListUtils.sortBucketKeys(
    bucketEventsDict->Js.Dict.keys,
  )->Array.filterMap(key =>
    bucketEventsDict
    ->Js.Dict.get(key)
    ->Option.flatMap(bucketEvents => {
      let filteredEvents = switch selectedLocationId {
      | Some(selId) =>
        bucketEvents->Array.filter(
          e =>
            e.location
            ->Option.flatMap(l => Some(l.id))
            ->Option.map(lid => lid == selId)
            ->Option.getOr(false),
        )
      | None => bucketEvents
      }
      if filteredEvents->Array.length == 0 {
        None
      } else {
        let (label, dateDetails, date) = getBucketMeta(key)
        let isoDate = isoDateOf(date)
        let viewerUserId = viewer->Option.flatMap(v => v.user)->Option.map(u => u.id)
        let userDaysForDate =
          allUserDays
          ->Array.filter(d => d.localDate == isoDate)
          ->Array.filter(
            d =>
              switch viewerUserId {
              | None => true
              | Some(vid) => d.user->Option.map(u => u.id)->Option.getOr("") != vid
              },
          )
        Some((
          key,
          <Day
            label
            dateDetails
            date
            events=filteredEvents
            viewer
            query=data.fragmentRefs
            onEventClick={id => ctx.openDrawer(<PkEventDrawer eventId=id />, "/events/" ++ id)}
            ?onHoverLocation
            ?activityId
            userDays=userDaysForDate
            onAvailabilityCommitted
            ?shouldHideEvent
          />,
        ))
      }
    })
  )

  let totalEvents = events->Array.length

  let eventDates =
    events->Array.filterMap(e => e.startDate->Option.map(d => d->Util.Datetime.toDate))

  let onPrevious = pageInfo.startCursor->Option.map(startCursor => () =>
    setSearchParams(prevParams => {
      EventsListUtils.Filter.ByBefore(startCursor)
      ->EventsListUtils.Filter.updateParams(prevParams->Router.ImmSearchParams.fromSearchParams)
      ->Router.ImmSearchParams.toSearchParams
    }))

  let onRefresh = () => {
    Js.Promise.make((~resolve, ~reject as _) => {
      let _ = refetch(
        ~variables=Fragment.makeRefetchVariables(),
        ~fetchPolicy=RescriptRelay.NetworkOnly,
        ~onComplete=_err => resolve(),
      )
    })
  }

  let onNext = pageInfo.endCursor->Option.map(endCursor => () =>
    setSearchParams(prevParams => {
      EventsListUtils.Filter.ByAfter(endCursor)
      ->EventsListUtils.Filter.updateParams(prevParams->Router.ImmSearchParams.fromSearchParams)
      ->Router.ImmSearchParams.toSearchParams
    }))

  <EventsListView
    totalEvents
    buckets
    weekendBucketKey=bucketSetup.weekendBucketKey
    ?selectedDate
    onSelectDate={onSelectDate}
    onClearDate={onClearDate}
    eventDates={eventDates}
    hasPrevious
    isLoadingPrevious
    ?onPrevious
    hasNext
    ?onNext
    onRefresh={onRefresh}
  />
}

%%raw("import { t, plural } from '@lingui/macro'")

module Fragment = %relay(`
  fragment PkEventsListFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    afterDate: { type: "Datetime" }
    filters: { type: "EventFilters" }
  )
  @refetchable(queryName: "PkEventsListRefetchQuery")
  {
    ...PkEventRow_query
    viewer {
      user {
        ...PkEventRow_user
      }
      clubs(first: 100) {
        edges {
          node {
            id
          }
        }
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
    let (showShadow, setShowShadow) = React.useState(() => false)

    let defaultHide = (
      edge: PkEventsListFragment_graphql.Types.fragment_events_edges_node,
      _viewer,
    ) => edge.shadow->Option.getOr(false)

    let hideCheck = shouldHideEvent->Option.getOr(defaultHide)

    let totalHiddenCount =
      events
      ->Array.filter(edge => hideCheck(edge, viewer))
      ->Array.length

    let hiddenDesc = Lingui.UtilString.plural(totalHiddenCount, {one: "event", other: "events"})

    let visibleEvents = events->Array.filter(edge => !hideCheck(edge, viewer) || showShadow)

    <WaitForMessages>
      {() => <>
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
          <LangProvider.Router.Link
            to={"/events/create?date=" ++ isoDate}
            className="flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-mono text-gray-500 dark:text-gray-400 hover:text-black dark:hover:text-white border border-dashed border-gray-300 dark:border-[#3a3b40] hover:border-gray-400 dark:hover:border-gray-500 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors">
            <Lucide.Plus size=11 />
            <span> {(ts`Add to ${label->String.toLowerCase}`)->React.string} </span>
          </LangProvider.Router.Link>
        </div>
        {visibleEvents
        ->Array.mapWithIndex((edge, idx) => {
          let waitlistCount = switch edge.maxRsvps {
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
          <PkEventRow
            key=edge.id
            event=edge.fragmentRefs
            user={viewer->Option.flatMap(v => v.user->Option.map(u => u.fragmentRefs))}
            isLastInGroup={idx == Array.length(visibleEvents) - 1}
            waitlistCount
            query
            ?onEventClick
            ?onHoverLocation
          />
        })
        ->React.array}
        {totalHiddenCount > 0 && !showShadow
          ? <button
              className="w-full py-3 text-center text-sm text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors border-b border-gray-100 dark:border-[#2a2b30]"
              onClick={_ => setShowShadow(_ => true)}>
              {t`${totalHiddenCount->Int.toString} ${hiddenDesc} hidden — show`}
            </button>
          : React.null}
      </>}
    </WaitForMessages>
  }
}

@react.component
let make = (
  ~events,
  ~onHoverLocation: option<option<string> => unit>=?,
  ~selectedLocationId: option<string>=?,
  ~shouldHideEvent: option<
    (
      PkEventsListFragment_graphql.Types.fragment_events_edges_node,
      option<PkEventsListFragment_graphql.Types.fragment_viewer>,
    ) => bool,
  >=?,
) => {
  let {data, hasNext, isLoadingNext: _, isLoadingPrevious} = Fragment.usePagination(events)
  let viewer = data.viewer
  let events = data.events->Fragment.getConnectionNodes
  let pageInfo = data.events.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage

  let ctx = DrawerContext.use()

  let (searchParams, setSearchParams) = Router.useSearchParamsFunc()
  let searchParams = searchParams->Router.ImmSearchParams.fromSearchParams

  let filterByDate =
    searchParams
    ->Router.ImmSearchParams.get("selectedDate")
    ->Option.map(date => Js.Date.fromString(date))

  let clearFilterByDate = () => {
    setSearchParams(prevParams => {
      prevParams->Router.SearchParams.delete("selectedDate")
      prevParams
    })
  }

  let bucketSetup = EventsListUtils.makeBucketSetup()
  let intl = ReactIntl.useIntl()

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
    ~filterByDate,
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
            ?shouldHideEvent
          />,
        ))
      }
    })
  )

  let totalEvents = events->Array.length

  let onPrevious = pageInfo.startCursor->Option.map(startCursor => () =>
    setSearchParams(prevParams => {
      EventsListUtils.Filter.ByBefore(startCursor)
      ->EventsListUtils.Filter.updateParams(prevParams->Router.ImmSearchParams.fromSearchParams)
      ->Router.ImmSearchParams.toSearchParams
    }))

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
    ?filterByDate
    onClearFilter={clearFilterByDate}
    hasPrevious
    isLoadingPrevious
    ?onPrevious
    hasNext
    ?onNext
  />
}

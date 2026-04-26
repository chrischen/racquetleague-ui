%%raw("import { t, plural } from '@lingui/macro'")

module Fragment = %relay(`
  fragment ClubEventsListFragment on Club
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    afterDate: { type: "Datetime" }
    token: { type: "String" }
  )
  @refetchable(queryName: "ClubEventsListRefetchQuery") {
    events(after: $after, first: $first, before: $before, afterDate: $afterDate, token: $token)
      @connection(key: "ClubEventsListFragment_events") {
      edges {
        node {
          id
          startDate
          timezone
          maxRsvps
          listed
          shadow
          deleted
          club { id }
          location { id }
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
      pageInfo { hasNextPage hasPreviousPage endCursor startCursor }
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
    ~events: array<ClubEventsListFragment_graphql.Types.fragment_events_edges_node>,
    ~viewerUser: option<RescriptRelay.fragmentRefs<[> #PkEventRow_user]>>,
    ~onEventClick: option<string => unit>=?,
    ~onHoverLocation: option<option<string> => unit>=?,
    ~selectedLocationId: option<string>=?,
  ) => {
    <>
      <div className="px-4 md:px-6 py-3 flex items-baseline gap-3">
        <h3 className="font-semibold text-gray-900 dark:text-gray-100"> {label->React.string} </h3>
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
      {events
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
          user=viewerUser
          isLastInGroup={idx == Array.length(events) - 1}
          waitlistCount
          ?onEventClick
          ?onHoverLocation
          dimmed={selectedLocationId
          ->Option.map(selId =>
            edge.location
            ->Option.flatMap(l => Some(l.id))
            ->Option.map(lid => lid != selId)
            ->Option.getOr(false)
          )
          ->Option.getOr(false)}
        />
      })
      ->React.array}
    </>
  }
}

@react.component
let make = (
  ~events: RescriptRelay.fragmentRefs<[> #ClubEventsListFragment]>,
  ~viewerUser: option<RescriptRelay.fragmentRefs<[> #PkEventRow_user]>>=?,
  ~onHoverLocation: option<option<string> => unit>=?,
  ~selectedLocationId: option<string>=?,
) => {
  let {data, hasNext, isLoadingNext: _, isLoadingPrevious} = Fragment.usePagination(events)
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

  let getBucketMeta = (key: string): (string, string) =>
    switch key {
    | "today" => (ts`Today`, formatDate(bucketSetup.dateFromOffset(0.)))
    | "tomorrow" => (ts`Tomorrow`, formatDate(bucketSetup.dateFromOffset(1.)))
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
      (label, formatDate(date))
    }

  let bucketEventsDict = EventsListUtils.bucketEvents(
    ~setup=bucketSetup,
    ~getStartDate={
      (e: ClubEventsListFragment_graphql.Types.fragment_events_edges_node) => e.startDate
    },
    ~filterByDate,
    events,
  )

  let buckets = EventsListUtils.sortBucketKeys(
    bucketEventsDict->Js.Dict.keys,
  )->Array.filterMap(key =>
    bucketEventsDict
    ->Js.Dict.get(key)
    ->Option.map(bucketEvents => {
      let (label, dateDetails) = getBucketMeta(key)
      (
        key,
        <Day
          label
          dateDetails
          events=bucketEvents
          viewerUser
          onEventClick={id => ctx.openDrawer(<PkEventDrawer eventId=id />, "/events/" ++ id)}
          ?onHoverLocation
          ?selectedLocationId
        />,
      )
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

  <WaitForMessages>
    {() =>
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
      />}
  </WaitForMessages>
}

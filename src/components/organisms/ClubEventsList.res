%%raw("import { t } from '@lingui/macro'")
open LangProvider.Router

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
      edges { node { id startDate timezone 
          rsvps(first: 100) {
            edges {
              node {
                id
                listType
              }
            }
          }
      location { id } shadow ...EventItem_event } }
      ...PinMap_eventConnection
      pageInfo { hasNextPage hasPreviousPage endCursor startCursor }
    }
  }
`)

// Grouping helpers
type dateGroups = dict<array<ClubEventsListFragment_graphql.Types.fragment_events_edges_node>>

let addEventToGroups = (
  intl,
  filterByDate: option<Js.Date.t>,
  groups: dateGroups,
  event: ClubEventsListFragment_graphql.Types.fragment_events_edges_node,
): dateGroups => {
  event.startDate
  ->Option.map(startDate => {
    open Util
    let dateJs = startDate->Datetime.toDate
    let key =
      intl->ReactIntl.Intl.formatDateWithOptions(
        dateJs,
        ReactIntl.dateTimeFormatOptions(
          ~weekday=#long,
          ~day=#numeric,
          ~month=#short,
          ~timeZone={event.timezone->Option.getOr("UTC")},
          (),
        ),
      )
    let shouldInclude = switch filterByDate {
    | None => true
    | Some(f) => dateJs->Js.Date.getTime > f->Js.Date.getTime
    }
    if shouldInclude {
      switch groups->Js.Dict.get(key) {
      | None => groups->Js.Dict.set(key, [event])
      | Some(existing) => groups->Js.Dict.set(key, [event, ...existing])
      }
    }
  })
  ->ignore
  groups
}

module Filter = {
  type t = ByDate(Js.Date.t) | ByAfter(string) | ByBefore(string) | ByAfterDate(Js.Date.t)
  let updateParams = (filter, params) =>
    switch filter {
    | ByAfter(cursor) =>
      params->Router.ImmSearchParams.set("after", cursor)->Router.ImmSearchParams.delete("before")
    | ByBefore(cursor) =>
      params->Router.ImmSearchParams.set("before", cursor)->Router.ImmSearchParams.delete("after")
    | ByDate(date) => params->Router.ImmSearchParams.set("selectedDate", date->Js.Date.toDateString)
    | ByAfterDate(date) =>
      params->Router.ImmSearchParams.set("afterDate", date->Js.Date.toISOString)
    }
}

module Day = {
  @react.component
  let make = (
    ~events: array<ClubEventsListFragment_graphql.Types.fragment_events_edges_node>,
    ~highlightedLocation,
    ~viewer: option<ClubPageQuery_graphql.Types.response_viewer>,
  ) => {
    let (showShadow, setShowShadow) = React.useState(() => false)
    let shadowEvents = events->Array.filter(e => e.shadow->Option.getOr(false))
    let shadowCount = shadowEvents->Array.length
    <>
      {events
      ->Array.map(edge => {
        let highlighted =
          edge.location
          ->Option.map(loc => highlightedLocation == loc.id)
          ->Option.getOr(false)
        if edge.shadow->Option.getOr(false) && !showShadow {
          React.null
        } else {
          <li
            key=edge.id
            className={highlighted ? "bg-yellow-100/35" : ""}
            id={highlighted ? "highlighted" : ""}>
            // Casting fragment refs to satisfy EventItem_event (edge includes spread)
            <EventItem
              event={Obj.magic(edge.fragmentRefs)}
              highlightedLocation=highlighted
              user={viewer->Option.flatMap(v => v.user->Option.map(u => u.fragmentRefs))}
            />
          </li>
        }
      })
      ->React.array}
      {shadowCount > 0 && !showShadow
        ? <li>
            <p className="text-gray-700 p-3 italic ml-6">
              {(shadowCount->Int.toString ++
              " private event" ++
              (shadowCount > 1 ? "s" : "") ++ " hidden")->React.string}
              {" "->React.string}
              <UiAction onClick={_ => setShowShadow(_ => true)}>
                {(Lingui.UtilString.t`show`)->React.string}
              </UiAction>
            </p>
          </li>
        : React.null}
    </>
  }
}

@react.component
let make = (
  ~events: RescriptRelay.fragmentRefs<[> #ClubDetails_club | #ClubEventsListFragment]>,
  ~viewer: option<ClubPageQuery_graphql.Types.response_viewer>,
  ~header: React.element,
) => {
  let {events: eventsQuery} = Fragment.use(events)
  let {data, isLoadingNext, hasNext, isLoadingPrevious} = Fragment.usePagination(events)
  let nodes = data.events->Fragment.getConnectionNodes
  let pageInfo = data.events.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage
  let (shareOpen, setShareOpen) = React.useState(() => false)
  let (selectedEvent: option<string>, _) = React.useState(() => None)
  let navigate = Router.useNavigate()
  let (searchParams, setSearchParams) = Router.useSearchParamsFunc()
  let immParams = searchParams->Router.ImmSearchParams.fromSearchParams
  let filterByDate =
    immParams
    ->Router.ImmSearchParams.get("selectedDate")
    ->Option.map(d => Js.Date.fromString(d))
  let clearFilterByDate = () =>
    setSearchParams(prev => {
      prev->Router.SearchParams.delete("selectedDate")
      prev
    })
  let intl = ReactIntl.useIntl()
  let grouped = nodes->Array.reduce(Js.Dict.empty(), addEventToGroups(intl, filterByDate, ...))
  // Extract date keys back into Js.Date.t list for calendar highlight
  let calendarDates =
    grouped
    ->Js.Dict.keys
    ->Array.map(dateString => Js.Date.fromString(dateString))

  <>
    <div
      className="grow p-0 z-10 lg:w-1/2 lg:h-[calc(100vh-50px)] lg:overflow-scroll lg:rounded-lg lg:bg-white lg:p-10 lg:shadow-sm lg:ring-1 lg:ring-zinc-950/5 dark:lg:bg-zinc-900 dark:lg:ring-white/10">
      <LangProvider.DetectedLang />
      <div className="mx-auto max-w-7xl">
        {header}
        <Layout.Container className="p-2 flex-row flex gap-2">
          <UiAction
            alt={Lingui.UtilString.t`share as text`}
            onClick={_ => setShareOpen(o => !o)}
            active={shareOpen}>
            <HeroIcons.DocumentTextOutline className="inline w-6 h-6" />
          </UiAction>
          // Text sharing list removed during refactor; re-add if needed
        </Layout.Container>
        <div className="mx-auto w-full grow lg:flex">
          <div className="w-full lg:overflow-x-hidden">
            <ClubCalendar
              dates=calendarDates
              onDateSelected={date =>
                setSearchParams(prev =>
                  Filter.ByDate(date)
                  ->Filter.updateParams(prev->Router.ImmSearchParams.fromSearchParams)
                  ->Router.ImmSearchParams.toSearchParams
                )}
            />
            {filterByDate
            ->Option.map(_ =>
              <WarningAlert
                cta={(Lingui.UtilString.t`clear filter`)->React.string}
                ctaClick={_ => clearFilterByDate()}>
                {<> {(Lingui.UtilString.t`filtering by date`)->React.string} </>}
              </WarningAlert>
            )
            ->Option.getOr(React.null)}
            {!isLoadingPrevious && hasPrevious
              ? pageInfo.startCursor
                ->Option.map(startCursor =>
                  <LinkWithOpts
                    className="hover:bg-gray-100 p-3 w-full text-center block"
                    to={
                      pathname: "./",
                      search: Filter.ByBefore(startCursor)
                      ->Filter.updateParams(immParams)
                      ->Router.ImmSearchParams.toString,
                    }>
                    <HeroIcons.ChevronUpIcon className="inline w-7 h-7" />
                  </LinkWithOpts>
                )
                ->Option.getOr(React.null)
              : React.null}
            <ul role="list">
              {grouped
              ->Js.Dict.entries
              ->Array.map(((dateString, events)) => {
                <li key={dateString}>
                  <div
                    className="sticky top-0 z-10 border-y border-b-gray-200 border-t-gray-100 bg-gray-50 px-0 py-1.5 text-sm font-semibold leading-6 text-gray-900">
                    <Layout.Container>
                      <h3> {dateString->React.string} </h3>
                    </Layout.Container>
                  </div>
                  <ul role="list" className="divide-y divide-gray-200">
                    <Day events viewer highlightedLocation="" />
                  </ul>
                </li>
              })
              ->React.array}
            </ul>
            {hasNext && !isLoadingNext
              ? <Layout.Container>
                  {pageInfo.endCursor
                  ->Option.map(endCursor =>
                    <LinkWithOpts
                      className="hover:bg-gray-100 p-3 w-full text-center block"
                      to={
                        pathname: "./",
                        search: Filter.ByAfter(endCursor)
                        ->Filter.updateParams(immParams)
                        ->Router.ImmSearchParams.toString,
                      }>
                      <HeroIcons.ChevronDownIcon className="inline w-7 h-7" />
                    </LinkWithOpts>
                  )
                  ->Option.getOr(React.null)}
                </Layout.Container>
              : React.null}
          </div>
        </div>
      </div>
    </div>
    <div
      className="grow p-0 lg:w-1/2 lg:-ml-1 lg:shadow-sm lg:ring-1 lg:ring-zinc-950/5 dark:lg:bg-zinc-900 dark:lg:ring-white/10">
      <div className="mx-auto">
        <div className="shrink-0 border-t border-gray-200 lg:border-l lg:border-t-0">
          <div className="w-full lg:min-h-96 h-96 lg:h-[calc(100vh-50px)] lg:max-h-screen">
            <PinMap
              connection={eventsQuery.fragmentRefs}
              onLocationClick={location => navigate("/locations/" ++ location.id, None)}
              selected=?selectedEvent
            />
          </div>
        </div>
      </div>
    </div>
  </>
}

// Force lingui extraction for dynamic ids
let __unused = () => {
  let td = Lingui.UtilString.td
  @live (td({id: "Badminton"})->ignore)
  @live (td({id: "Table Tennis"})->ignore)
  @live (td({id: "Pickleball"})->ignore)
  @live (td({id: "Futsal"})->ignore)
}

%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")

// open Util
open LangProvider.Router
module Fragment = %relay(`
  fragment EventsListFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    afterDate: { type: "Datetime" }
    filters: { type: "EventFilters" }
  )
  @refetchable(queryName: "EventsListRefetchQuery")
  {
    viewer {
      user {
        ...EventItem_user
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
    @connection(key: "EventsListFragment_events") {
      edges {
        node {
          id
          startDate
          timezone
          location {
            id
          }
          shadow
          listed
          club {
            id
          }
          rsvps(first: 100) {
            edges {
              node {
                id
                listType
              }
            }
          }
          ...EventItem_event
          ...EventsListText_event
        }
      }
      ...PinMap_eventConnection
      pageInfo {
        hasNextPage
        hasPreviousPage
        endCursor
        startCursor
      }
    }
  }
`)

module TextItemFragment = %relay(`
  fragment EventsListText_event on Event {
    id
    title
    details
    activity {
      name
    }
    location {
      name
    }
    rsvps(first: 100) {
      edges {
        node {
          id
          listType
        }
      }
    }
    maxRsvps
    startDate
    endDate
    timezone
    shadow
    listed
    deleted
  }
`)

module TextEventItem = {
  open Lingui.UtilString
  let td = Lingui.UtilString.dynamic
  let ts = Lingui.UtilString.t

  let make = (~event) => {
    let {
      id,
      location,
      // details,
      rsvps,
      startDate,
      maxRsvps,
      endDate,
      timezone,
      deleted,
    } = TextItemFragment.use(event)
    let {i18n: {locale}} = Lingui.useLingui()
    let intl = ReactIntl.useIntl()

    let playersCount =
      rsvps
      ->Option.flatMap(rsvps =>
        rsvps.edges->Option.map(edges =>
          edges
          ->Array.filter(
            edge => {
              edge
              ->Option.flatMap(
                edge =>
                  edge.node->Option.map(node => node.listType == Some(0) || node.listType == None),
              )
              ->Option.getOr(true)
            },
          )
          ->Array.length
        )
      )
      ->Option.getOr(0)

    let spaceAvailable = switch maxRsvps {
    | Some(max) => max - playersCount > 0 ? "🈳" : "🈵"
    | None => "🈳"
    }

    let duration = startDate->Option.flatMap(startDate =>
      endDate->Option.map(endDate =>
        endDate
        ->Util.Datetime.toDate
        ->DateFns.differenceInMinutes(startDate->Util.Datetime.toDate)
      )
    )
    let duration = duration->Option.map(duration => {
      let hours = Js.Math.floor_float(duration /. 60.)
      let minutes = mod(duration->Float.toInt, 60)
      if minutes == 0 {
        plural(
          hours->Float.toInt,
          {one: ts`${hours->Float.toString} hour`, other: ts`${hours->Float.toString} hours`},
        )
      } else {
        plural(
          hours->Float.toInt,
          {one: ts`${hours->Float.toString} hour`, other: ts`${hours->Float.toString} hours`},
        ) ++
        " " ++
        plural(
          minutes,
          {
            one: ts`${minutes->Int.toString} minute`,
            other: ts`${minutes->Int.toString} minutes`,
          },
        )
      }
    })
    let canceled = deleted->Option.isSome ? " " ++ (ts`🚫 CANCELED`) : ""

    // Date string in local time
    "🗓 " ++
    startDate
    ->Option.map(startDate => {
      let startDate = startDate->Util.Datetime.toDate
      intl->ReactIntl.Intl.formatDateWithOptions(
        startDate,
        ReactIntl.dateTimeFormatOptions(
          ~timeZone=timezone->Option.getOr("Asia/Tokyo"),
          ~weekday=#short,
          ~month=#numeric,
          ~day=#numeric,
          (),
        ),
      ) ++
      " " ++
      intl->ReactIntl.Intl.formatTimeWithOptions(
        startDate,
        ReactIntl.dateTimeFormatOptions(~timeZone=timezone->Option.getOr("Asia/Tokyo"), ()),
      )
    })
    ->Option.getOr("") ++
    "->" ++
    endDate
    ->Option.map(endDate =>
      intl->ReactIntl.Intl.formatTimeWithOptions(
        endDate->Util.Datetime.toDate,
        ReactIntl.dateTimeFormatOptions(~timeZone=?timezone, ()),
      )
    )
    ->Option.getOr("") ++
    duration
    ->Option.map(duration => " (" ++ duration ++ ") ")
    ->Option.getOr("") ++
    spaceAvailable ++
    canceled ++
    "\n📍 " ++
    location
    ->Option.flatMap(l => l.name->Option.map(name => name))
    ->Option.getOr(ts`[location missing]`) ++
    // "\n" ++
    // maxRsvps
    // ->Option.map(maxRsvps =>
    //   (ts`Max`) ++ " " ++ maxRsvps->Int.toString ++ " " ++ ts(["players"], []) ++ "\n"
    // )
    // ->Option.getOr("") ++
    "\n👉 https://www.pkuru.com/" ++
    locale ++
    "/events/" ++
    id ++
    "\n" ++ "-----------------------------"
  }
}

module TextEventsList = {
  let toLocalTime = date => {
    Js.Date.fromFloat(date->Js.Date.getTime -. date->Js.Date.getTimezoneOffset *. 60. *. 1000.)
  }
  @react.component
  let make = (~events) => {
    let (_isPending, _) = ReactExperimental.useTransition()
    let {data} = Fragment.usePagination(events)
    let events = data.events->Fragment.getConnectionNodes

    let str = {
      events
      ->Array.map(edge => TextEventItem.make(~event=edge.fragmentRefs))
      ->Array.join("\n")
    }
    <textarea readOnly=true className="w-full" rows=10 value={str} />
  }
}

// type dateEntry = (string, array<EventsListFragment_graphql.Types.fragment_events_edges_node>)
type dates = dict<array<EventsListFragment_graphql.Types.fragment_events_edges_node>>
// type dates = array<dateEntry>;
// let toLocalTime = date => {
//   Js.Date.fromFloat(date->Js.Date.getTime -. date->Js.Date.getTimezoneOffset *. 60. *. 1000.)
// }
let sortByDate = (
  intl,
  filterByDate: option<Js.Date.t>,
  dates: dates,
  event: EventsListFragment_graphql.Types.fragment_events_edges_node,
): dates => {
  event.startDate
  ->Option.map(startDate => {
    open Util
    // startDate in UTC
    let startDate = startDate->Datetime.toDate

    // Date string in local time
    let startDateString =
      intl->ReactIntl.Intl.formatDateWithOptions(
        startDate,
        ReactIntl.dateTimeFormatOptions(
          ~weekday=#long,
          ~day=#numeric,
          ~month=#short,
          ~timeZone={event.timezone->Option.getOr("Asia/Tokyo")},
          (),
        ),
      )

    filterByDate
    ->Option.map(filterDate => {
      switch startDate->Js.Date.getTime > filterDate->Js.Date.getTime {
      | true =>
        switch dates->Js.Dict.get(startDateString) {
        | None => dates->Js.Dict.set(startDateString, [event])
        | Some(events) => dates->Js.Dict.set(startDateString, [event, ...events])
        }
      | false => ()
      }
    })
    ->ignore
    switch filterByDate {
    | None =>
      switch dates->Js.Dict.get(startDateString) {
      | None => dates->Js.Dict.set(startDateString, [event])
      | Some(events) => dates->Js.Dict.set(startDateString, [event, ...events])
      }
    | _ => ()
    }
  })
  ->ignore
  dates
}

module Filter = {
  type t = ByDate(Js.Date.t) | ByAfter(string) | ByBefore(string) | ByAfterDate(Js.Date.t)
  // let make = (filterByDate, afterCursor, beforeCursor) =>
  //   switch (filterByDate, afterCursor, beforeCursor) {
  //   | (Some(date), _, _) => Some(ByDate(date))
  //   | (None, Some(c), _) => Some(ByAfter(c))
  //   | (None, _, Some(c)) => Some(ByBefore(c))
  //   | _ => None
  //   }
  let updateParams = (filter, params) => {
    switch filter {
    | ByAfter(cursor) =>
      params->Router.ImmSearchParams.set("after", cursor)->Router.ImmSearchParams.delete("before")
    | ByDate(date) => params->Router.ImmSearchParams.set("selectedDate", date->Js.Date.toDateString)
    | ByAfterDate(date) =>
      params->Router.ImmSearchParams.set("afterDate", date->Js.Date.toISOString)
    | ByBefore(cursor) =>
      params->Router.ImmSearchParams.set("before", cursor)->Router.ImmSearchParams.delete("after")
    }
  }
}

module Day = {
  open Lingui.Util
  @react.component
  let make = (
    ~events: array<EventsListFragment_graphql.Types.fragment_events_edges_node>,
    ~highlightedLocation,
    ~viewer: option<EventsListFragment_graphql.Types.fragment_viewer>,
  ) => {
    let (showShadow, setShowShadow) = React.useState(() => false)

    // Get the user's club IDs
    let userClubIds =
      viewer
      ->Option.flatMap(v => v.clubs.edges)
      ->Option.map(edges =>
        edges
        ->Array.filterMap(edge => edge)
        ->Array.filterMap(edge => edge.node)
        ->Array.map(node => node.id)
        ->Set.fromArray
      )
      ->Option.getOr(Set.make())

    // Check if user has any clubs
    let hasClubs = Set.size(userClubIds) > 0

    // Helper function to check if event should be hidden
    let shouldHideEvent = (edge: EventsListFragment_graphql.Types.fragment_events_edges_node) => {
      let isPrivate = edge.shadow->Option.getOr(false)

      // Only check non-member club filtering if viewer exists AND has clubs
      let isFromNonMemberClub = switch viewer {
      | None => false // Not logged in, show all public events
      | Some(_) if !hasClubs => false // Logged in but no clubs, show all public events
      | Some(_) =>
        edge.club
        ->Option.map(club => !Set.has(userClubIds, club.id))
        ->Option.getOr(false)
      }

      (isPrivate || isFromNonMemberClub) && !showShadow
    }

    let shadowCount = events->Array.filter(edge => edge.shadow->Option.getOr(false))->Array.length
    let nonMemberClubCount = switch viewer {
    | None => 0 // Not logged in, don't count non-member events
    | Some(_) if !hasClubs => 0 // Logged in but no clubs, don't count non-member events
    | Some(_) =>
      events
      ->Array.filter(edge =>
        edge.club
        ->Option.map(club => !Set.has(userClubIds, club.id))
        ->Option.getOr(false)
      )
      ->Array.length
    }
    let totalHiddenCount = shadowCount + nonMemberClubCount
    let hiddenCountDesc = Lingui.UtilString.plural(
      totalHiddenCount,
      {one: "event", other: "events"},
    )
    <>
      {events
      ->Array.map(edge => {
        let highlighted =
          edge.location
          ->Option.map(location => highlightedLocation == location.id)
          ->Option.getOr(false)

        let highlightedClass = highlighted ? "bg-yellow-100/35" : ""

        {
          shouldHideEvent(edge)
            ? React.null
            : <li key=edge.id className=highlightedClass id={highlighted ? "highlighted" : ""}>
                // <UiAction
                //   onClick={_ => {
                //     setShowMap(_ => true)
                //     setSelectedEvent(_ => edge.location->Option.map(l => l.id))
                //   }}
                //   key={edge.id}>
                <EventItem
                  key={edge.id}
                  event=edge.fragmentRefs
                  user={viewer->Option.flatMap(v => v.user->Option.map(u => u.fragmentRefs))}
                />
                // </UiAction>
              </li>
        }
      })
      ->React.array}
      {totalHiddenCount > 0 && !showShadow
        ? <li>
            <p className="text-gray-700 p-3 italic ml-6">
              {t`${totalHiddenCount->Int.toString} ${hiddenCountDesc} hidden`}
              {" "->React.string}
              <UiAction onClick={_ => setShowShadow(_ => true)}> {t`show`} </UiAction>
            </p>
          </li>
        : React.null}
    </>
  }
}

@react.component
let make = (~events, ~header: React.element, ~context: AIAssistantModal.context={}) => {
  open Lingui.Util
  let (_isPending, _) = ReactExperimental.useTransition()
  let eventsFragment = events
  let {events: eventsQuery, viewer} = Fragment.use(events)
  let {data, isLoadingNext, hasNext, isLoadingPrevious} = Fragment.usePagination(events)
  let events = data.events->Fragment.getConnectionNodes
  let pageInfo = data.events.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage
  // let (highlightedLocation, _) = React.useState(() => "")
  let (shareOpen, setShareOpen) = React.useState(() => false)
  // let (showMap, setShowMap) = React.useState(() => false)
  let (selectedEvent: option<string>, _) = React.useState(() => None)
  let navigate = Router.useNavigate()

  let (searchParams, setSearchParams) = Router.useSearchParamsFunc()
  let searchParams = searchParams->Router.ImmSearchParams.fromSearchParams

  // AI Assistant Modal state
  let (isAiModalOpen, setIsAiModalOpen) = React.useState(() => false)

  // let afterCursor = searchParams->Router.ImmSearchParams.get("after")
  // let beforeCursor = searchParams->Router.ImmSearchParams.get("before")
  let filterByDate =
    searchParams
    ->Router.ImmSearchParams.get("selectedDate")
    ->Option.map(date => Js.Date.fromString(date))

  // let filterParams = Filter.make(filterByDate, afterCursor, beforeCursor)->Option.map(Filter.updateParams(_, searchParams))

  // let filter = filter->Option.map(filterToParam)->Option.flatMap(activityFilter)

  let clearFilterByDate = () => {
    setSearchParams(prevParams => {
      prevParams->Router.SearchParams.delete("selectedDate")
      prevParams
    })
  }

  let intl = ReactIntl.useIntl()
  let eventsByDate = events->Array.reduce(Js.Dict.empty(), sortByDate(intl, filterByDate, ...))

  <>
    <AIAssistantModal
      open_=isAiModalOpen
      // open_=true
      onOpenChange={isOpen => setIsAiModalOpen(_ => isOpen)}
      context
    />
    <div
      className="grow p-0 z-10 lg:w-1/2 lg:h-[calc(100vh-50px)] lg:overflow-scroll lg:rounded-lg lg:bg-white lg:p-10 lg:shadow-sm lg:ring-1 lg:ring-zinc-950/5 dark:lg:bg-zinc-900 dark:lg:ring-white/10">
      <LangProvider.DetectedLang />
      <div className="mx-auto max-w-7xl">
        {header}
        // <Layout.Container>
        <Layout.Container className="p-2 flex-row flex gap-2">
          <UiAction
            alt={Lingui.UtilString.t`share as text`}
            onClick={_ => setShareOpen(v => !v)}
            active={shareOpen}>
            <HeroIcons.DocumentTextOutline className="inline w-6 h-6" />
          </UiAction>
          {shareOpen ? <TextEventsList events=eventsFragment /> : React.null}
        </Layout.Container>
        <div className="mx-auto w-full grow lg:flex">
          <div className="w-full lg:overflow-x-hidden">
            <Calendar
              events=eventsFragment
              onDateSelected={date => {
                setSearchParams(prevParams => {
                  Filter.ByDate(date)
                  ->Filter.updateParams(prevParams->Router.ImmSearchParams.fromSearchParams)
                  ->Router.ImmSearchParams.toSearchParams
                })
              }}
            />
            <div className="mb-4 mt-4 flex justify-center items-center">
              <AddToCalendar />
            </div>
            <div className="mx-4">
              <button
                onClick={_ => setIsAiModalOpen(_ => true)}
                className="flex w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-2xl font-medium transition-all shadow-lg shadow-purple-500/25 items-center justify-center gap-2">
                <Lucide.Sparkles className="w-5 h-5" />
                {t`Add an Event`}
              </button>
            </div>
            {filterByDate
            ->Option.map(_ =>
              <WarningAlert cta={t`clear filter`} ctaClick={_ => clearFilterByDate()}>
                {<> {t`filtering by date`} </>}
              </WarningAlert>
            )
            ->Option.getOr(React.null)}
            {!isLoadingPrevious && hasPrevious
              ? pageInfo.startCursor
                ->Option.map(startCursor =>
                  <LinkWithOpts
                    className="hover:bg-gray-100 p-3 text-center block"
                    to={
                      pathname: "./",
                      search: Filter.ByBefore(startCursor)
                      ->Filter.updateParams(searchParams)
                      // searchParams
                      // ->Router.ImmSearchParams.set("before", encodeURIComponent(startCursor))
                      ->Router.ImmSearchParams.toString,
                    }>
                    <HeroIcons.ChevronUpIcon className="inline w-7 h-7" />
                  </LinkWithOpts>
                )
                ->Option.getOr(
                  <LinkWithOpts
                    to={
                      pathname: "./",
                      search: Filter.ByAfterDate(Js.Date.fromString("2020-01-01"))
                      ->Filter.updateParams(searchParams)
                      // searchParams
                      // ->Router.ImmSearchParams.set("before", encodeURIComponent(startCursor))
                      ->Router.ImmSearchParams.toString,
                    }>
                    {t`...load past events`}
                  </LinkWithOpts>,
                )
              : React.null}
            <ul role="list" className="">
              {eventsByDate
              ->Js.Dict.entries
              ->Array.map(((dateString, events)) => {
                // This date is in local time
                // @NOTE: Potential bug as dateString possibly needs to be converted
                // back to UTC
                // Js.log(dateString);
                let date = dateString

                // Local time difference in minutes
                // let until = date->DateFns.differenceInMinutes(Js.Date.make())
                <li key={dateString}>
                  <div
                    className="sticky top-0 z-10 border-y border-b-gray-200 border-t-gray-100 bg-gray-50 px-0 py-1.5 text-sm font-semibold leading-6 text-gray-900">
                    <Layout.Container>
                      <h3>
                        {date->React.string}
                        // <ReactIntl.FormattedDate weekday=#long day={#numeric} month={#short} value={date} />
                        // {" "->React.string}
                        // <ReactIntl.FormattedRelativeTime
                        //   value={until} unit=#minute updateIntervalInSeconds=1.
                        // />
                      </h3>
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
                      className="hover:bg-gray-100 p-3 text-center block"
                      to={
                        pathname: "./",
                        search: Filter.ByAfter(endCursor)
                        ->Filter.updateParams(searchParams)
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
        // </Layout.Container>
      </div>
    </div>
    <div
      className="grow p-0 lg:w-1/2 lg:-ml-1 lg:shadow-sm lg:ring-1 lg:ring-zinc-950/5 dark:lg:bg-zinc-900 dark:lg:ring-white/10">
      <div className="mx-auto">
        <div className="shrink-0 border-t border-gray-200 lg:border-l lg:border-t-0">
          <div className="w-full lg:min-h-96 h-96 lg:h-[calc(100vh-50px)] lg:max-h-screen">
            // <ModalDrawer title={"Choose Match"} open_=showMap setOpen={setShowMap}>
            <PinMap
              connection={eventsQuery.fragmentRefs}
              onLocationClick={location => navigate("/locations/" ++ location.id, None)}
              selected=?selectedEvent
            />
            // {selectedEvent
            // ->Option.flatMap(e => e.location)
            // ->Option.map(location => <GMap location=location.fragmentRefs />)
            // ->Option.getOr(React.null)}
            // </ModalDrawer>
          </div>
        </div>
      </div>
    </div>
  </>
}

// @genType
// let default = make

// @NOTE Force lingui to include the potential dynamic values here
let __unused = () => {
  let td = Lingui.UtilString.td

  @live (td({id: "Badminton"})->ignore)

  @live (td({id: "Table Tennis"})->ignore)

  @live (td({id: "Pickleball"})->ignore)

  @live (td({id: "Futsal"})->ignore)
}

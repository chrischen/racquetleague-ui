%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t, plural } from '@lingui/macro'")

open Util
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
    events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate)
    @connection(key: "EventsListFragment_events") {
      edges {
        node {
          id
          startDate
          location {
            id
          }
          ...EventsList_event
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

module ItemFragment = %relay(`
  fragment EventsList_event on Event {
    id
    title
    activity {
      name
    }
    location {
      id
      name
    }
    maxRsvps
    rsvps {
      edges {
        node {
          id
        }
      }
    }
    startDate
    endDate
  }
`)

module NodeId: {
  type t
  let toId: t => string
  let make: (string, string) => t
} = {
  type t = (string, string)
  let make = (key, id) => {
    (key, id)
  }
  let toId = ((_, id): t) => {
    id
  }
}
module NodeIdDto: {
  type t = string
  let toDomain: t => result<NodeId.t, [> #InvalidNode]>
} = {
  type t = string
  let toDomain = (t: t) => {
    switch t->String.split(":") {
    | [key, id] => Ok(NodeId.make(key, id))
    | _ => Error(#InvalidNode)
    }
  }
}

module EventItem = {
  open Lingui.Util
  let td = Lingui.UtilString.dynamic
  let ts = Lingui.UtilString.t
  @react.component
  let make = (~event, ~highlightedLocation: bool=false) => {
    let {id, title, activity, location, startDate, rsvps, endDate} = ItemFragment.use(event)
    let playersCount =
      rsvps
      ->Option.flatMap(rsvps => rsvps.edges->Option.map(edges => edges->Array.length))
      ->Option.getOr(0)
    // let id = id->NodeIdDto.toDomain->Result.map(NodeId.toId)

    // id->Result.map(id =>
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
        // t`${hours->Float.toString} hours and ${minutes->Int.toString} minutes`
        <>
          {plural(
            hours->Float.toInt,
            {one: ts`${hours->Float.toString} hour`, other: ts`${hours->Float.toString} hours`},
          )}
          {" "->React.string}
          {plural(
            minutes,
            {
              one: ts`${minutes->Int.toString} minute`,
              other: ts`${minutes->Int.toString} minutes`,
            },
          )}
        </>
      }
    })
    let highlighted = highlightedLocation ? "bg-yellow-100/35" : ""
    <li className=highlighted id={highlightedLocation ? "highlighted" : ""}>
      <Layout.Container className="relative flex items-center space-x-4 py-4">
        <div className="min-w-0 flex-auto">
          <div className="flex items-center gap-x-3">
            <div
              className={Util.cx(["text-green-400 bg-green-400/10", "flex-none rounded-full p-1"])}>
              <div className="h-2 w-2 rounded-full bg-current" />
            </div>
            <h2 className="min-w-0 text-sm font-semibold leading-6 text-white">
              <Link to={"/events/" ++ id} relative="path" className="flex gap-x-2">
                <span className="truncate">
                  {activity
                  ->Option.flatMap(a => a.name->Option.map(name => td(name)->React.string))
                  ->Option.getOr(React.null)}
                  {" / "->React.string}
                  {title->Option.getOr(ts`[missing title]`)->React.string}
                </span>
                <span className="absolute inset-0" />
              </Link>
            </h2>
          </div>
          <div className="mt-3 flex items-center gap-x-2.5 text-xs leading-5 text-gray-600">
            <p className="whitespace-nowrap">
              {startDate
              ->Option.map(startDate =>
                <ReactIntl.FormattedTime value={startDate->Util.Datetime.toDate} />
              )
              ->Option.getOr(React.null)}
              {" -> "->React.string}
              {endDate
              ->Option.map(endDate =>
                <ReactIntl.FormattedTime value={endDate->Util.Datetime.toDate} />
              )
              ->Option.getOr(React.null)}
              {duration
              ->Option.map(duration => <>
                {" ("->React.string}
                {duration}
                {") "->React.string}
              </>)
              ->Option.getOr(React.null)}
            </p>
          </div>
          <div className="mt-3 flex items-center gap-x-2.5 text-xs leading-5 text-gray-600">
            <span className="whitespace-nowrap">
              <p className={Util.cx(["truncate", highlightedLocation ? "font-bold" : ""])}>
                {location
                ->Option.flatMap(l => l.name->Option.map(name => name->React.string))
                ->Option.getOr(t`[location missing]`)}
              </p>
            </span>
          </div>
        </div>
        <div
          className={Util.cx([
            "text-indigo-400 bg-indigo-400/10 ring-indigo-400/30",
            "rounded-full flex-none py-1 px-2 text-xs font-medium ring-1 ring-inset",
          ])}>
          {(playersCount->Int.toString ++ " ")->React.string}
          {plural(playersCount, {one: "player", other: "players"})}
        </div>
        // <ChevronRightIcon className="h-5 w-5 flex-none text-gray-400" ariaHidden="true" />
      </Layout.Container>
    </li>
    // )->Result.getOr(React.null)
  }
}

type dateEntry = (string, array<EventsListFragment_graphql.Types.fragment_events_edges_node>)
type dates = dict<array<EventsListFragment_graphql.Types.fragment_events_edges_node>>
// type dates = array<dateEntry>;
let toLocalTime = date => {
  Js.Date.fromFloat(date->Js.Date.getTime -. date->Js.Date.getTimezoneOffset *. 60. *. 1000.)
}
let sortByDate = (
  intl,
  dates: dates,
  event: EventsListFragment_graphql.Types.fragment_events_edges_node,
): dates => {
  event.startDate
  ->Option.map(startDate => {
    // startDate in UTC
    let startDate = startDate->Datetime.toDate

    // Date string in local time
    let startDateString =
      intl->ReactIntl.Intl.formatDateWithOptions(
        startDate,
        ReactIntl.dateTimeFormatOptions(~weekday=#long, ~day=#numeric, ~month=#short, ()),
      )

    switch dates->Js.Dict.get(startDateString) {
    | None => dates->Js.Dict.set(startDateString, [event])
    | Some(events) => dates->Js.Dict.set(startDateString, [event, ...events])
    }
  })
  ->ignore
  dates
}
@genType @react.component
let make = (~events) => {
  open Lingui.Util
  let (_isPending, _) = ReactExperimental.useTransition()
  let {events: eventsQuery} = Fragment.use(events)
  let {data, isLoadingNext, hasNext, isLoadingPrevious} = Fragment.usePagination(events)
  let events = data.events->Fragment.getConnectionNodes
  let pageInfo = data.events.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage
  let (highlightedLocation, setHighlightedLocation) = React.useState(() => "")
  let navigate = Router.useNavigate();

  // let onLoadMore = _ =>
  //   startTransition(() => {
  //     loadNext(~count=1)->ignore
  //   })
  //
  let intl = ReactIntl.useIntl()
  let viewer = GlobalQuery.useViewer()
  let eventsByDate = events->Array.reduce(Js.Dict.empty(), sortByDate(intl, ...))

  React.useEffect(() => {

    %raw("window.location.hash = '#highlighted'");
    // navigate("./#highlighted", None);
    // setHighlightedLocations(_ => "asdf"])
    None
  }, [highlightedLocation])
  <>
    {!isLoadingPrevious
      ? pageInfo.startCursor
        ->Option.map(startCursor =>
          <Layout.Container>
            <Link to={"./" ++ "?before=" ++ startCursor}> {t`...load past events`} </Link>
          </Layout.Container>
        )
        ->Option.getOr(React.null)
      : React.null}
    // <Layout.Container>
    <div className="mx-auto w-full grow lg:flex">
      <div className="w-full lg:w-1/2 xl:w-1/3">
        <ul role="list" className="">
          {eventsByDate
          ->Js.Dict.entries
          ->Array.map(((dateString, events)) => {
            // This date is in local time
            // @NOTE: Potential bug as dateString possibly needs to be converted
            // back to UTC
            // Js.log(dateString);
            let date = dateString->Js.Date.fromString
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
                {events
                ->Array.map(edge =>
                  <EventItem
                    highlightedLocation={edge.location
                    ->Option.map(location => highlightedLocation == location.id)
                    ->Option.getOr(false)}
                    key={edge.id}
                    event=edge.fragmentRefs
                  />
                )
                ->React.array}
              </ul>
            </li>
          })
          ->React.array}
        </ul>
        {hasNext && !isLoadingNext
          ? <Layout.Container>
              {pageInfo.endCursor
              ->Option.map(endCursor =>
                <Link to={"./" ++ "?after=" ++ endCursor}> {t`load more`} </Link>
              )
              ->Option.getOr(React.null)}
            </Layout.Container>
          : React.null}
      </div>
      <div
        className="shrink-0 border-t border-gray-200 lg:w-1/2 xl:w-2/3 lg:border-l lg:border-t-0">
        <div className="w-full lg:h-full lg:min-h-96 h-96">
          <PinMap
            connection={eventsQuery.fragmentRefs}
            onLocationClick={location => setHighlightedLocation(_ => location.id)}
          />
        </div>
      </div>
    </div>
    // </Layout.Container>
  </>
}

@genType
let default = make

// @NOTE Force lingui to include the potential dynamic values here
let __unused = () => {
  let td = Lingui.UtilString.td

  @live (td({id: "Badminton"})->ignore)

  @live (td({id: "Table Tennis"})->ignore)

  @live (td({id: "Pickleball"})->ignore)

  @live (td({id: "Futsal"})->ignore)
}

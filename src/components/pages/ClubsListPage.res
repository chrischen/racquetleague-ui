%%raw("import { t, plural } from '@lingui/macro'")
open LangProvider.Router

module Fragment = %relay(`
  fragment ClubsListPage_query on Query
  @argumentDefinitions(
    activitySlug: { type: "String!" }
    first: { type: "Int", defaultValue: 20 }
    after: { type: "String" }
    afterDate: { type: "Datetime" }
  )
  @refetchable(queryName: "ClubsListPageRefetchQuery") {
    clubs(activitySlug: $activitySlug, first: $first, after: $after)
      @connection(key: "ClubsListPage_query_clubs") {
      edges {
        node {
          id
          name
          slug
          description
          score
          stats {
            totalMembers
            activeParticipants
            topPlayersMedianSkill
            retentionRate
          }
          viewerMembership { status isAdmin }
          events(first: 1, afterDate: $afterDate) {
            edges { node { id startDate timezone } }
          }
        }
      }
      pageInfo { hasNextPage endCursor }
    }
  }
`)

module Query = %relay(`
  query ClubsListPageQuery(
    $activitySlug: String!
    $first: Int
    $after: String
    $afterDate: Datetime
  ) {
    ...ClubsListPage_query
      @arguments(
        activitySlug: $activitySlug
        first: $first
        after: $after
        afterDate: $afterDate
      )
  }
`)

type loaderData = ClubsListPageQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

let controlClass = "h-9 rounded-md border border-gray-200 bg-white text-xs font-medium text-gray-700 shadow-sm outline-none transition-colors focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-200"

// Club level on the DUPR scale: the stats job stores an openskill ordinal.
let clubLevel = (
  stats: option<ClubsListPage_query_graphql.Types.fragment_clubs_edges_node_stats>,
) =>
  stats
  ->Option.flatMap(stats => stats.topPlayersMedianSkill)
  ->Option.map(Rating.ordinalToDupr)

module ClubCard = {
  @react.component
  let make = (
    ~club: ClubsListPage_query_graphql.Types.fragment_clubs_edges_node,
    ~rank: int,
  ) => {
    open Lingui.Util
    let podium = rank <= 3
    let name = club.name->Option.getOr("?")
    let slug = club.slug->Option.getOr("")
    let level = clubLevel(club.stats)

    let cardClass = if rank == 1 {
      "border-amber-300 bg-amber-50/60 dark:border-amber-700/60 dark:bg-amber-950/20"
    } else if podium {
      "border-gray-300 bg-gray-50/60 dark:border-gray-600 dark:bg-[#202126]"
    } else {
      "border-gray-200 bg-white hover:border-gray-300 dark:border-[#3a3b40] dark:bg-[#1e1f23] dark:hover:border-gray-500"
    }

    let rankClass = if rank == 1 {
      "text-amber-500"
    } else if podium {
      "text-gray-700 dark:text-gray-200"
    } else {
      "text-gray-300 dark:text-gray-600"
    }

    let tile = (label: string, value: string) =>
      <div className="bg-white/80 px-3 py-2 dark:bg-[#222326]/90">
        <p className="font-mono text-[8px] uppercase tracking-wider text-gray-400">
          {label->React.string}
        </p>
        <p className="mt-0.5 text-sm font-semibold text-gray-900 dark:text-gray-100">
          {value->React.string}
        </p>
      </div>

    <article className={"overflow-hidden rounded-xl border transition-colors " ++ cardClass}>
      <div className="flex items-start gap-3 p-4">
        <div className="flex w-11 flex-shrink-0 flex-col items-center sm:w-14">
          <span
            className={"font-mono text-2xl font-black italic leading-none " ++ rankClass}>
            {rank->Int.toString->React.string}
          </span>
          {rank == 1
            ? <Lucide.Crown size=13 className="mt-1 text-amber-500" />
            : React.null}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <span
              className={"h-2.5 w-2.5 flex-shrink-0 rounded-full " ++ Util.ClubDot.color(club.id)}
              ariaHidden=true
            />
            <Link
              to={"/clubs/" ++ slug}
              className="text-left text-sm font-semibold text-gray-900 hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-gray-100">
              {name->React.string}
            </Link>
            {switch club.viewerMembership->Option.flatMap(m => m.status) {
            | Some(Active) =>
              <span
                className="rounded-full bg-[#bdf25d]/40 px-1.5 py-0.5 font-mono text-[9px] font-semibold text-[#4d6f12] dark:bg-[#bdf25d]/20 dark:text-[#bdf25d]">
                {t`Member`}
              </span>
            | Some(Pending) =>
              <span
                className="rounded-full bg-gray-100 px-1.5 py-0.5 font-mono text-[9px] font-semibold text-gray-500 dark:bg-[#2a2b30] dark:text-gray-400">
                {t`Pending`}
              </span>
            | _ => React.null
            }}
          </div>
          <div
            className="mt-1 flex flex-wrap items-center gap-x-2 gap-y-1 font-mono text-[10px] text-gray-500 dark:text-gray-400">
            <span> {("@" ++ slug)->React.string} </span>
            {switch level {
            | Some(level) => <>
                <span ariaHidden=true> {"·"->React.string} </span>
                <span> {(level->Float.toFixed(~digits=1) ++ " DUPR")->React.string} </span>
              </>
            | None => React.null
            }}
          </div>
          <p className="mt-2 line-clamp-2 text-xs leading-relaxed text-gray-600 dark:text-gray-300">
            {club.description->Option.getOr("")->React.string}
          </p>
        </div>
        <div className="flex flex-shrink-0 flex-col items-end">
          <span
            className="font-mono text-xl font-semibold text-gray-900 dark:text-gray-100 sm:text-2xl">
            {club.score->Option.map(s => s->Float.toFixed(~digits=1))->Option.getOr("—")->React.string}
          </span>
          <span className="font-mono text-[8px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
            {t`Club score`}
          </span>
        </div>
      </div>
      <div
        className="grid grid-cols-2 gap-px border-t border-gray-200 bg-gray-200 dark:border-[#3a3b40] dark:bg-[#3a3b40] sm:grid-cols-4">
        {tile(
          Lingui.UtilString.t`Total members`,
          club.stats->Option.map(s => s.totalMembers->Int.toString)->Option.getOr("—"),
        )}
        {tile(
          Lingui.UtilString.t`Active players`,
          club.stats->Option.map(s => s.activeParticipants->Int.toString)->Option.getOr("—"),
        )}
        {tile(
          Lingui.UtilString.t`Median level`,
          level->Option.map(l => l->Float.toFixed(~digits=1))->Option.getOr("—"),
        )}
        {tile(
          Lingui.UtilString.t`Retention`,
          club.stats
          ->Option.flatMap(s => s.retentionRate)
          ->Option.map(rate => (rate *. 100.)->Float.toFixed(~digits=0) ++ "%")
          ->Option.getOr("—"),
        )}
      </div>
      <div
        className="flex items-center justify-between gap-2 border-t border-gray-100 px-4 py-2.5 dark:border-[#2a2b30]">
        <div className="min-w-0 truncate font-mono text-[10px] text-gray-400 dark:text-gray-500">
          {switch club.events.edges
          ->Option.getOr([])
          ->Array.filterMap(edge => edge->Option.flatMap(edge => edge.node))
          ->Array.get(0) {
          | Some(event) =>
            switch event.startDate {
            | Some(startDate) =>
              let date = startDate->Util.Datetime.toDate
              <>
                {(Lingui.UtilString.t`Next` ++ " ")->React.string}
                <ReactIntl.FormattedDate value=date month=#short day=#numeric />
                {", "->React.string}
                {switch event.timezone {
                | Some(tz) => <ReactIntl.FormattedTime value=date timeZone=tz />
                | None => <ReactIntl.FormattedTime value=date />
                }}
              </>
            | None => React.null
            }
          | None => t`No upcoming event`
          }}
        </div>
        <Link
          to={"/clubs/" ++ slug}
          className="rounded-lg px-2 py-1.5 text-xs font-semibold text-[#4d6f12] hover:bg-[#bdf25d]/15 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-[#bdf25d]">
          {t`View club`}
        </Link>
      </div>
    </article>
  }
}

@react.component
let make = () => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let data = useLoaderData()
  let query = Query.usePreloaded(~queryRef=data.data)
  let {data: clubsData, loadNext, hasNext, isLoadingNext} = Fragment.usePagination(
    query.fragmentRefs,
  )
  // The sidebar renders this page inside a sport, so the activity comes from
  // the path (/e/:activitySlug/clubs) rather than a control on the page. The
  // unscoped /clubs route has no segment and falls back to pickleball.
  let params: {"activitySlug": option<string>} = Router.useParams()
  let sport = params["activitySlug"]->Option.getOr("pickleball")
  let sportLabel = switch sport {
  | "badminton" => ts`Badminton`
  | _ => ts`Pickleball`
  }

  let (search, setSearch) = React.useState(() => "")

  // Rank comes from the server's ordering, so filtering the list narrows it
  // without renumbering the clubs that remain.
  let ranked = clubsData.clubs->Fragment.getConnectionNodes->Array.mapWithIndex((club, i) => (club, i + 1))

  let query_ = search->String.trim->String.toLowerCase
  let filtered = ranked->Array.filter((((club, _))) =>
    query_ == "" ||
      [club.name, club.slug]
      ->Array.filterMap(v => v)
      ->Array.some(v => v->String.toLowerCase->String.includes(query_))
  )

  let filtersActive = query_ != ""
  let clearFilters = () => setSearch(_ => "")

  <WaitForMessages>
    {_ =>
      <div className="flex h-full flex-1 flex-col overflow-hidden bg-white dark:bg-[#222326]">
        <div
          className="flex-shrink-0 border-b border-gray-200 px-4 py-5 dark:border-[#2a2b30] md:px-6">
          <h1 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
            {t`Clubs`}
            <span className="ml-2 font-normal text-gray-400 dark:text-gray-500">
              {("/ " ++ sportLabel->String.toLowerCase)->React.string}
            </span>
          </h1>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {t`Find and join clubs, ranked by activity, level of play and how many players come back.`}
          </p>
        </div>
        <section
          ariaLabel={ts`Club filters`}
          className="flex flex-shrink-0 flex-wrap items-center gap-1.5 border-b border-gray-200 bg-gray-50/70 px-4 py-2.5 dark:border-[#2a2b30] dark:bg-[#1e1f23]/70 md:px-6">
          <label className="relative min-w-[160px] flex-1 sm:max-w-[240px]">
            <span className="sr-only"> {t`Search clubs`} </span>
            <Lucide.Search
              size=13
              className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-gray-400"
              \"aria-hidden"="true"
            />
            <input
              type_="text"
              value=search
              onChange={e => {
                let value = ReactEvent.Form.target(e)["value"]
                setSearch(_ => value)
              }}
              placeholder={ts`Search clubs`}
              className={controlClass ++ " w-full pl-8 pr-3 placeholder:text-gray-400"}
            />
          </label>
          // The sport is no longer a filter here — the sidebar picks it and it
          // lives in the URL. A minimum-level filter belongs here (see the
          // design), but the only level signal we have is the median of a club's
          // *top* players, which is a poor stand-in for "can I play here". Left
          // out until the data supports it.
          {filtersActive
            ? <button
                type_="button"
                onClick={_ => clearFilters()}
                className="h-9 px-1.5 text-[10px] font-semibold text-gray-500 hover:text-gray-900 focus:outline-none focus-visible:underline dark:text-gray-400 dark:hover:text-gray-100">
                {t`Clear`}
              </button>
            : React.null}
          <span
            className="ml-auto whitespace-nowrap font-mono text-[10px] text-gray-500 dark:text-gray-400"
            ariaLive=#polite>
            {Lingui.UtilString.plural(
              filtered->Array.length,
              {one: ts`${filtered->Array.length->Int.toString} club`, other: ts`${filtered->Array.length->Int.toString} clubs`},
            )->React.string}
          </span>
        </section>
        <div className="flex-1 overflow-y-auto p-4 md:p-6">
          {filtered->Array.length == 0
            ? <div
                className="mx-auto flex max-w-md flex-col items-center rounded-xl border border-dashed border-gray-300 bg-gray-50 px-6 py-12 text-center dark:border-[#3a3b40] dark:bg-[#1e1f23]">
                <span
                  className="flex h-12 w-12 items-center justify-center rounded-full border border-gray-200 bg-white text-gray-400 dark:border-[#3a3b40] dark:bg-[#2a2b30]">
                  <Lucide.Users size=20 \"aria-hidden"="true" />
                </span>
                <h3 className="mt-4 text-sm font-semibold text-gray-900 dark:text-gray-100">
                  {t`No clubs match your filters`}
                </h3>
                <p className="mt-1 text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                  {t`Try a different search, or pick another sport in the sidebar.`}
                </p>
                {filtersActive
                  ? <button
                      type_="button"
                      onClick={_ => clearFilters()}
                      className="mt-4 rounded-md border border-gray-200 bg-white px-3 py-1.5 text-xs font-semibold text-gray-700 transition-colors hover:bg-gray-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-200 dark:hover:bg-[#2a2b30]">
                      {t`Clear filters`}
                    </button>
                  : React.null}
              </div>
            : <div className="mx-auto flex max-w-5xl flex-col gap-2.5">
                <div
                  className="hidden items-center px-4 font-mono text-[9px] uppercase tracking-wider text-gray-400 dark:text-gray-500 sm:flex">
                  <span className="w-14"> {t`Rank`} </span>
                  <span className="flex-1"> {t`Club`} </span>
                  <span className="w-24 text-right"> {t`Club score`} </span>
                </div>
                {filtered
                ->Array.map(((club, rank)) => <ClubCard key={club.id} club rank />)
                ->React.array}
                {hasNext
                  ? <button
                      type_="button"
                      disabled=isLoadingNext
                      onClick={_ => loadNext(~count=20)->RescriptRelay.Disposable.ignore}
                      className="mt-1 flex w-full items-center justify-center gap-2 rounded-xl border border-dashed border-gray-300 px-4 py-4 font-mono text-[10px] font-bold uppercase tracking-widest text-gray-400 transition-colors hover:border-[#a3d949] hover:text-[#4d6f12] disabled:opacity-50 dark:border-[#3a3b40] dark:text-gray-500 dark:hover:border-[#bdf25d]/60 dark:hover:text-[#bdf25d]">
                      {(isLoadingNext ? ts`Loading...` : ts`Load more clubs`)->React.string}
                    </button>
                  : React.null}
              </div>}
        </div>
      </div>}
  </WaitForMessages>
}

%%raw("import { t } from '@lingui/macro'")

module Fragment = %relay(`
  fragment PkuruSidebarClubs_viewer on Viewer
  @argumentDefinitions(
    first: { type: "Int", defaultValue: 20 }
    after: { type: "String" }
  )
  @refetchable(queryName: "PkuruSidebarClubsPaginationQuery") {
    clubs(first: $first, after: $after)
    @connection(key: "PkuruSidebarClubs_viewer_clubs") {
      edges {
        node {
          id
          name
          slug
          # The sidebar nests clubs under their sport, so each club needs the
          # activity it plays.
          defaultActivity {
            slug
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`)

module Query = %relay(`
  query PkuruSidebarClubsQuery {
    viewer {
      ...PkuruSidebarClubs_viewer
    }
  }
`)

module SidebarItem = {
  @react.component
  let make = (
    ~icon: option<React.element>=?,
    ~label: string,
    ~count: option<int>=?,
    ~active: bool=false,
    ~dotColor: option<string>=?,
    ~href: option<string>=?,
    ~onClick: option<unit => unit>=?,
  ) => {
    let navigate = LangProvider.Router.useNavigate()
    let className = Util.cx([
      "flex items-center justify-between px-3 py-1.5 rounded-md cursor-pointer text-sm",
      active
        ? "bg-[#bdf25d] font-medium text-black"
        : "hover:bg-gray-50 dark:hover:bg-[#2a2b30] text-gray-700 dark:text-gray-300",
    ])
    let inner =
      <>
        <div className="flex min-w-0 items-center gap-3">
          {icon->Option.getOr(React.null)}
          {dotColor
          ->Option.map(dc => <div className={"h-2.5 w-2.5 flex-shrink-0 rounded-full " ++ dc} />)
          ->Option.getOr(React.null)}
          <span className="truncate"> {label->React.string} </span>
        </div>
        {count
        ->Option.map(c =>
          <span
            className={Util.cx([
              "font-mono text-xs",
              active ? "text-black" : "text-gray-400 dark:text-gray-500",
            ])}>
            {c->Int.toString->React.string}
          </span>
        )
        ->Option.getOr(React.null)}
      </>
    switch href {
    | Some(h) =>
      <a
        className
        href=h
        onClick={e => {
          ReactEvent.Mouse.preventDefault(e)
          onClick->Option.forEach(fn => fn())
          navigate(h, None)
        }}>
        {inner}
      </a>
    | None => <div className onClick={_ => onClick->Option.forEach(fn => fn())}> {inner} </div>
    }
  }
}

// Nested under a sport in the sidebar accordion, so the list is scoped to that
// sport's clubs. `viewer.clubs` has no activity argument, so the filter happens
// here on the club's own activity.
@react.component
let make = (~activitySlug: string, ~onNavigate: option<unit => unit>=?) => {
  let ts = Lingui.UtilString.t
  let (_isPending, startTransition) = ReactExperimental.useTransition()
  let query = Query.use(~variables=())
  switch query.viewer {
  | None => React.null
  | Some(viewer) =>
    let {data, loadNext, hasNext, isLoadingNext} = Fragment.usePagination(viewer.fragmentRefs)
    let location = Router.useLocation()
    let clubs =
      data.clubs
      ->Fragment.getConnectionNodes
      ->Array.filter(club =>
        club.defaultActivity->Option.flatMap(a => a.slug) == Some(activitySlug)
      )
    clubs->Array.length == 0 && !hasNext
      ? React.null
      : <>
          <div
            className="mb-1 mt-3 px-3 font-mono text-[9px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
            {(ts`My clubs`)->React.string}
          </div>
          <div className="space-y-0.5">
            {clubs
            ->Array.map(club => {
              let slug = club.slug->Option.getOr("")
              <SidebarItem
                key={club.id}
                label={club.name->Option.getOr("")}
                dotColor={Util.ClubDot.color(club.id)}
                active={slug != "" && location.pathname->String.endsWith("/clubs/" ++ slug)}
                href={"/clubs/" ++ slug}
                onClick=?onNavigate
              />
            })
            ->React.array}
            {hasNext
              ? <button
                  className="w-full text-left px-3 py-1.5 text-xs text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 disabled:opacity-50"
                  onClick={_ =>
                    startTransition(() => {
                      loadNext(~count=20)->RescriptRelay.Disposable.ignore
                    })}
                  disabled=isLoadingNext>
                  {(isLoadingNext ? ts`Loading...` : ts`Load more`)->React.string}
                </button>
              : React.null}
          </div>
        </>
  }
}

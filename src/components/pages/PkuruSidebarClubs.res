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
        <div className="flex items-center gap-3">
          {icon->Option.getOr(React.null)}
          {dotColor
          ->Option.map(dc => <div className={"w-2.5 h-2.5 rounded-full " ++ dc} />)
          ->Option.getOr(React.null)}
          <span> {label->React.string} </span>
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

@react.component
let make = () => {
  let ts = Lingui.UtilString.t
  let (_isPending, startTransition) = ReactExperimental.useTransition()
  let query = Query.use(~variables=())
  switch query.viewer {
  | None => React.null
  | Some(viewer) =>
    let {data, loadNext, hasNext, isLoadingNext} = Fragment.usePagination(viewer.fragmentRefs)
    let clubs = data.clubs->Fragment.getConnectionNodes
    clubs->Array.length > 0
      ? <div>
          <div
            className="px-3 mb-2 text-[10px] font-mono text-gray-400 dark:text-gray-500 uppercase tracking-wider">
            {(ts`My clubs`)->React.string}
          </div>
          <div className="space-y-0.5">
            {clubs
            ->Array.map(club =>
              <SidebarItem
                key={club.id}
                label={club.name->Option.getOr("")}
                dotColor="bg-indigo-400"
                href=?{club.slug->Option.map(slug => "/clubs/" ++ slug)}
              />
            )
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
        </div>
      : React.null
  }
}

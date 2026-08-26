%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
%%raw("import '../../global/static.css'")

module Query = %relay(`
  query PkuruLayoutQuery {
    ...UseProfileGate_query
    viewer {
      user {
        id
      }
      viewerMetadata {
        id
        unreadInboxCount
      }
      ...GlobalQueryProvider_viewer
      ...NavViewer_viewer
      ...NotificationsPreview_viewer
    }
  }
`)

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<PkuruLayoutQuery_graphql.queryRef> =
  "useLoaderData"

@val @scope(("window", "document")) external documentBody: Dom.element = "body"
@val @scope(("window", "history")) external pushState: ('a, string, string) => unit = "pushState"
@val @scope("window")
external addPopstateListener: (string, unit => unit) => unit = "addEventListener"
@val @scope("window")
external removePopstateListener: (string, unit => unit) => unit = "removeEventListener"

module MediaQueryList = {
  type t
  type event = {matches: bool}
  @val external matchMedia: string => t = "window.matchMedia"
  @get external matches: t => bool = "matches"
  @send external addEventListener: (t, string, event => unit) => unit = "addEventListener"
  @send external removeEventListener: (t, string, event => unit) => unit = "removeEventListener"
}

type sport = {
  slug: string,
  label: string,
  dotColor: string,
  // Availability is scoped to a single Activity id and only pickleball's is
  // wired up (the API takes an activityId, not a slug), so the item stays
  // hidden for the other sports until a slug can be resolved.
  hasAvailability: bool,
}

// Everything the sidebar links to is activity-scoped, so the locale prefix has
// to come off before a path can be compared against "/e/<sport>/...".
let useAppPath = () => {
  let locale = React.useContext(LangProvider.LocaleContext.context)
  let location = Router.useLocation()
  let prefix = "/" ++ locale.lang
  if location.pathname == prefix {
    "/"
  } else if location.pathname->String.startsWith(prefix ++ "/") {
    location.pathname->String.sliceToEnd(~start=prefix->String.length)
  } else {
    location.pathname
  }
}

let iconClass = active => active ? "text-black" : "text-gray-500 dark:text-gray-400"

module SidebarItem = PkuruSidebarClubs.SidebarItem

let sportsList = () => {
  let ts = Lingui.UtilString.t
  [
    {slug: "pickleball", label: ts`Pickleball`, dotColor: "bg-green-600", hasAvailability: true},
    {slug: "badminton", label: ts`Badminton`, dotColor: "bg-blue-400", hasAvailability: false},
  ]
}

// "/" is the pickleball discover feed; the legacy unscoped /clubs and
// /availability paths resolve to pickleball too.
let activeSportSlug = (path: string) =>
  switch path {
  | "/" | "/clubs" | "/availability" => Some("pickleball")
  | _ =>
    sportsList()
    ->Array.find(s =>
      path->String.startsWith("/e/" ++ s.slug) || path->String.startsWith("/league/" ++ s.slug)
    )
    ->Option.map(s => s.slug)
  }

module SidebarContent = {
  @react.component
  let make = (
    ~isLoggedIn: bool,
    ~unreadCount: int=0,
    // The sidebar renders twice (mobile drawer + desktop rail); the surface
    // keeps the aria ids unique across the two copies.
    ~surfaceId: string,
    ~onNavigate: unit => unit=() => (),
  ) => {
    let ts = Lingui.UtilString.t
    let path = useAppPath()
    let navigate = LangProvider.Router.useNavigate()

    let sports = sportsList()
    let activeSport = activeSportSlug(path)

    let (expanded, setExpanded) = React.useState(() =>
      Some(activeSport->Option.getOr("pickleball"))
    )

    // Follow the URL when the sport changes under us (a link, the back button),
    // but leave a sport the user collapsed by hand alone.
    React.useEffect1(() => {
      activeSport->Option.forEach(slug => setExpanded(_ => Some(slug)))
      None
    }, [activeSport->Option.getOr("")])

    <div className="flex-1 overflow-y-auto px-2 py-4 space-y-6">
      <section ariaLabelledby={"sport-heading-" ++ surfaceId}>
        <div
          id={"sport-heading-" ++ surfaceId}
          className="mb-2 px-3 font-mono text-[10px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
          {(ts`Sports`)->React.string}
        </div>
        <div className="space-y-1">
          {sports
          ->Array.map(sport => {
            let isExpanded = expanded == Some(sport.slug)
            let isActive = activeSport == Some(sport.slug)
            let panelId = surfaceId ++ "-" ++ sport.slug ++ "-menu"
            let base = "/e/" ++ sport.slug
            let isDefault = sport.slug == "pickleball"
            let leaf = (scoped, legacy) => path == scoped || (isDefault && path == legacy)

            <div key={sport.slug}>
              <button
                type_="button"
                onClick={_ =>
                  if isExpanded {
                    setExpanded(_ => None)
                  } else {
                    setExpanded(_ => Some(sport.slug))
                    if !isActive {
                      navigate(base, None)
                    }
                  }}
                ariaExpanded={isExpanded}
                ariaControls={panelId}
                className={Util.cx([
                  "flex w-full items-center justify-between rounded-md px-3 py-2 text-sm transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a]",
                  isActive
                    ? "bg-gray-100 font-semibold text-gray-900 dark:bg-[#2a2b30] dark:text-gray-100"
                    : "text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-[#2a2b30]",
                ])}>
                <span className="flex min-w-0 items-center gap-3">
                  <span
                    className={"h-2.5 w-2.5 flex-shrink-0 rounded-full " ++ sport.dotColor}
                    ariaHidden=true
                  />
                  <span className="truncate"> {sport.label->React.string} </span>
                </span>
                <Lucide.ChevronDown
                  size=15
                  className={Util.cx([
                    "flex-shrink-0 text-gray-400 transition-transform duration-200",
                    isExpanded ? "rotate-180" : "",
                  ])}
                  \"aria-hidden"="true"
                />
              </button>
              <FramerMotion.AnimatePresence initial=false>
                {isExpanded
                  ? <FramerMotion.DivCss
                      key={panelId}
                      initial={{height: "0px", opacity: 0.}}
                      animate={{height: "auto", opacity: 1.}}
                      exit={{height: "0px", opacity: 0.}}
                      transition={{duration: 0.18}}
                      className="overflow-hidden">
                      <div
                        id={panelId}
                        className="mt-1 rounded-md bg-gray-50/70 pb-2 pt-1 dark:bg-[#24252a]">
                        <div className="space-y-0.5">
                          <SidebarItem
                            icon={<Lucide.Home size=16 className={iconClass(leaf(base, "/"))} />}
                            label={ts`Discover`}
                            active={leaf(base, "/")}
                            href=base
                            onClick=onNavigate
                          />
                          <SidebarItem
                            icon={<Lucide.Users
                              size=16 className={iconClass(leaf(base ++ "/clubs", "/clubs"))}
                            />}
                            label={ts`Clubs`}
                            active={leaf(base ++ "/clubs", "/clubs")}
                            href={base ++ "/clubs"}
                            onClick=onNavigate
                          />
                          {isLoggedIn && sport.hasAvailability
                            ? <SidebarItem
                                icon={<Lucide.CalendarRange
                                  size=16
                                  className={iconClass(
                                    leaf(base ++ "/availability", "/availability"),
                                  )}
                                />}
                                label={ts`Availability`}
                                active={leaf(base ++ "/availability", "/availability")}
                                href={base ++ "/availability"}
                                onClick=onNavigate
                              />
                            : React.null}
                          <SidebarItem
                            icon={<Lucide.Trophy
                              size=16
                              className={iconClass(
                                path->String.startsWith("/league/" ++ sport.slug),
                              )}
                            />}
                            label={ts`Leaderboard`}
                            active={path->String.startsWith("/league/" ++ sport.slug)}
                            href={"/league/" ++ sport.slug}
                            onClick=onNavigate
                          />
                          <SidebarItem
                            icon={<Lucide.Map
                              size=16 className={iconClass(path == base ++ "/map")}
                            />}
                            label={ts`Map view`}
                            active={path == base ++ "/map"}
                            href={base ++ "/map"}
                            onClick=onNavigate
                          />
                        </div>
                        {isLoggedIn
                          ? <React.Suspense fallback={React.null}>
                              <PkuruSidebarClubs
                                activitySlug={sport.slug} onNavigate={() => onNavigate()}
                              />
                            </React.Suspense>
                          : React.null}
                      </div>
                    </FramerMotion.DivCss>
                  : React.null}
              </FramerMotion.AnimatePresence>
            </div>
          })
          ->React.array}
        </div>
      </section>
      {isLoggedIn
        ? <section ariaLabelledby={"personal-heading-" ++ surfaceId}>
            <div
              id={"personal-heading-" ++ surfaceId}
              className="mb-2 px-3 font-mono text-[10px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
              {(ts`Personal`)->React.string}
            </div>
            <div className="space-y-0.5">
              <SidebarItem
                icon={<Lucide.CalendarDays size=16 className={iconClass(path == "/events")} />}
                label={ts`My events`}
                active={path == "/events"}
                href="/events"
                onClick=onNavigate
              />
              <SidebarItem
                icon={<Lucide.Bell
                  className={"w-4 h-4 " ++ iconClass(path == "/notifications")}
                />}
                label={ts`Notifications`}
                count=?{unreadCount > 0 ? Some(unreadCount) : None}
                active={path == "/notifications"}
                href="/notifications"
                onClick=onNavigate
              />
              <SidebarItem
                icon={<Lucide.User size=16 className={iconClass(path == "/settings/profile")} />}
                label={ts`Profile`}
                active={path == "/settings/profile"}
                href="/settings/profile"
                onClick=onNavigate
              />
            </div>
          </section>
        : React.null}
      <div className="px-3 py-1.5">
        <LangSwitch />
      </div>
    </div>
  }
}

module BrandLogo = {
  @module("/src/assets/pkuru.com.png") external pkuruLogo: string = "default"

  @react.component
  let make = () => {
    <LangProvider.Router.Link to="/">
      <img src=pkuruLogo alt="Pkuru" className="h-6 w-auto dark:invert" />
    </LangProvider.Router.Link>
  }
}

// The sidebar header carries the activity context the menu below it is scoped to.
module SidebarHeader = {
  @react.component
  let make = () => {
    let path = useAppPath()
    let label =
      activeSportSlug(path)
      ->Option.flatMap(slug => sportsList()->Array.find(s => s.slug == slug))
      ->Option.map(s => s.label->String.toLowerCase)

    <div
      className="h-14 flex items-center gap-2 px-4 border-b border-gray-200 dark:border-[#2a2b30]">
      <BrandLogo />
      {switch label {
      | Some(label) =>
        <span className="truncate text-sm font-normal text-gray-400 dark:text-gray-500">
          {("/ " ++ label)->React.string}
        </span>
      | None => React.null
      }}
    </div>
  }
}

module Topbar = {
  @react.component
  let make = (
    ~onToggleSidebar: unit => unit,
    ~viewer: option<Query.Types.response_viewer>,
    ~onNewPlan: unit => unit,
  ) => {
    let ts = Lingui.UtilString.t
    let navigate = LangProvider.Router.useNavigate()
    let isLoggedIn = viewer->Option.flatMap(v => v.user)->Option.isSome
    let (showBell, setShowBell) = React.useState(() => false)
    let loginHref = "/oauth-login?return=/events/create"

    <div
      className="h-14 border-b border-gray-200 dark:border-[#2a2b30] flex items-center justify-between px-4 bg-white dark:bg-[#1e1f23] flex-shrink-0 touch-none">
      // Mobile: hamburger + logo
      <div className="flex items-center gap-3 md:hidden">
        <button
          onClick={_ => onToggleSidebar()}
          className="text-gray-600 dark:text-gray-400 hover:text-black dark:hover:text-white">
          <Lucide.Menu size=20 />
        </button>
        <BrandLogo />
      </div>
      // Desktop: search (commented out - feature not yet available)
      /* <div className="hidden md:flex items-center gap-2 text-gray-400 dark:text-gray-500 flex-1">
        <Lucide.Search size=16 />
        <input
          type_="text"
          placeholder={ts`Search events, venues, hosts...`}
          className="w-full bg-transparent border-none focus:outline-none text-sm text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500"
        />
      </div> */
      // Right side actions
      <div className="flex items-center gap-3 md:gap-4 text-gray-600 dark:text-gray-400 ml-auto">
        <button
          onClick={_ =>
            if isLoggedIn {
              onNewPlan()
            } else {
              navigate(loginHref, None)
            }}
          className="hidden md:flex items-center gap-1.5 px-3.5 py-1.5 text-sm font-semibold bg-[#bdf25d] hover:bg-[#aee050] text-black rounded-md transition-colors shadow-sm">
          <Lucide.CalendarDays size=14 />
          <span> {(ts`New event`)->React.string} </span>
        </button>
        <LangProvider.Router.Link to="/events" className="hover:text-black dark:hover:text-white">
          <Lucide.Calendar size=18 />
        </LangProvider.Router.Link>
        {viewer
        ->Option.map((v: Query.Types.response_viewer) =>
          <div className="relative flex items-center">
            <button
              onMouseDown={e => e->ReactEvent.Mouse.stopPropagation}
              onClick={_ => setShowBell(prev => !prev)}
              title={ts`Notifications`}
              className="relative flex items-center justify-center hover:text-black dark:hover:text-white">
              <Lucide.Bell className="w-[18px] h-[18px]" />
              {v.viewerMetadata->Option.map(m => m.unreadInboxCount)->Option.getOr(0) > 0
                ? <span
                    className="absolute -top-0.5 -right-0.5 w-2 h-2 rounded-full bg-red-500 ring-2 ring-white dark:ring-[#1e1f23]"
                  />
                : React.null}
            </button>
            <FramerMotion.AnimatePresence>
              {showBell
                ? <NotificationsPreview
                    viewer=v.fragmentRefs
                    onClose={() => setShowBell(_ => false)}
                    onViewAll={() => {
                      setShowBell(_ => false)
                      navigate("/notifications", None)
                    }}
                  />
                : React.null}
            </FramerMotion.AnimatePresence>
          </div>
        )
        ->Option.getOr(React.null)}
        {isLoggedIn
          ? <LangProvider.Router.Link
              to="/settings/profile" className="hover:text-black dark:hover:text-white">
              <Lucide.Settings size=18 />
            </LangProvider.Router.Link>
          : React.null}
        {viewer
        ->Option.map((viewer: Query.Types.response_viewer) =>
          <React.Suspense
            fallback={<div
              className="hidden md:flex w-7 h-7 rounded-full bg-gray-100 dark:bg-[#2a2b30] items-center justify-center text-xs font-medium text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-[#3a3b40] cursor-pointer">
              {"..."->React.string}
            </div>}>
            <NavViewer viewer=viewer.fragmentRefs />
          </React.Suspense>
        )
        ->Option.getOr(<LoginLink />)}
      </div>
    </div>
  }
}

module MobileSidebar = {
  @react.component
  let make = (~isOpen: bool, ~onClose: unit => unit, ~isLoggedIn: bool, ~unreadCount: int) => {
    <FramerMotion.AnimatePresence>
      {isOpen
        ? <>
            <FramerMotion.DivCss
              className="fixed inset-0 bg-black/40 dark:bg-black/60 z-40 md:hidden"
              initial={{opacity: 0.}}
              animate={{opacity: 1.}}
              exit={{opacity: 0.}}
              onClick={_ => onClose()}
            />
            <FramerMotion.DivCss
              className="fixed top-0 left-0 bottom-0 w-[280px] bg-white dark:bg-[#1e1f23] z-50 md:hidden flex flex-col shadow-xl"
              initial={{x: -280.}}
              animate={{x: 0.}}
              exit={{x: -280.}}>
              <SidebarHeader />
              <SidebarContent isLoggedIn unreadCount surfaceId="mobile" onNavigate=onClose />
            </FramerMotion.DivCss>
          </>
        : React.null}
    </FramerMotion.AnimatePresence>
  }
}

module MobileTabs = {
  @react.component
  let make = (~onNewPlan: unit => unit) => {
    let ts = Lingui.UtilString.t
    let location = Router.useLocation()
    let pathname = location.pathname

    let tabClass = active =>
      Util.cx([
        "flex flex-col items-center gap-0.5 py-2 px-3 text-[10px]",
        active ? "text-black dark:text-white" : "text-gray-400 dark:text-gray-500",
      ])

    let activeSlug = activeSportSlug(useAppPath())->Option.getOr("pickleball")

    <nav
      className="md:hidden border-t border-gray-200 dark:border-[#2a2b30] bg-white dark:bg-[#1e1f23] flex items-center justify-around px-2 touch-none relative z-30"
      style={ReactDOM.Style.make(~paddingBottom="env(safe-area-inset-bottom, 0)", ())}>
      <LangProvider.Router.Link className={tabClass(pathname == "/")} to="/">
        <Lucide.Home size=20 />
        {(ts`Discover`)->React.string}
      </LangProvider.Router.Link>
      <LangProvider.Router.Link
        className={tabClass(pathname->String.includes("/map"))} to={"/e/" ++ activeSlug ++ "/map"}>
        <Lucide.Map size=20 />
        {(ts`Map`)->React.string}
      </LangProvider.Router.Link>
      <button
        onClick={_ => onNewPlan()} className="flex flex-col items-center justify-center -mt-3">
        <div
          className="w-11 h-11 rounded-full bg-[#bdf25d] hover:bg-[#aee050] flex items-center justify-center shadow-md active:scale-95 transition-transform">
          <Lucide.Plus size=20 className="text-black" />
        </div>
        <span className="text-[10px] font-medium text-gray-400 dark:text-gray-500 mt-0.5">
          {(ts`New`)->React.string}
        </span>
      </button>
      <LangProvider.Router.Link
        className={tabClass(pathname->String.includes("/events"))} to="/events">
        <Lucide.CalendarDays size=20 />
        {(ts`My Events`)->React.string}
      </LangProvider.Router.Link>
      <LangProvider.Router.Link
        className={tabClass(
          pathname->String.includes("/profile") || pathname->String.includes("/settings"),
        )}
        to="/settings/profile">
        <Lucide.User size=20 />
        {(ts`Profile`)->React.string}
      </LangProvider.Router.Link>
    </nav>
  }
}

let defaultActivityId = "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"

module Layout = {
  @react.component
  let make = (
    ~viewer: option<PkuruLayoutQuery_graphql.Types.response_viewer>,
    ~queryRefs: RescriptRelay.fragmentRefs<[> #UseProfileGate_query]>,
    ~children: React.element,
  ) => {
    let isLoggedIn = viewer->Option.flatMap(v => v.user)->Option.isSome
    let unreadCount =
      viewer
      ->Option.flatMap(v => v.viewerMetadata)
      ->Option.map(m => m.unreadInboxCount)
      ->Option.getOr(0)
    let profileGate = UseProfileGate.use(~query=queryRefs, ~context=ProfileModal.Availability)
    let (showModal, setShowModal) = React.useState(() => false)
    let (commitSetAvailability, _) = UseSetAvailabilityDay.use()
    let env = RescriptRelay.useEnvironmentFromContext()
    let (sidebarOpen, setSidebarOpen) = React.useState(() => false)
    let (drawerContent, setDrawerContent) = React.useState((): option<React.element> => None)
    let (drawerUrl, setDrawerUrl) = React.useState((): option<string> => None)
    let (preDrawerUrl, setPreDrawerUrl) = React.useState((): option<string> => None)
    let (mounted, setMounted) = React.useState(() => false)
    let (darkMode, setDarkMode) = React.useState(() => false)
    let navigate = Router.useNavigate()
    let location = Router.useLocation()

    let handleMarkAvailable = (localDate: string, intents: array<TimeWindow.playIntent>) => {
      let _ = commitSetAvailability(
        ~localDate,
        ~activityId=defaultActivityId,
        ~intervals=UseSetAvailabilityDay.intervalsOfIntents(intents),
        ~onCompleted=(res, _err) => {
          if res.setAvailabilityDay.day->Option.isSome {
            RescriptRelay.commitLocalUpdate(~environment=env, ~updater=store =>
              store
              ->RescriptRelay.RecordSourceSelectorProxy.getRoot
              ->RescriptRelay.RecordProxy.invalidateRecord
            )
          }
        },
      )
    }

    let handleCreateEvent = (localDate: string, intent: TimeWindow.playIntent) => {
      let startHour = intent.start->Float.toInt
      let endHour = intent.end->Float.toInt
      navigate(
        "/events/create?date=" ++
        localDate ++
        "&startHour=" ++
        startHour->Int.toString ++
        "&endHour=" ++
        endHour->Int.toString,
        None,
      )
    }

    let handleNewPlan = () => {
      navigate(
        if isLoggedIn {
          "/events/create"
        } else {
          "/oauth-login?return=/events/create"
        },
        None,
      )
    }
    let localePath = LangProvider.Router.useLocalePath()
    let gviewer = viewer->Option.map(v => v.fragmentRefs)

    React.useEffect0(() => {
      let mq = MediaQueryList.matchMedia("(prefers-color-scheme: dark)")
      setDarkMode(_ => mq->MediaQueryList.matches)
      setMounted(_ => true)
      let handleChange = (e: MediaQueryList.event) => {
        setDarkMode(_ => e.matches)
      }
      mq->MediaQueryList.addEventListener("change", handleChange)
      Some(() => mq->MediaQueryList.removeEventListener("change", handleChange))
    })

    React.useEffect0(() => {
      let handler = () => {
        setDrawerContent(_ => None)
        setDrawerUrl(_ => None)
        setPreDrawerUrl(_ => None)
      }
      addPopstateListener("popstate", handler)
      Some(() => removePopstateListener("popstate", handler))
    })

    React.useEffect1(() => {
      if drawerContent->Option.isSome {
        setDrawerContent(_ => None)
        setDrawerUrl(_ => None)
        setPreDrawerUrl(_ => None)
      }
      None
    }, [location.pathname])

    let openDrawer = (content, url) => {
      setPreDrawerUrl(_ => Some(location.pathname ++ location.search))
      pushState(Js.Obj.empty(), "", localePath(url))
      setDrawerContent(_ => Some(content))
      setDrawerUrl(_ => Some(url))
    }

    let closeDrawer = () => {
      let returnUrl = preDrawerUrl->Option.getOr("/")
      setDrawerContent(_ => None)
      setDrawerUrl(_ => None)
      setPreDrawerUrl(_ => None)
      navigate(returnUrl, None)
    }

    let dismissDrawer = () => {
      setDrawerContent(_ => None)
      setDrawerUrl(_ => None)
      setPreDrawerUrl(_ => None)
    }

    let ctx: DrawerContext.contextValue = {openDrawer, closeDrawer}

    <GlobalQuery.Provider value={gviewer}>
      <DrawerContext.Provider value=ctx>
        <WaitForMessages>
          {() =>
            <div className={darkMode ? "dark" : ""}>
              <div
                className="flex h-[100dvh] w-full bg-white dark:bg-[#1a1a1e] text-gray-900 dark:text-gray-100 font-sans overflow-hidden overscroll-none transition-colors duration-200">
                // Mobile sidebar overlay
                <MobileSidebar
                  isOpen=sidebarOpen
                  onClose={() => setSidebarOpen(_ => false)}
                  isLoggedIn
                  unreadCount
                />
                // Desktop sidebar
                <div
                  className="hidden md:flex w-[200px] flex-shrink-0 border-r border-gray-200 dark:border-[#2a2b30] bg-white dark:bg-[#1e1f23] flex-col">
                  <SidebarHeader />
                  <SidebarContent isLoggedIn unreadCount surfaceId="desktop" />
                </div>
                // Main content + top bar wrapper
                <div
                  className="flex-1 flex flex-col min-w-0 overflow-hidden bg-white dark:bg-[#222326]">
                  <Topbar
                    onToggleSidebar={() => setSidebarOpen(prev => !prev)}
                    viewer
                    onNewPlan=handleNewPlan
                  />
                  <InstallPwa />
                  <div className="flex-1 overflow-y-auto overscroll-contain">
                    <React.Suspense fallback={React.null}> {children} </React.Suspense>
                  </div>
                  <MobileTabs onNewPlan=handleNewPlan />
                </div>
                {mounted
                  ? ReactDOM.createPortal(
                      <div className={darkMode ? "dark" : ""}>
                        <FramerMotion.AnimatePresence>
                          {drawerContent
                          ->Option.map(content =>
                            <React.Fragment key="drawer">
                              <FramerMotion.Div
                                key="drawer-backdrop"
                                className="fixed inset-0 bg-black/40 z-40"
                                initial={FramerMotion.opacity: 0.}
                                animate={FramerMotion.opacity: 1.}
                                exit={FramerMotion.opacity: 0.}
                                onClick={_ => closeDrawer()}
                              />
                              <FramerMotion.Div
                                key="drawer-panel"
                                className="fixed inset-y-0 right-0 w-full max-w-2xl bg-white dark:bg-[#1e1f23] shadow-2xl z-50 flex flex-col overflow-hidden"
                                initial={FramerMotion.x: 700.}
                                animate={FramerMotion.x: 0.}
                                exit={FramerMotion.x: 700.}
                                transition={
                                  FramerMotion.type_: "spring",
                                  stiffness: 900,
                                  damping: 35,
                                  mass: 0.4,
                                }>
                                <div
                                  className="flex items-center justify-between px-4 md:px-6 py-2 border-b border-gray-200 dark:border-[#3a3b40] flex-shrink-0">
                                  <div
                                    className="flex items-center gap-2 text-gray-400 dark:text-gray-500">
                                    {drawerUrl
                                    ->Option.map(url =>
                                      <button
                                        onClick={_ => {
                                          dismissDrawer()
                                          navigate(localePath(url), None)
                                        }}
                                        className="p-1 rounded-md text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-[#2a2b30] transition-colors">
                                        <Lucide.Maximize2 className="w-4 h-4" />
                                      </button>
                                    )
                                    ->Option.getOr(React.null)}
                                  </div>
                                  <button
                                    onClick={_ => closeDrawer()}
                                    className="p-1 rounded-md text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-[#2a2b30] transition-colors">
                                    <Lucide.X size=20 />
                                  </button>
                                </div>
                                <div className="flex-1 overflow-y-auto">
                                  <React.Suspense
                                    fallback={<div
                                      className="flex items-center justify-center h-32 text-gray-400 dark:text-gray-500 text-sm font-mono">
                                      {t`Loading...`}
                                    </div>}>
                                    {content}
                                  </React.Suspense>
                                </div>
                              </FramerMotion.Div>
                            </React.Fragment>
                          )
                          ->Option.getOr(React.null)}
                        </FramerMotion.AnimatePresence>
                        <NewPlanModal.make
                          isOpen=showModal
                          onClose={() => setShowModal(_ => false)}
                          onMarkAvailable={(localDate, intents) =>
                            profileGate.require(() => handleMarkAvailable(localDate, intents))}
                          onCreateEvent=handleCreateEvent
                        />
                        {profileGate.modal}
                      </div>,
                      documentBody,
                    )
                  : React.null}
              </div>
            </div>}
        </WaitForMessages>
      </DrawerContext.Provider>
    </GlobalQuery.Provider>
  }
}

@genType @react.component
let make = () => {
  let query = useLoaderData()
  let {viewer, fragmentRefs} = Query.usePreloaded(~queryRef=query.data)

  <>
    <Util.Helmet>
      <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
      />
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      <link
        href="https://fonts.googleapis.com/css2?family=Inter+Tight:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap"
        rel="stylesheet"
      />
      <link rel="icon" type_="image/x-icon" href="/src/assets/favicon.ico" />
      <link rel="apple-touch-icon" href="/src/assets/apple-touch-icon.png" />
    </Util.Helmet>
    <Layout viewer queryRefs=fragmentRefs>
      <GlobalQuery.DetectedLang />
      <Router.Outlet />
    </Layout>
  </>
}

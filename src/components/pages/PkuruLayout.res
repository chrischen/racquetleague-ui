%%raw("import { t } from '@lingui/macro'")
%%raw("import '../../global/static.css'")

module Query = %relay(`
  query PkuruLayoutQuery {
    viewer {
      user {
        id
      }
      ...GlobalQueryProvider_viewer
      ...NavViewer_viewer
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

module SidebarContent = {
  @react.component
  let make = (~isLoggedIn: bool) => {
    let ts = Lingui.UtilString.t
    let location = Router.useLocation()
    let pathname = location.pathname
    let params: {"activitySlug": option<string>} = Router.useParams()
    let activeSlug = switch params["activitySlug"] {
    | Some("badminton") => "badminton"
    | Some("pickleball") => "pickleball"
    | Some(_) | None => ""
    }
    let mapSlug = if activeSlug == "" {
      "pickleball"
    } else {
      activeSlug
    }

    open PkuruSidebarClubs
    <div className="flex-1 overflow-y-auto py-4 px-2 space-y-6">
      <div>
        <div
          className="px-3 mb-2 text-[10px] font-mono text-gray-400 dark:text-gray-500 uppercase tracking-wider">
          {(ts`Browse`)->React.string}
        </div>
        <div className="space-y-0.5">
          <SidebarItem
            icon={<Lucide.Home
              size=16
              className={pathname == "/" ? "text-black" : "text-gray-500 dark:text-gray-400"}
            />}
            label={ts`Discover`}
            href="/"
          />
          <SidebarItem
            icon={<Lucide.Map size=16 className="text-gray-500 dark:text-gray-400" />}
            label={ts`Map view`}
            href={"/e/" ++ mapSlug ++ "/map"}
          />
          {isLoggedIn
            ? <SidebarItem
                icon={<Lucide.CalendarDays size=16 className="text-gray-500 dark:text-gray-400" />}
                label={ts`My events`}
                href="/events"
              />
            : React.null}
          {isLoggedIn
            ? <SidebarItem
                icon={<Lucide.User size=16 className="text-gray-500 dark:text-gray-400" />}
                label={ts`Profile`}
                href="/settings/profile"
              />
            : React.null}
        </div>
      </div>
      <div>
        <div
          className="px-3 mb-2 text-[10px] font-mono text-gray-400 dark:text-gray-500 uppercase tracking-wider">
          {(ts`Sports`)->React.string}
        </div>
        <div className="space-y-0.5">
          <SidebarItem
            label={ts`Pickleball`}
            active={activeSlug == "pickleball"}
            dotColor="bg-green-600"
            href="/e/pickleball"
          />
          <SidebarItem
            label={ts`Badminton`}
            active={activeSlug == "badminton"}
            dotColor="bg-blue-400"
            href="/e/badminton"
          />
          // <SidebarItem label={ts`Crossminton`} count=13 dotColor="bg-red-400" />
        </div>
      </div>
      <div>
        <div
          className="px-3 mb-2 text-[10px] font-mono text-gray-400 dark:text-gray-500 uppercase tracking-wider">
          {(ts`Rankings`)->React.string}
        </div>
        <div className="space-y-0.5">
          <SidebarItem
            icon={<Lucide.Trophy className="w-4 h-4 text-gray-500 dark:text-gray-400" />}
            label={ts`Pickleball`}
            active={pathname->String.includes("/league/pickleball")}
            href="/league/pickleball"
          />
          <SidebarItem
            icon={<Lucide.Trophy className="w-4 h-4 text-gray-500 dark:text-gray-400" />}
            label={ts`Badminton`}
            active={pathname->String.includes("/league/badminton")}
            href="/league/badminton"
          />
        </div>
      </div>
      <React.Suspense fallback={React.null}>
        <PkuruSidebarClubs />
      </React.Suspense>
      <div className="px-3 py-1.5">
        <LangSwitch />
      </div>
    </div>
  }
}

module BrandLogo = {
  @react.component
  let make = (~showBreadcrumb: bool=true) => {
    <div className="flex items-center gap-2">
      <div
        className="w-6 h-6 bg-[#bdf25d] rounded flex items-center justify-center font-bold text-sm text-black">
        {"P"->React.string}
      </div>
      <span className="font-semibold text-sm tracking-tight dark:text-gray-100">
        {"Pkuru "->React.string}
        {showBreadcrumb
          ? <span className="text-gray-400 dark:text-gray-500 font-normal">
              {"/ discover"->React.string}
            </span>
          : React.null}
      </span>
    </div>
  }
}

module Topbar = {
  @react.component
  let make = (~onToggleSidebar: unit => unit, ~viewer: option<Query.Types.response_viewer>) => {
    let ts = Lingui.UtilString.t
    let isLoggedIn = viewer->Option.flatMap(v => v.user)->Option.isSome
    let hostHref = if isLoggedIn {
      "/events/create"
    } else {
      "/oauth-login?return=/events/create"
    }

    <div
      className="h-14 border-b border-gray-200 dark:border-[#2a2b30] flex items-center justify-between px-4 bg-white dark:bg-[#1e1f23] flex-shrink-0 touch-none">
      // Mobile: hamburger + logo
      <div className="flex items-center gap-3 md:hidden">
        <button
          onClick={_ => onToggleSidebar()}
          className="text-gray-600 dark:text-gray-400 hover:text-black dark:hover:text-white">
          <Lucide.Menu size=20 />
        </button>
        <BrandLogo showBreadcrumb=false />
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
        <LangProvider.Router.Link
          to=hostHref
          className="hidden md:flex items-center gap-1.5 px-3.5 py-1.5 text-sm font-semibold bg-[#bdf25d] hover:bg-[#aee050] text-black rounded-md transition-colors shadow-sm">
          <Lucide.CalendarDays size=14 />
          <span> {(ts`New event`)->React.string} </span>
        </LangProvider.Router.Link>
        <LangProvider.Router.Link to="/events" className="hover:text-black dark:hover:text-white">
          <Lucide.Calendar size=18 />
        </LangProvider.Router.Link>
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
  let make = (~isOpen: bool, ~onClose: unit => unit, ~isLoggedIn: bool) => {
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
              <div
                className="h-14 flex items-center px-4 border-b border-gray-200 dark:border-[#2a2b30]">
                <BrandLogo />
              </div>
              <SidebarContent isLoggedIn />
            </FramerMotion.DivCss>
          </>
        : React.null}
    </FramerMotion.AnimatePresence>
  }
}

module MobileTabs = {
  @react.component
  let make = (~hostHref: string) => {
    let ts = Lingui.UtilString.t
    let location = Router.useLocation()
    let pathname = location.pathname

    let tabClass = active =>
      Util.cx([
        "flex flex-col items-center gap-0.5 py-2 px-3 text-[10px]",
        active ? "text-black dark:text-white" : "text-gray-400 dark:text-gray-500",
      ])

    let activeSlug = if pathname->String.includes("/e/badminton") {
      "badminton"
    } else {
      "pickleball"
    }

    <nav
      className="md:hidden border-t border-gray-200 dark:border-[#2a2b30] bg-white dark:bg-[#1e1f23] flex items-center justify-around px-2 touch-none"
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
      <LangProvider.Router.Link
        to=hostHref className="flex flex-col items-center justify-center -mt-3">
        <div
          className="w-11 h-11 rounded-full bg-[#bdf25d] hover:bg-[#aee050] flex items-center justify-center shadow-md active:scale-95 transition-transform">
          <Lucide.Plus size=20 className="text-black" />
        </div>
        <span className="text-[10px] font-medium text-gray-400 dark:text-gray-500 mt-0.5">
          {(ts`New`)->React.string}
        </span>
      </LangProvider.Router.Link>
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

module Layout = {
  @react.component
  let make = (
    ~viewer: option<PkuruLayoutQuery_graphql.Types.response_viewer>,
    ~children: React.element,
  ) => {
    let isLoggedIn = viewer->Option.flatMap(v => v.user)->Option.isSome
    let hostHref = if isLoggedIn {
      "/events/create"
    } else {
      "/oauth-login?return=/events/create"
    }
    let (sidebarOpen, setSidebarOpen) = React.useState(() => false)
    let (drawerContent, setDrawerContent) = React.useState((): option<React.element> => None)
    let (drawerUrl, setDrawerUrl) = React.useState((): option<string> => None)
    let (preDrawerUrl, setPreDrawerUrl) = React.useState((): option<string> => None)
    let (mounted, setMounted) = React.useState(() => false)
    let (darkMode, setDarkMode) = React.useState(() => false)
    let navigate = Router.useNavigate()
    let location = Router.useLocation()
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
                  isLoggedIn={viewer->Option.flatMap(v => v.user)->Option.isSome}
                />
                // Desktop sidebar
                <div
                  className="hidden md:flex w-[200px] flex-shrink-0 border-r border-gray-200 dark:border-[#2a2b30] bg-white dark:bg-[#1e1f23] flex-col">
                  <div
                    className="h-14 flex items-center px-4 border-b border-gray-200 dark:border-[#2a2b30]">
                    <BrandLogo />
                  </div>
                  <SidebarContent isLoggedIn={viewer->Option.flatMap(v => v.user)->Option.isSome} />
                </div>
                // Main content + top bar wrapper
                <div
                  className="flex-1 flex flex-col min-w-0 overflow-hidden bg-white dark:bg-[#222326]">
                  <Topbar onToggleSidebar={() => setSidebarOpen(prev => !prev)} viewer />
                  <div className="flex-1 overflow-y-auto overscroll-contain">
                    <React.Suspense fallback={React.null}> {children} </React.Suspense>
                  </div>
                  <MobileTabs hostHref />
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
                                  className="flex items-center justify-between px-4 md:px-6 py-4 border-b border-gray-200 dark:border-[#3a3b40] flex-shrink-0">
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
                                      {"Loading..."->React.string}
                                    </div>}>
                                    {content}
                                  </React.Suspense>
                                </div>
                              </FramerMotion.Div>
                            </React.Fragment>
                          )
                          ->Option.getOr(React.null)}
                        </FramerMotion.AnimatePresence>
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
  let {viewer} = Query.usePreloaded(~queryRef=query.data)

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
    <Layout viewer>
      <GlobalQuery.DetectedLang />
      <Router.Outlet />
    </Layout>
  </>
}

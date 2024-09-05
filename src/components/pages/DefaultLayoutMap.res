%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
%%raw("import '../../global/static.css'")

module Query = %relay(`
  query DefaultLayoutMapQuery {
    ...Nav_query
    viewer { 
      ... GlobalQueryProvider_viewer
      user {
        lineUsername
        picture
      }
    }
  }
`)

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<DefaultLayoutMapQuery_graphql.queryRef> =
  "useLoaderData"

// module MenuInstance = {
//   @module("../ui/navigation-menu") @react.component
//   external make: unit => React.element = "MenuInstance"
// }

module Content = {
  @react.component
  let make = (~children) => {
    <div
      className="grow p-0 lg:rounded-lg lg:bg-white lg:p-10 lg:shadow-sm lg:ring-1 lg:ring-zinc-950/5 dark:lg:bg-zinc-900 dark:lg:ring-white/10">
      <div className="mx-auto max-w-7xl"> {children} </div>
    </div>
  }
}

module ActivityDropdownMenu = {
  type navItem = {label: string, url: string, initials?: string}
  let ts = Lingui.UtilString.t
  @react.component
  let make = () => {
    let activities = [
      {label: ts`All`, url: "/"},
      {label: ts`Pickleball`, url: "/?activity=pickleball", initials: "P"},
      {label: ts`Badminton`, url: "/?activity=badminton", initials: "B"},
    ]
    open Dropdown
    <DropdownMenu className="min-w-80 lg:min-w-64" anchor="bottom start">
      {activities
      ->Array.map(a => <React.Fragment key={a.label}>
        <DropdownItem href=a.url>
          {a.initials
          ->Option.map(initials =>
            <Avatar slot="icon" initials className="bg-purple-500 text-white" />
          )
          ->Option.getOr(React.null)}
          <DropdownLabel> {a.label->React.string} </DropdownLabel>
        </DropdownItem>
        <DropdownDivider />
      </React.Fragment>)
      ->React.array}
    </DropdownMenu>
  }
}
module ActivityLeagueDropdownMenu = {
  type navItem = {label: string, url: string, initials?: string}
  let ts = Lingui.UtilString.t
  @react.component
  let make = () => {
    let activities = [
      {label: ts`Pickleball`, url: "/league/pickleball", initials: "P"},
      {label: ts`Badminton`, url: "/league/badminton", initials: "B"},
    ]
    open Dropdown
    <DropdownMenu className="min-w-80 lg:min-w-64" anchor="bottom start">
      {activities
      ->Array.map(a => <React.Fragment key={a.label} >
        <DropdownItem href=a.url>
          {a.initials
          ->Option.map(initials =>
            <Avatar slot="icon" initials className="bg-purple-500 text-white" />
          )
          ->Option.getOr(React.null)}
          <DropdownLabel> {a.label->React.string} </DropdownLabel>
        </DropdownItem>
        <DropdownDivider />
      </React.Fragment>)
      ->React.array}
    </DropdownMenu>
  }
}

type params = {activitySlug: string, lang: option<string>}
module Layout = {
  @react.component
  let make = (~viewer: option<Query.Types.response_viewer>, ~children: React.element) => {
    open Lingui.Util
    // let params: params = Router.useParams()
    // let (searchParams, _) = Router.useSearchParamsFunc()
    // let activity = params.activitySlug
    // let activity = searchParams->Router.SearchParams.get("activity")
    // let activitySearchParam = activity->Option.map(a => "?activity=" ++ a)->Option.getOr("")
    // let navItems = [
    //   // {label: "Home", url: "/"},
    //   {ActivityDropdownMenu.label: ts`Events`, url: "/" ++ activity},
    //   {label: ts`Rankings`, url: "/league/" ++ activity},
    // ]

    open Dropdown
    open Sidebar
    open! Navbar
    // let query = useLoaderData()
    // <UserProvider query={fragmentRefs}>
    let gviewer = viewer->Option.map(v => v.fragmentRefs)
    <GlobalQuery.Provider value={gviewer}>
      <StackedLayout
        navbar={<Navbar>
          <NavbarItem href="/" className="max-lg:hidden">
            <WaitForMessages>
              {() => <Navbar.NavbarLabel> {t`Racquet League`} </Navbar.NavbarLabel>}
            </WaitForMessages>
          </NavbarItem>
          <NavbarDivider className="max-lg:hidden" />
          <WaitForMessages>
            {() =>
              <NavbarSection className="max-lg:hidden">
                <Dropdown>
                  <DropdownButton \"as"={Navbar.NavbarItem.make} className="max-lg:hidden">
                    <WaitForMessages>
                      {() => <Navbar.NavbarLabel> {t`Events`} </Navbar.NavbarLabel>}
                    </WaitForMessages>
                    <HeroIcons.ChevronDownIcon />
                  </DropdownButton>
                  <ActivityDropdownMenu />
                </Dropdown>
                <Dropdown>
                  <DropdownButton \"as"={Navbar.NavbarItem.make} className="max-lg:hidden">
                    <WaitForMessages>
                      {() => <Navbar.NavbarLabel> {t`Rankings`} </Navbar.NavbarLabel>}
                    </WaitForMessages>
                    <HeroIcons.ChevronDownIcon />
                  </DropdownButton>
                  <ActivityLeagueDropdownMenu />
                </Dropdown>
              </NavbarSection>}
          </WaitForMessages>
          <NavbarSpacer />
          <NavbarSection className="max-lg:hidden">
            <LangSwitch />
          </NavbarSection>
          <NavbarSpacer />
          <NavbarSection>
            // <NavbarItem href="/search" \"aria-label"="Search">
            //   {""->React.string}
            //   // <MagnifyingGlassIcon />
            // </NavbarItem>
            // <NavbarItem href="/inbox" \"aria-label"="Inbox">
            //   // <InboxIcon />
            //   {""->React.string}
            // </NavbarItem>
            {viewer
            ->Option.flatMap(v =>
              v.user->Option.map(user =>
                <Dropdown>
                  <DropdownButton \"as"={NavbarItem.make}>
                    {user.lineUsername->Option.getOr("")->React.string}
                    <Avatar src=?user.picture square=true />
                  </DropdownButton>
                  <DropdownMenu className="min-w-64" anchor="bottom end">
                    <DropdownItem href="/events">
                      // <HeroIcons.UserIcon />
                      <DropdownLabel> {t`My Events`} </DropdownLabel>
                    </DropdownItem>
                    // <DropdownItem href="/settings">
                    //   <HeroIcons.Cog6Tooth />
                    //   <DropdownLabel> {t`Settings`} </DropdownLabel>
                    // </DropdownItem>
                    <DropdownDivider />
                    // <DropdownItem href="/privacy-policy">
                    //   // <ShieldCheckIcon />
                    //   <DropdownLabel> {t`Privacy Policy`} </DropdownLabel>
                    // </DropdownItem>
                    // <DropdownItem href="/share-feedback">
                    //   // <LightBulbIcon />
                    //   <DropdownLabel> {t`Share Feedback`} </DropdownLabel>
                    // </DropdownItem>
                    // <DropdownDivider />
                    <DropdownItem>
                      // <ArrowRightStartOnRectangleIcon />
                      <DropdownLabel>
                        <LogoutLink />
                      </DropdownLabel>
                    </DropdownItem>
                  </DropdownMenu>
                </Dropdown>
              )
            )
            ->Option.getOr(<LoginLink />)}
          </NavbarSection>
        </Navbar>}
        sidebar={<Sidebar>
          <SidebarHeader>
            <SidebarItem href="/">
              <WaitForMessages>
                {() => <SidebarLabel> {t`Racquet League`} </SidebarLabel>}
              </WaitForMessages>
            </SidebarItem>
          </SidebarHeader>
          <SidebarBody>
            <SidebarSection>
              <Dropdown>
                <DropdownButton \"as"={SidebarItem.make} className="lg:mb-2.5">
                  <WaitForMessages>
                    {() => <SidebarLabel> {t`Events`} </SidebarLabel>}
                  </WaitForMessages>
                  <HeroIcons.ChevronDownIcon />
                </DropdownButton>
                <ActivityDropdownMenu />
              </Dropdown>
              <Dropdown>
                <DropdownButton \"as"={SidebarItem.make} className="lg:mb-2.5">
                  <WaitForMessages>
                    {() => <SidebarLabel> {t`Rankings`} </SidebarLabel>}
                  </WaitForMessages>
                  <HeroIcons.ChevronDownIcon />
                </DropdownButton>
                <ActivityLeagueDropdownMenu />
              </Dropdown>
              <div className="ml-2 mt-2">
                <LangSwitch />
              </div>
            </SidebarSection>
          </SidebarBody>
        </Sidebar>}>
        {children}
      </StackedLayout>
    </GlobalQuery.Provider>
    // </UserProvider>
  }
}

// module RouteParams = {
//   type t = {lang: option<string>}
//
//   let parse = (json: Js.Json.t): result<t, string> => {
//     open JsonCombinators.Json.Decode
//
//     let decoder = object(field => {
//       lang: field.optional("lang", string),
//     })
//     try {
//       json->JsonCombinators.Json.decode(decoder)
//     } catch {
//     | _ => Error("An unexpected error occurred when checking the id.")
//     }
//   }
// }

@genType @react.component
let make = () => {
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()

  // open Router
  // let paramsJs = useParams()

  // let lang = paramsJs->RouteParams.parse->Belt.Result.mapWithDefault(None, ({lang}) => lang)
  let {viewer, _} = Query.usePreloaded(~queryRef=query.data)

  // <Router.Await2 resolve=query.i18nLoaders errorElement={"Error"->React.string}>
  <Layout viewer={viewer}>
    <Router.Outlet />
  </Layout>
  // </Router.Await2>
}

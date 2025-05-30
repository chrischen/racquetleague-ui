%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
%%raw("import '../../global/static.css'")

module Query = %relay(`
  query DefaultLayout2Query {
    viewer { 
      ... GlobalQueryProvider_viewer
      ...NavViewer_viewer
      user {
        lineUsername
        picture
      }
    }
  }
`)

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<DefaultLayout2Query_graphql.queryRef> =
  "useLoaderData"

// module MenuInstance = {
//   @module("../ui/navigation-menu") @react.component
//   external make: unit => React.element = "MenuInstance"
// }

type navItem = {label: string, url: string}
let ts = Lingui.UtilString.t
let navItems = [
  // {label: "Home", url: "/"},
  {label: ts`Events`, url: "/"},
  {label: ts`Rankings`, url: "/league/badminton"},
]
module Layout = {
  @react.component
  let make = (~children: React.element, ~viewer: option<Query.Types.response_viewer>) => {
    open Lingui.Util

    open LangProvider.Router
    open Dropdown
    open Sidebar
    open! Navbar
    // let query = useLoaderData()
    // <UserProvider query={fragmentRefs}>
    let gviewer = viewer->Option.map(v => v.fragmentRefs)
    <GlobalQuery.Provider value={gviewer}>
      <StackedLayout
        navbar={<Navbar>
          <Dropdown>
            <DropdownButton \"as"={Navbar.NavbarItem.make} className="max-lg:hidden">
              // <Avatar src="/tailwind-logo.svg" />
              <Navbar.NavbarLabel> {"Racquet League"->React.string} </Navbar.NavbarLabel>
              <HeroIcons.ChevronDownIcon />
            </DropdownButton>
            // <TeamDropdownMenu />
          </Dropdown>
          <NavbarDivider className="max-lg:hidden" />
          <NavbarSection className="max-lg:hidden">
            {navItems
            ->Array.map(({label, url}) =>
              <NavbarItem key={label}>
                <NavLink to={url}> {label->React.string} </NavLink>
              </NavbarItem>
            )
            ->React.array}
          </NavbarSection>
          <NavbarSpacer />
          <NavbarSection className="max-lg:hidden">
            <LangSwitch />
          </NavbarSection>
          <NavbarSpacer />
          <NavbarSection>
            <NavbarItem href="/search" \"aria-label"="Search">
              {""->React.string}
              // <MagnifyingGlassIcon />
            </NavbarItem>
            <NavbarItem href="/inbox" \"aria-label"="Inbox">
              // <InboxIcon />
              {""->React.string}
            </NavbarItem>
            {viewer
            ->Option.flatMap(v =>
              v.user->Option.map(user =>
                <Dropdown>
                  <DropdownButton \"as"={NavbarItem.make}>
                    {user.lineUsername->Option.getOr("")->React.string}
                    <Avatar src=?user.picture square=true />
                  </DropdownButton>
                  <DropdownMenu className="min-w-64" anchor="bottom end">
                    // <DropdownItem href="/my-profile">
                    //   // <HeroIcons.UserIcon />
                    //   <DropdownLabel> {t`My Profile`} </DropdownLabel>
                    // </DropdownItem>
                    // <DropdownItem href="/settings">
                    //   <HeroIcons.Cog6Tooth />
                    //   <DropdownLabel> {t`Settings`} </DropdownLabel>
                    // </DropdownItem>
                    // <DropdownDivider />
                    // <DropdownItem href="/privacy-policy">
                    //   // <ShieldCheckIcon />
                    //   <DropdownLabel> {t`Privacy Policy`} </DropdownLabel>
                    // </DropdownItem>
                    // <DropdownItem href="/share-feedback">
                    //   // <LightBulbIcon />
                    //   <DropdownLabel> {t`Share Feedback`} </DropdownLabel>
                    // </DropdownItem>
                    // <DropdownDivider />
                    <DropdownItem href="/logout">
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
            <Dropdown>
              <DropdownButton \"as"={SidebarItem.make} className="lg:mb-2.5">
                // <Avatar src="/tailwind-logo.svg" />
                <SidebarLabel> {t`Racquet League`} </SidebarLabel>
                <HeroIcons.ChevronDownIcon />
              </DropdownButton>
              // <TeamDropdownMenu />
            </Dropdown>
          </SidebarHeader>
          <SidebarBody>
            <SidebarSection>
              {navItems
              ->Array.map(({label, url}) =>
                <SidebarItem key={label}>
                  <NavLink to={url}> {label->React.string} </NavLink>
                </SidebarItem>
              )
              ->React.array}
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
  let {viewer} = Query.usePreloaded(~queryRef=query.data)

  // <Router.Await2 resolve=query.i18nLoaders errorElement={"Error"->React.string}>
  <Layout viewer={viewer}>
    <Router.Outlet />
  </Layout>
  // </Router.Await2>
}

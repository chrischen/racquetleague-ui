%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
open LangProvider.Router

module Fragment = %relay(`
  fragment LeagueNav_query on Query {
    viewer {
      user {
        id
        lineUsername
        picture
      }
      ... LeagueNav_viewer
    }

  }
`)

module ViewerFragment = %relay(`
  fragment LeagueNav_viewer on Viewer {
    user {
      id
      lineUsername
      picture
    }
  }
`)

module Viewer = {
  @genType @react.component
  let make = (~viewer) => {
    // Uses the Query fragment directly
    let viewer = ViewerFragment.use(viewer)

    {
      viewer.user
      ->Option.flatMap(user =>
        user.lineUsername->Option.map(lineUsername => <>
          <span> {React.string(lineUsername)} </span>
          {React.string(" ")}
          <LogoutLink />
        </>)
      )
      ->Option.getOr(<LoginLink />)
    }
  }
}
module MenuInstance = {
  @module("../ui/navigation-menu") @react.component
  external make: unit => React.element = "MenuInstance"
}

type navItem = {name: string, href: string, current: bool}

type userNav = {name: string, href: string}
@genType @react.component
let make = (~query) => {
  open HeadlessUi
  open HeroIcons
  let ts = Lingui.UtilString.t
  let query = Fragment.use(query)

  let _loginEls = {
    query.viewer
    ->Option.map(viewer =>
      <React.Suspense fallback={React.string("...")}>
        <Viewer viewer={viewer.fragmentRefs} />
      </React.Suspense>
    )
    ->Option.getOr(<LoginLink />)
  }

  let {pathname} = Router.useLocation()
  let navigation = [
    {
      name: ts`Rankings`,
      href: "/league",
      current: pathname == "/league" || pathname == "/" ? true : false,
    },
    {
      name: ts`Find Games`,
      href: "/league/games",
      current: pathname->String.indexOf("/games") > -1 ? true : false,
    },
    {
      name: ts`About`,
      href: "/league/about",
      current: pathname->String.indexOf("/about") > -1 ? true : false,
    },
  ]
  let userNavigation =
    query.viewer
    ->Option.flatMap(viewer =>
      viewer.user->Option.map(user => [
        {name: ts`Your Profile`, href: "/p/" ++ user.id},
        // {name: ts`Settings`, href: "#"},
        {name: ts`Logout`, href: "/logout"},
      ])
    )
    ->Option.getOr([])
  <WaitForMessages>
    {() =>
      <header>
        <nav>
          <div className="min-h-full">
            <Disclosure \"as"="nav" className="border-b border-gray-200 bg-white">
              {({\"open": open_}) =>
                <Layout.Container className="">
                  // <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                  <div className="flex h-16 justify-between">
                    // Large screen nav
                    <div className="flex">
                      <div
                        className="flex flex-shrink-0 items-center sm:hidden inline-flex items-center px-1 pt-1 text-sm font-medium">
                        //   <img
                        //     className="block h-8 w-auto lg:hidden"
                        //     src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600"
                        //     alt="Your Company"
                        //   />
                        //   <img
                        //     className="hidden h-8 w-auto lg:block"
                        //     src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600"
                        //     alt="Your Company"
                        //   />
                        <LangSwitch />
                      </div>
                      <div className="hidden sm:-my-px sm:ml-6 sm:flex sm:space-x-8">
                        {navigation
                        ->Array.map((item: navItem) =>
                          <a
                            key={item.name}
                            href={item.href}
                            className={Util.cx([
                              item.current
                                ? "border-leaguePrimary text-gray-900"
                                : "border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700",
                              "inline-flex items-center border-b-2 px-1 pt-1 text-sm font-medium",
                            ])}
                            ariaCurrent={item.current ? #page : #"false"}>
                            {item.name->React.string}
                          </a>
                        )
                        ->React.array}
                        // <div className="inline-flex items-center px-1 pt-0 text-sm font-medium">
                        // <LangSwitch />
                        // </div>
                      </div>
                    </div>
                    <div className="hidden sm:ml-6 sm:flex sm:items-center">
                      <LangSwitch />
                      <button
                        type_="button"
                        className="relative rounded-full bg-white ml-3 p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2">
                        <span className="absolute -inset-1.5" />
                        <span className="sr-only"> {t`View notifications`} </span>
                        <BellIcon className="h-6 w-6" \"aria-hidden"="true" />
                      </button>
                      <Menu \"as"="div" className="relative ml-3">
                        {query.viewer
                        ->Option.flatMap(viewer =>
                          viewer.user->Option.map(user =>
                            <div>
                              <MenuButton
                                className="relative flex max-w-xs items-center rounded-full bg-white text-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2">
                                <span className="absolute -inset-1.5" />
                                <span className="sr-only"> {t`Open user menu`} </span>
                                {user.picture
                                ->Option.map(
                                  picture =>
                                    <img
                                      className="h-8 w-8 rounded-full"
                                      src=picture
                                      alt={ts`Profile picture`}
                                    />,
                                )
                                ->Option.getOr(React.null)}
                              </MenuButton>
                            </div>
                          )
                        )
                        ->Option.getOr(<LoginLink />)}
                        <Transition
                          enter="transition ease-out duration-200"
                          enterFrom="transform opacity-0 scale-95"
                          enterTo="transform opacity-100 scale-100"
                          leave="transition ease-in duration-75"
                          leaveFrom="transform opacity-100 scale-100"
                          leaveTo="transform opacity-0 scale-95">
                          <MenuItems
                            className="absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none">
                            {userNavigation->Array.map(item =>
                              <MenuItem key={item.name}>
                                {({focus}) =>
                                  <a
                                    href={item.href}
                                    className={Util.cx([
                                      focus ? "bg-gray-100" : "",
                                      "block px-4 py-2 text-sm text-gray-700",
                                    ])}>
                                    {item.name->React.string}
                                  </a>}
                              </MenuItem>
                            )}
                          </MenuItems>
                        </Transition>
                      </Menu>
                    </div>
                    <div className="-mr-2 flex items-center sm:hidden">
                      <DisclosureButton
                        className="relative inline-flex items-center justify-center rounded-md bg-white p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2">
                        <span className="absolute -inset-0.5" />
                        <span className="sr-only"> {t`Open main menu`} </span>
                        {open_
                          ? <XMarkIcon className="block h-6 w-6" \"aria-hidden"="true" />
                          : <Bars3Icon className="block h-6 w-6" \"aria-hidden"="true" />}
                      </DisclosureButton>
                    </div>
                  </div>
                  // </div>
                  // Large screen nav
                  <DisclosurePanel className="sm:hidden">
                    <div className="space-y-1 pb-3 pt-2">
                      {navigation
                      ->Array.map(item =>
                        <DisclosureButton
                          key={item.name}
                          \"as"="a"
                          href={item.href}
                          className={Util.cx([
                            item.current
                              ? "border-red-500 bg-red-50 text-red-700"
                              : "border-transparent text-gray-600 hover:border-gray-300 hover:bg-gray-50 hover:text-gray-800",
                            "block border-l-4 py-2 pl-3 pr-4 text-base font-medium",
                          ])}
                          ariaCurrent={item.current ? #page : #"false"}>
                          {item.name}
                        </DisclosureButton>
                      )
                      ->React.array}
                    </div>
                    <div className="border-t border-gray-200 pb-3 pt-4">
                      {query.viewer
                      ->Option.flatMap(viewer =>
                        viewer.user->Option.map(user =>
                          <div className="flex items-center px-4">
                            <div className="flex-shrink-0">
                              {user.picture
                              ->Option.map(
                                picture =>
                                  <img
                                    className="h-10 w-10 rounded-full"
                                    src=picture
                                    alt={ts`Profile picture`}
                                  />,
                              )
                              ->Option.getOr(React.null)}
                            </div>
                            <div className="ml-3">
                              <div className="text-base font-medium text-gray-800">
                                {user.lineUsername->Option.getOr("")->React.string}
                              </div>
                              <div className="text-sm font-medium text-gray-500">
                                {""->React.string}
                              </div>
                            </div>
                            <button
                              type_="button"
                              className="relative ml-auto flex-shrink-0 rounded-full bg-white p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2">
                              <span className="absolute -inset-1.5" />
                              <span className="sr-only"> {t`View notifications`} </span>
                              <BellIcon className="h-6 w-6" \"aria-hidden"="true" />
                            </button>
                          </div>
                        )
                      )
                      ->Option.getOr(React.null)}
                      <div className="mt-3 space-y-1">
                        {query.viewer
                        ->Option.flatMap(viewer =>
                          viewer.user->Option.map(user => {
                            userNavigation
                            ->Array.map(
                              item =>
                                <DisclosureButton
                                  key={item.name}
                                  \"as"="a"
                                  href={item.href}
                                  className="block px-4 py-2 text-base font-medium text-gray-500 hover:bg-gray-100 hover:text-gray-800">
                                  {item.name}
                                </DisclosureButton>,
                            )
                            ->React.array
                          })
                        )
                        ->Option.getOr(<LoginLink />)}
                      </div>
                    </div>
                  </DisclosurePanel>
                </Layout.Container>}
            </Disclosure>
          </div>
        </nav>
      </header>}
  </WaitForMessages>
}

@genType
let default = make

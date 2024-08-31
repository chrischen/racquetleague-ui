%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
open LangProvider.Router

module EventQuery = %relay(`
  query EventQuery($eventId: ID!, $after: String, $first: Int, $before: String) {
    event(id: $eventId) {
      __id
      id
      title
      details
      activity {
        name
        slug
        ...SubscribeActivity_activity
      }
      viewerIsAdmin
      viewerHasRsvp
      startDate
      endDate
      shadow
      location {
        id
        name
        details
        ...MediaList_location
        ...EventLocation_location
      }
      club {
        name
        slug
      }
      ...EventRsvps_event @arguments(after: $after, first: $first, before: $before)
    }
  }
`)

// module EventJoinMutation = %relay(`
//  mutation EventJoinMutation(
//     $connections: [ID!]!
//     $id: ID!
//   ) {
//     joinEvent(eventId: $id) {
//       edge @appendEdge(connections: $connections) {
//         node {
//           id
//           user {
//             id
//             lineUsername
//           }
//         }
//       }
//     }
//   }
// `)
// module EventLeaveMutation = %relay(`
//  mutation EventLeaveMutation(
//     $connections: [ID!]!
//     $id: ID!
//   ) {
//     leaveEvent(eventId: $id) {
//       eventIds @deleteEdge(connections: $connections)
//       errors {
//         message
//       }
//     }
//   }
// `)

// module Fragment = %relay(`
//   fragment Event_event on Event {
//     title
//     ... EventRsvps_event
//   }
// `)

type loaderData = EventQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"
@genType @react.component
let make = () => {
  let td = Lingui.UtilString.dynamic
  let ts = Lingui.UtilString.t
  let query = useLoaderData()
  let {event} = EventQuery.usePreloaded(~queryRef=query.data)
  let viewer = GlobalQuery.useViewer()
  let navigate = Router.useNavigate()

  event
  ->Option.map(event => {
    let {__id, title, activity, details, location, shadow, fragmentRefs} = event
    // Permissions
    let viewerIsAdmin = event.viewerIsAdmin->Option.getOr(false)
    let viewerHasRsvp = event.viewerHasRsvp->Option.getOr(false)
    let canOpenAiTetsu = switch (viewerHasRsvp, viewerIsAdmin) {
    | (false, false) => false
    | _ => true
    }

    // let startDate =
    //   event.startDate->Option.getOr(
    //     "1900-05-05T00:00"->DateFns.formatWithPattern("yyyy-MM-dd'T'HH:00"),
    //   )
    //
    let until = event.startDate->Option.map(startDate =>
      startDate
      ->Util.Datetime.toDate
      ->DateFns.differenceInMinutes(Js.Date.make())
    )
    let duration = event.startDate->Option.flatMap(startDate =>
      event.endDate->Option.map(
        endDate =>
          endDate
          ->Util.Datetime.toDate
          ->DateFns.differenceInMinutes(startDate->Util.Datetime.toDate),
      )
    )
    let duration = duration->Option.map(duration => {
      let hours = Js.Math.floor_float(duration /. 60.)
      let minutes = mod(duration->Float.toInt, 60)
      if minutes == 0 {
        ts`${hours->Float.toString} hours`
      } else {
        ts`${hours->Float.toString} hours and ${minutes->Int.toString} minutes`
      }
    })

    let activityName =
      activity->Option.flatMap(activity => activity.name->Option.map(td))->Option.getOr("---")

    let pageTitle = {
      activity
      ->Option.flatMap(a => a.name->Option.map(name => td(name)))
      ->Option.getOr("") ++
      " / " ++
      title->Option.getOr("") ++
      duration
      ->Option.map(duration => " / " ++ duration)
      ->Option.getOr("") ++
      " @ " ++
      location
      ->Option.flatMap(location => location.name)
      ->Option.getOr("?")
    }

    <WaitForMessages>
      {() =>
        <main>
          <Util.Helmet>
            <title> {pageTitle->React.string} </title>
            <meta property="og:title" content=pageTitle />
            // <meta property="og:description" content="LINE is a new communication app" />
          </Util.Helmet>
          <header className="relative isolate pt-4">
            <div className="absolute inset-0 -z-10 overflow-hidden" ariaHidden=true>
              <div
                className="absolute left-16 top-full -mt-16 transform-gpu opacity-50 blur-3xl xl:left-1/2 xl:-ml-80">
                // <div
                //   className="aspect-[1154/678] w-[72.125rem] bg-gradient-to-br from-[#FF80B5] to-[#9089FC]"
                //   style={{
                //     clipPath:
                //       'polygon(100% 38.5%, 82.6% 100%, 60.2% 37.7%, 52.4% 32.1%, 47.5% 41.8%, 45.2% 65.6%, 27.5% 23.4%, 0.1% 35.3%, 17.9% 0%, 27.7% 23.4%, 76.2% 2.5%, 74.2% 56%, 100% 38.5%)',
                //   }}
                // />
              </div>
              <div className="absolute inset-x-0 bottom-0 h-px bg-gray-900/5" />
            </div>
            // <div className="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
            <Layout.Container className="py-0">
              <div
                className="mx-auto flex max-w-2xl items-center justify-between gap-x-8 lg:mx-0 lg:max-w-none">
                <div className="flex items-center gap-x-6">
                  // <img
                  //   src="https://tailwindui.com/img/logos/48x48/tuple.svg"
                  //   alt=""
                  //   className="h-16 w-16 flex-none rounded-full ring-1 ring-gray-900/10"
                  // />
                  <h1>
                    <div className="text-base leading-6 text-gray-500">
                      {t`event @`}
                      {" "->React.string}
                      <span className="text-gray-700">
                        {location
                        ->Option.flatMap(location =>
                          location.name->Option.map(
                            name =>
                              <Link to={"/locations/" ++ location.id}> {name->React.string} </Link>,
                          )
                        )
                        ->Option.getOr(React.null)}
                      </span>
                    </div>
                    <div className="mt-1 text-2xl font-semibold leading-6 text-gray-900">
                      // <PageTitle>
                      {activity
                      ->Option.flatMap(a => a.name->Option.map(name => td(name)->React.string))
                      ->Option.getOr(React.null)}
                      {" / "->React.string}
                      {title->Option.map(React.string)->Option.getOr(React.null)}
                      {duration
                      ->Option.map(duration => <>
                        {" / "->React.string}
                        {duration->React.string}
                      </>)
                      ->Option.getOr(React.null)}

                      // </PageTitle>
                    </div>
                    {event.club
                    ->Option.flatMap(club => {
                      club.name->Option.map(
                        name =>
                          <div className="mt-2 text-base leading-6 text-gray-500">
                            <span className="text-gray-700">
                              <Link to={"/clubs/" ++ club.slug->Option.getOr("")}>
                                {t`hosted by ${name}`}
                              </Link>
                            </span>
                          </div>,
                      )
                    })
                    ->Option.getOr(React.null)}
                  </h1>
                </div>
                <div className="flex items-center gap-x-4 sm:gap-x-6">
                  // <button
                  //   type_="button"
                  //   className="hidden text-sm font-semibold leading-6 text-gray-900 sm:block">
                  //   {"Copy URL"->React.string}
                  // </button>
                  // <a
                  //   href="#"
                  //   className="hidden text-sm font-semibold leading-6 text-gray-900 sm:block">
                  //   {"Edit"->React.string}
                  // </a>
                  // <a
                  //   href="#"
                  //   className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
                  //   {"Send"->React.string}
                  // </a>
                  // <Menu as="div" className="relative sm:hidden">
                  //   <Menu.Button className="-m-3 block p-3">
                  //     <span className="sr-only">More</span>
                  //     <EllipsisVerticalIcon className="h-5 w-5 text-gray-500" aria-hidden="true" />
                  //   </Menu.Button>
                  //
                  //   <Transition
                  //     as={Fragment}
                  //     enter="transition ease-out duration-100"
                  //     enterFrom="transform opacity-0 scale-95"
                  //     enterTo="transform opacity-100 scale-100"
                  //     leave="transition ease-in duration-75"
                  //     leaveFrom="transform opacity-100 scale-100"
                  //     leaveTo="transform opacity-0 scale-95"
                  //   >
                  //     <Menu.Items className="absolute right-0 z-10 mt-0.5 w-32 origin-top-right rounded-md bg-white py-2 shadow-lg ring-1 ring-gray-900/5 focus:outline-none">
                  //       <Menu.Item>
                  //         {({ active }) => (
                  //           <button
                  //             type_="button"
                  //             className={classNames(
                  //               active ? 'bg-gray-50' : '',
                  //               'block w-full px-3 py-1 text-left text-sm leading-6 text-gray-900'
                  //             )}
                  //           >
                  //             Copy URL
                  //           </button>
                  //         )}
                  //       </Menu.Item>
                  //       <Menu.Item>
                  //         {({ active }) => (
                  //           <a
                  //             href="#"
                  //             className={classNames(
                  //               active ? 'bg-gray-50' : '',
                  //               'block px-3 py-1 text-sm leading-6 text-gray-900'
                  //             )}
                  //           >
                  //             Edit
                  //           </a>
                  //         )}
                  //       </Menu.Item>
                  //     </Menu.Items>
                  //   </Transition>
                  // </Menu>
                </div>
              </div>
            </Layout.Container>
          </header>
          {switch viewerIsAdmin {
          | true =>
            <Layout.Container className="py-4">
              <div
                className="mx-auto grid max-w-2xl grid-cols-1 grid-rows-1 items-start gap-x-8 gap-y-4 lg:mx-0 lg:max-w-none lg:grid-cols-3">
                <div
                  className="-mx-4 px-6 py-4 shadow-sm ring-1 ring-gray-900/5 sm:mx-0 sm:rounded-lg sm:px-8 sm:pb-4 col-span-3 lg:row-span-2 lg:row-end-2">
                  <Link
                    to={"/events/update/" ++
                    event.id ++
                    "/" ++
                    event.location->Option.map(l => l.id)->Option.getOr("")}>
                    {t`edit event`}
                  </Link>
                </div>
              </div>
            </Layout.Container>
          | _ => React.null
          }}
          <Layout.Container className="py-4">
            <div
              className="mx-auto grid max-w-2xl grid-cols-1 grid-rows-1 items-start gap-x-8 gap-y-4 lg:mx-0 lg:max-w-none lg:grid-cols-3">
              <div
                className="-mx-4 px-6 py-4 shadow-sm ring-1 ring-gray-900/5 sm:mx-0 sm:rounded-lg sm:px-8 sm:pb-4 col-span-3 lg:row-span-2 lg:row-end-2">
                {viewer.user
                ->Option.flatMap(_ =>
                  activity->Option.map(
                    activity => <SubscribeActivity activity=activity.fragmentRefs />,
                  )
                )
                ->Option.getOr(t`login to subscribe to ${activityName} events`)}
              </div>
            </div>
          </Layout.Container>
          <Layout.Container>
            // <div className="mx-auto max-w-7xl px-4 py-16 sm:px-6 lg:px-8">
            <div
              className="mx-auto grid max-w-2xl grid-cols-1 grid-rows-1 items-start gap-x-8 gap-y-4 lg:mx-0 lg:max-w-none lg:grid-cols-3">
              <div className="lg:col-start-3 lg:row-end-1">
                <div
                  className="grid grid-cols-1 grid-rows-1 items-start gap-x-8 gap-y-4 lg:mx-0 lg:max-w-none">
                  {switch shadow {
                  | None
                  | Some(false) =>
                    <EventRsvps event=fragmentRefs />
                  | Some(true) =>
                    <ErrorAlert
                      cta={t`view events`} ctaClick={_ => navigate("/clubs/japanpickle", None)}>
                      {t`this is a private event that requires membership with the club. To join this club, please join a Japan Pickleball League event first.`}
                    </ErrorAlert>
                  }}
                  {event.activity
                  ->Option.flatMap(activity =>
                    activity.slug->Option.map(
                      slug =>
                        switch (canOpenAiTetsu, slug) {
                        | (true, "pickleball" as slug)
                        | (true, "badminton" as slug) =>
                          <div
                            className="-mx-4 px-6 py-4 shadow-sm ring-1 ring-gray-900/5 sm:mx-0 sm:rounded-lg sm:px-6 sm:pb-4">
                            <h2 className="text-base font-semibold leading-6 text-gray-900">
                              {t`league`}
                            </h2>
                            <Link to={"/league/events/" ++ event.id ++ "/" ++ slug}>
                              {t`submit matches`}
                            </Link>
                          </div>
                        | _ => React.null
                        },
                    )
                  )
                  ->Option.getOr(React.null)}
                </div>
              </div>
              <div className="lg:col-span-2 lg:row-span-2 lg:row-end-2">
                <div
                  className="grid grid-cols-1 grid-rows-1 items-start gap-x-8 gap-y-4 lg:mx-0 lg:max-w-none">
                  <div
                    className="-mx-4 px-6 py-4 shadow-sm ring-1 ring-gray-900/5 sm:mx-0 sm:rounded-lg sm:px-8 sm:py-6 xl:px-12 xl:py-8">
                    <h2 className="text-base font-semibold leading-6 text-gray-900">
                      {t`details`}
                    </h2>
                    <div
                      className="font-bold flex items-center mt-4 lg:text-xl leading-8 text-gray-700">
                      <Lucide.CalendarClock
                        className="mr-2 h-7 w-7 flex-shrink-0 text-gray-500" \"aria-hidden"="true"
                      />
                      {event.startDate
                      ->Option.flatMap(startDate =>
                        event.endDate->Option.map(
                          endDate => <>
                            <ReactIntl.FormattedDate value={startDate->Util.Datetime.toDate} />
                            {" "->React.string}
                            <ReactIntl.FormattedTime value={startDate->Util.Datetime.toDate} />
                            {" -> "->React.string}
                            <ReactIntl.FormattedTime value={endDate->Util.Datetime.toDate} />
                            {" "->React.string}
                            {until
                            ->Option.map(
                              until =>
                                <ReactIntl.FormattedRelativeTime
                                  value={until} unit=#minute updateIntervalInSeconds=1.
                                />,
                            )
                            ->Option.getOr(React.null)}
                          </>,
                        )
                      )
                      ->Option.getOr("???"->React.string)}
                    </div>
                    <div className="ml-3 border-gray-200 border-l-4 pl-5 mt-4">
                      <AddToCalendar />
                    </div>
                    {location
                    ->Option.map(location => <EventLocation location=location.fragmentRefs />)
                    ->Option.getOr(React.null)}
                    {details
                    ->Option.map(details => <>
                      <div
                        className="font-bold flex items-center mt-4 lg:text-xl leading-8 text-gray-700">
                        <Lucide.Info
                          className="mr-2 h-7 w-7 flex-shrink-0 text-gray-500" \"aria-hidden"="true"
                        />
                        {t`notes`}
                      </div>
                      <div className="ml-3 border-gray-200 border-l-4 pl-5 mt-4">
                        <p className="lg:text-xl leading-8 text-gray-700 whitespace-pre text-wrap">
                          {switch details {
                          | "" => ts`good luck, have fun`
                          | d => d
                          }->React.string}
                        </p>
                      </div>
                    </>)
                    ->Option.getOr(React.null)}
                  </div>
                  {event.location
                  ->Option.map(location =>
                    <div
                      className="-mx-4 px-6 py-4 shadow-sm ring-1 ring-gray-900/5 sm:mx-0 sm:rounded-lg sm:px-8 sm:py-6 xl:px-12 xl:py-8">
                      <h2 className="text-base font-semibold leading-6 text-gray-900">
                        {t`media`}
                      </h2>
                      <MediaList media=location.fragmentRefs />
                    </div>
                  )
                  ->Option.getOr(React.null)}
                </div>
              </div>
            </div>
            // </div>
          </Layout.Container>
        </main>}
      // <div className="md:col-span-3">
      //   <div
      //     className="-mx-4 px-4 py-8 shadow-sm ring-1 ring-gray-900/5 sm:mx-0 sm:rounded-lg sm:px-8 sm:pb-14 lg:col-span-2 lg:row-span-2 lg:row-end-2 xl:px-16 xl:pb-20 xl:pt-16"
      //   />
      // </div>
    </WaitForMessages>
  })
  ->Option.getOr(<div> {t`event doesn't exist`} </div>)
}

@genType
let default = make

@genType
let \"Component" = make

type params = {
  ...EventQuery_graphql.Types.variables,
  lang: option<string>,
}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = lang => {
  let messages = switch lang {
  | "ja" => Lingui.import("../../locales/src/components/pages/Event.re/ja")
  | _ => Lingui.import("../../locales/src/components/pages/Event.re/en")
  }->Promise.thenResolve(messages =>
    Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  )
  [messages]
  // ->Array.concat(EventRsvps.loadMessages(lang))
  // ->Array.concat(ViewerRsvpStatus.loadMessages(lang))
}

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make

  // let lang = params.lang->Option.getOr("en")

  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore

  Router.defer({
    WaitForMessages.data: EventQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={eventId: params.eventId, ?after, ?before, first: 20},
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

// @genType
// let \"HydrateFallbackElement" = <div> {React.string("Loading fallback...")} </div>
// %raw("loader.hydrate = true")

// @NOTE Force lingui to include the potential dynamic values here
let __unused = () => {
  let td = Lingui.UtilString.td

  @live (td({id: "Badminton"})->ignore)

  @live (td({id: "Table Tennis"})->ignore)

  @live (td({id: "Pickleball"})->ignore)

  @live (td({id: "Futsal"})->ignore)
}

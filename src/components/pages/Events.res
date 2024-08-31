%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module EventsQuery = %relay(`
  query EventsQuery($after: String, $first: Int, $before: String, $afterDate: Datetime, $filters: EventFilters) {
    ... EventsListFragment @arguments(after: $after, first: $first, before: $before, afterDate: $afterDate, filters: $filters)
    ... CalendarEventsFragment @arguments(after: $after, first: $first, before: $before, afterDate: $afterDate, filters: $filters)
  }
`)
/* module Fragment = %relay(`
  fragment Events_event on Event {
    ... Event_event
  }
`)*/
/* module Query = %relay(`
  query EventQuery {
    event(id: "1") {
      title
			... EventRsvps_event
		}
  }
`)*/
type loaderData = EventsQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Router
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  let {fragmentRefs} = EventsQuery.usePreloaded(~queryRef=query.data)
  let (searchParams, _) = Router.useSearchParamsFunc()
  let activityFilter = searchParams->Router.SearchParams.get("activity")
  let viewer = GlobalQuery.useViewer()

  <WaitForMessages>
    {() => {
      <>
        <React.Suspense fallback={<Layout.Container> {t`loading events...`} </Layout.Container>}>
          <EventsList
            events=fragmentRefs
            header={<Layout.Container>
              <Grid>
                <PageTitle>
                  {t`all events`}
                  {viewer.user
                  ->Option.flatMap(user =>
                    [
                      "Hasby Riduan",
                      "hasbyriduan9",
                      "notchrischen",
                      "Matthew",
                      "David Vo",
                      "Kai",
                      "Alex Ng",
                    ]->Array.indexOfOpt(user.lineUsername->Option.getOr(""))
                  )
                  ->Option.map(_ => <>
                    {" "->React.string}
                    <Link to="/events/create"> {"+"->React.string} </Link>
                  </>)
                  ->Option.getOr(React.null)}
                </PageTitle>
                <div>
                  <Link to={"/"}> {t`all`} </Link>
                  {" "->React.string}
                  <svg viewBox="0 0 2 2" className="h-1.5 w-1.5 inline flex-none fill-gray-600">
                    <circle cx={1->Int.toString} cy={1->Int.toString} r={1->Int.toString} />
                  </svg>
                  {" "->React.string}
                  <LinkWithOpts
                    to={
                      pathname: "",
                      search: Router.createSearchParams({
                        "activity": "pickleball",
                      })->Router.SearchParams.toString,
                    }>
                    {t`pickleball`}
                  </LinkWithOpts>
                  {" "->React.string}
                  <svg viewBox="0 0 2 2" className="h-1.5 w-1.5 inline flex-none fill-gray-600">
                    <circle cx={1->Int.toString} cy={1->Int.toString} r={1->Int.toString} />
                  </svg>
                  {" "->React.string}
                  <LinkWithOpts
                    to={
                      pathname: "",
                      search: Router.createSearchParams({
                        "activity": "badminton",
                      })->Router.SearchParams.toString,
                    }>
                    {t`badminton`}
                  </LinkWithOpts>
                  {viewer.user
                  ->Option.map(_ => <>
                    {" "->React.string}
                    <svg viewBox="0 0 2 2" className="h-1.5 w-1.5 inline flex-none fill-gray-600">
                      <circle cx={1->Int.toString} cy={1->Int.toString} r={1->Int.toString} />
                    </svg>
                    {" "->React.string}
                    <Link to={"/events"} relative="path"> {t`my events`} </Link>
                  </>)
                  ->Option.getOr(React.null)}
                </div>
              </Grid>
            </Layout.Container>}
          />

          // <Router.Outlet context={fragmentRefs} />
        </React.Suspense>
      </>
    }}
  </WaitForMessages>
}

let \"Component" = make

type params = {...EventsQuery_graphql.Types.variables, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = lang => {
  let messages = switch lang {
  | "ja" => Lingui.import("../../locales/src/components/pages/Events.re/ja")
  | _ => Lingui.import("../../locales/src/components/pages/Events.re/en")
  }->Promise.thenResolve(messages =>
    Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  )
  // Debug code to delay client message bundle loading
  // ->Promise.then(messages =>
  //   Promise.make((resolve, _) =>
  //     setTimeout(
  //       _ => {
  //         Js.log("Events Messages Load")
  //         Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  //         resolve()
  //       },
  //       RelaySSRUtils.ssr ? 0 : 3000,
  //     )->ignore
  //   )
  // )
  [messages]
}
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")
  let activity = url.searchParams->Router.SearchParams.get("activity")
  let afterDate =
    url.searchParams
    ->Router.SearchParams.get("afterDate")
    ->Option.map(d => {
      d->Js.Date.fromString->Util.Datetime.fromDate
    })
    // @TODO: Server Date will mismatch with client date potentially
    // ->Option.getOr(Js.Date.make()->Util.Datetime.fromDate)

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  {
    WaitForMessages.data: EventsQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        ?after,
        ?before,
        ?afterDate,
        filters: {
          activitySlug: ?activity,
        },
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    // i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
    // i18nData: !RelaySSRUtils.ssr ? await Localized.loadMessages(params.lang, loadMessages) : %raw("[]"),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  }
}

// @genType
// let \"HydrateFallbackElement" =
//   <div> {React.string("Loading fallback...")} </div>

// %raw("loade;.hydrate = true")
// let useFragmentRefs = (): RescriptRelay.fragmentRefs<[#EventsListFragment]> => {
//   let data = Router.useOutletContext()
//   data
// }

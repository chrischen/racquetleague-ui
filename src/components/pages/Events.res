%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module EventsQuery = %relay(`
  query EventsQuery($after: String, $first: Int, $before: String, $afterDate: Datetime, $filters: EventFilters) {
    ... EventsListFragment @arguments(
      after: $after,
      first: $first,
      before: $before,
      afterDate: $afterDate,
      filters: $filters
    )
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
module ActivityDropdownMenu = {
  type navItem = {label: string, url: string, initials?: string}
  let ts = Lingui.UtilString.t
  @react.component
  let make = () => {
    open Dropdown
    let activities = [
      {label: ts`All`, url: "/"},
      {label: ts`Pickleball`, url: "/?activity=pickleball", initials: "P"},
      {label: ts`Badminton`, url: "/?activity=badminton", initials: "B"},
    ]
    <DropdownMenu className="min-w-80 lg:min-w-64" anchor="bottom start">
      {activities
      ->Array.map(a =>
        <React.Fragment key={a.label}>
          <DropdownItem href=a.url>
            {a.initials
            ->Option.map(initials =>
              <Avatar slot="icon" initials className="bg-purple-500 text-white" />
            )
            ->Option.getOr(React.null)}
            <DropdownLabel> {a.label->React.string} </DropdownLabel>
          </DropdownItem>
          <DropdownDivider />
        </React.Fragment>
      )
      ->React.array}
    </DropdownMenu>
  }
}
type loaderData = EventsQuery_graphql.queryRef
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Router
  open Dropdown
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  let {fragmentRefs} = EventsQuery.usePreloaded(~queryRef=query.data)
  let (searchParams, _) = Router.useSearchParamsFunc()
  let activityFilter = searchParams->Router.SearchParams.get("activity")
  let title = switch activityFilter {
  | Some("pickleball") => t`pickleball events`
  | Some("badminton") => t`badminton events`
  | _ => t`all events`
  }
  let shadowFilter =
    searchParams
    ->Router.SearchParams.get("shadow")
    ->Option.map(v => v == "true")
    ->Option.getOr(true)
  // let viewer = GlobalQuery.useViewer()
  let navigate = Router.useNavigate()

  let searchParams = searchParams->Router.ImmSearchParams.fromSearchParams

  <WaitForMessages>
    {() => {
      <>
        <EventsList
          events=fragmentRefs
          header={<Layout.Container>
            <Grid>
              <PageTitle>
                {title}
                <Dropdown>
                  <DropdownButton \"as"={Navbar.NavbarItem.make}>
                    <HeroIcons.ChevronDownIcon />
                  </DropdownButton>
                  <ActivityDropdownMenu />
                </Dropdown>
                {" "->React.string}
                <Link to="/events/create"> {"+"->React.string} </Link>
              </PageTitle>
              <div>
                <HeadlessUi.Switch.Group \"as"="div" className="flex items-center">
                  <HeadlessUi.Switch
                    checked={shadowFilter}
                    onChange={v => {
                      v
                        ? navigate(
                            "./?" ++
                            searchParams
                            ->Router.ImmSearchParams.set("shadow", "true")
                            ->Router.ImmSearchParams.toString,
                            None,
                          )->ignore
                        : navigate(
                            "./?" ++
                            searchParams
                            ->Router.ImmSearchParams.set("shadow", "false")
                            ->Router.ImmSearchParams.toString,
                            None,
                          )
                    }}
                    className={Util.cx([
                      shadowFilter ? "bg-indigo-600" : "bg-gray-200",
                      "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2",
                    ])}>
                    <span
                      ariaHidden=true
                      className={Util.cx([
                        shadowFilter ? "translate-x-5" : "translate-x-0",
                        "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
                      ])}
                    />
                  </HeadlessUi.Switch>
                  <HeadlessUi.Switch.Label \"as"="span" className="ml-3 text-sm">
                    <span className="font-medium text-gray-900"> {t`include private`} </span>
                    {" "->React.string}
                  </HeadlessUi.Switch.Label>
                </HeadlessUi.Switch.Group>
              </div>
            </Grid>
          </Layout.Container>}
        />

        // <Router.Outlet context={fragmentRefs} />
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

let loadMessages = Lingui.loadMessages({
  ja: Lingui.import("../../locales/src/components/pages/Events.re/ja"),
  en: Lingui.import("../../locales/src/components/pages/Events.re/en"),
  th: Lingui.import("../../locales/src/components/pages/Events.re/th"),
  zhCN: Lingui.import("../../locales/src/components/pages/Events.re/zh-CN"),
  zhTW: Lingui.import("../../locales/src/components/pages/Events.re/zh-TW"),
})

let loader = async ({context, params, request}: LoaderArgs.t) => {
  let validLangs = ["en", "ja", "th", "zh-TW", "zh-CN"]
  switch params.lang {
  | Some(lang) if !(validLangs->Array.includes(lang)) =>
    // Throw custom ReScript exception for invalid language
    raise(Lang.InvalidLanguageException(lang))
  | _ => ()
  }
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")
  let activity = url.searchParams->Router.SearchParams.get("activity")
  let shadow =
    url.searchParams
    ->Router.SearchParams.get("shadow")
    ->Option.map(v => v == "true")
    ->Option.getOr(true)
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
          shadow,
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

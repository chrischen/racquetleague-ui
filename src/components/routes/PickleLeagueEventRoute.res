@genType
let \"Component" = LeagueEventPage.make

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

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/LeagueEventPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/LeagueEventPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/LeagueEventPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/LeagueEventPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/LeagueEventPage.re/zh-CN"),
})
@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make

  // let lang = params.lang->Option.getOr("en")

  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore

  Router.defer({
    WaitForMessages.data: LeagueEventPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={eventId: params.eventId, ?after, ?before, first: 3, activitySlug: "pickleball"},
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

@genType
let \"HydrateFallbackElement" =
  <div> {React.string("Loading fallback...")} </div>

// %raw("loade;.hydrate = true")

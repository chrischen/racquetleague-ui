@genType
let \"Component" = ClubsListPage.make

type params = {lang: option<string>, activitySlug: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/ClubsListPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/ClubsListPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/ClubsListPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/ClubsListPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/ClubsListPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/ClubsListPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/ClubsListPage.re/vi"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make
  // The clubs resolver is scoped to one activity, and the sidebar renders this
  // page inside a sport, so the activity comes from the path segment. The
  // unscoped /clubs route has no segment and falls back to pickleball.
  let activitySlug = params.activitySlug->Option.getOr("pickleball")
  let after = url.searchParams->Router.SearchParams.get("after")

  // "Next event" cutoff, truncated to the hour so the server and the client
  // agree on the query's cache key across hydration.
  let afterDate = {
    let now = Js.Date.make()
    now->Js.Date.setMinutes(0.)->ignore
    now->Js.Date.setSeconds(0.)->ignore
    now->Js.Date.setMilliseconds(0.)->ignore
    now->Util.Datetime.fromDate
  }

  let query = ClubsListPageQuery_graphql.load(
    ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
    ~variables={
      activitySlug,
      first: 20,
      afterDate,
      ?after,
    },
    ~fetchPolicy=RescriptRelay.StoreOrNetwork,
  )
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: query,
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

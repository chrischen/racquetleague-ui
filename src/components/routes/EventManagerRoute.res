@genType
let \"Component" = EventManagerPage.make

type params = {
  ...EventQuery_graphql.Types.variables,
  activitySlug: string,
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
  en: Lingui.import("../../locales/src/components/pages/EventManagerPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/EventManagerPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/EventManagerPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/EventManagerPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/EventManagerPage.re/zh-CN"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make

  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore

  Router.defer({
    WaitForMessages.data: EventManagerPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        eventId: params.eventId,
        ?after,
        ?before,
        first: 3,
        activitySlug: params.activitySlug,
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

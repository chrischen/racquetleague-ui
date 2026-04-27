@genType
let \"Component" = PkEventPage.make

type params = {
  eventId: string,
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
  en: Lingui.import("../../locales/src/components/pages/PkEventPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/PkEventPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/PkEventPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/PkEventPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/PkEventPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/PkEventPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/PkEventPage.re/vi"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: PkEventPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        eventId: params.eventId,
        topic: params.eventId ++ ".updated",
        ?after,
        ?before,
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

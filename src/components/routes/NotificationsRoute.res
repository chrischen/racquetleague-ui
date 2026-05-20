@genType
let \"Component" = NotificationsPage.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/NotificationsPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/NotificationsPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/NotificationsPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/NotificationsPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/NotificationsPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/NotificationsPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/NotificationsPage.re/vi"),
})

@genType
let loader = async ({context, params}: LoaderArgs.t) => {
  let query = NotificationsPageQuery_graphql.load(
    ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
    ~variables=(),
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

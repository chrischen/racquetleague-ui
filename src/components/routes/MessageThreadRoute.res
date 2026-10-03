@genType
let \"Component" = MessageThreadPage.make

type params = {userId: string, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/MessageThreadPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/MessageThreadPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/MessageThreadPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/MessageThreadPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/MessageThreadPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/MessageThreadPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/MessageThreadPage.re/vi"),
})

@genType
let loader = async ({context, params}: LoaderArgs.t) => {
  let query = MessageThreadPageQuery_graphql.load(
    ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
    ~variables={withUserId: params.userId},
    // A conversation changes under the viewer (replies arrive, their own
    // replies were sent from this page), so always refresh it.
    ~fetchPolicy=RescriptRelay.StoreAndNetwork,
  )
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: query,
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

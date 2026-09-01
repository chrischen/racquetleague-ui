@genType
let \"Component" = MatchmakingLabPage.make

type params = {lang: option<string>}

module LoaderArgs = {
  type t = {
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/MatchmakingLabPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/MatchmakingLabPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/MatchmakingLabPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/MatchmakingLabPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/MatchmakingLabPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/MatchmakingLabPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/MatchmakingLabPage.re/vi"),
})

@genType
let loader = async ({params, request: _}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore

  Router.defer({
    WaitForMessages.data: (),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

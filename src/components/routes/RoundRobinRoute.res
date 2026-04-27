@genType
let \"Component" = RoundRobinPage.make

type params = {lang: option<string>}

module LoaderArgs = {
  type t = {
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/RoundRobinPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/RoundRobinPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/RoundRobinPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/RoundRobinPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/RoundRobinPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/RoundRobinPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/RoundRobinPage.re/vi"),
})

@genType
let loader = async ({params, request: _}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore

  Router.defer({
    WaitForMessages.data: (),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

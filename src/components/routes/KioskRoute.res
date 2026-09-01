@genType
let \"Component" = KioskPage.make

type params = {lang: option<string>}

module LoaderArgs = {
  type t = {
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/KioskPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/KioskPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/KioskPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/KioskPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/KioskPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/KioskPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/KioskPage.re/vi"),
})

@genType
let loader = async ({params, request: _}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore

  Router.defer({
    WaitForMessages.data: (),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

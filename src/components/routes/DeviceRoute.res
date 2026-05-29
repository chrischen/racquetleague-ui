@genType
let \"Component" = DevicePage.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context?: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/DevicePage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/DevicePage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/DevicePage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/DevicePage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/DevicePage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/DevicePage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/DevicePage.re/vi"),
})

@genType
let loader = async ({params}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: None,
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

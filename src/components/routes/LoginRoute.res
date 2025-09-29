%%raw("import '../../global/static.css'")

@genType
let \"Component" = LoginPage.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context?: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/LoginPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/LoginPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/LoginPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/LoginPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/LoginPage.re/zh-CN"),
})

@genType
let loader = async ({params}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: None,
    // Localized.i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

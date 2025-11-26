@genType
let \"Component" = EventManagerGuidePage.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/EventManagerGuidePage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/EventManagerGuidePage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/EventManagerGuidePage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/EventManagerGuidePage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/EventManagerGuidePage.re/zh-CN"),
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

@genType
let \"Component" = CreateEventPage.make

type params = {slug: string, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/CreateEventPage.re/zh-CN"),
})

@genType
let loader = async ({params}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: (),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

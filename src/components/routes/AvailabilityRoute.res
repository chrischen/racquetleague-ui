@genType
let \"Component" = AvailabilityPage.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/AvailabilityPage.re/vi"),
})

// Availability data is client-only (fetched after the geolocation permission
// prompt resolves) — the loader only handles i18n; see AvailabilityPage.res.
@genType
let loader = async ({params}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: (),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

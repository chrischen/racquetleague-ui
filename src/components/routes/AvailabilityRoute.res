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

// Standard SSR preload: the query is scoped by the default location — the
// server substitutes the viewer's stored coords (User.coords) when it knows
// them, and AvailabilityPage captures them via ViewerLocationPrompt when it
// doesn't.
@genType
let loader = async ({context, params}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  let (fromDate, toDate) = AvailabilityPage.getDateRange()
  Router.defer({
    WaitForMessages.data: AvailabilityPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        activityId: AvailabilityPage.defaultActivityId,
        fromDate,
        toDate,
        afterDate: Util.Datetime.fromDate(Js.Date.make()),
        location: UseUserLocation.tokyoDefault,
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

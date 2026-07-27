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

// Standard SSR preload: scoped by the `coords` URL param (the location filter)
// when present; absent, the Tokyo default lets the server fall back to the
// viewer's stored coords (User.coords), and the filter captures them.
@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  let (fromDate, toDate) = AvailabilityPage.getDateRange()
  let url = request.url->Router.URL.make
  // Build the LocationInput from the `location` URL param (region name or coords)
  // when present; leave it out otherwise so the server resolves the viewer's
  // stored coords, then the default.
  let location =
    url.searchParams
    ->Router.SearchParams.get(UseUserLocation.locationParamKey)
    ->Option.flatMap(UseUserLocation.locationInputFromParam)
  Router.defer({
    WaitForMessages.data: AvailabilityPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        activityId: AvailabilityPage.defaultActivityId,
        fromDate,
        toDate,
        afterDate: Util.Datetime.fromDate(Js.Date.make()),
        ?location,
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

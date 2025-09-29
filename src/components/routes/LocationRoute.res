@genType
let \"Component" = LocationPage.make

type params = {locationId: string, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/LocationPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/LocationPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/LocationPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/LocationPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/LocationPage.re/zh-CN"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")
  let afterDate =
    url.searchParams
    ->Router.SearchParams.get("afterDate")
    ->Option.map(d => {
      d->Js.Date.fromString->Util.Datetime.fromDate
    })
  let query = LocationPageQuery_graphql.load(
    ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
    ~variables={
      id: params.locationId,
      filters: {locationId: params.locationId},
      ?after,
      ?before,
      ?afterDate,
    },
    ~fetchPolicy=RescriptRelay.StoreOrNetwork,
  )
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: query,
    // Localized.i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

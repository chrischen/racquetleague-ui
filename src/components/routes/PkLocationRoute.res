@genType
let \"Component" = PkLocationPage.make

type params = {locationId: string, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/PkLocationPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/PkLocationPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/PkLocationPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/PkLocationPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/PkLocationPage.re/zh-CN"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")
  let afterDate =
    url.searchParams
    ->Router.SearchParams.get("afterDate")
    ->Option.map(d => d->Js.Date.fromString->Util.Datetime.fromDate)

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: PkLocationPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        id: params.locationId,
        ?after,
        ?before,
        ?afterDate,
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

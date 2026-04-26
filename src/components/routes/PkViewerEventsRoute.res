@genType
let \"Component" = PkViewerEventsPage.make

type params = {...PkViewerEventsPageQuery_graphql.Types.variables, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/PkViewerEventsPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/PkViewerEventsPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/PkViewerEventsPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/PkViewerEventsPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/PkViewerEventsPage.re/zh-CN"),
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

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  {
    WaitForMessages.data: PkViewerEventsPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        ?after,
        ?before,
        ?afterDate,
        filters: {viewer: true},
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  }
}

@genType
let \"HydrateFallbackElement" =
  <div> {React.string("Loading fallback...")} </div>

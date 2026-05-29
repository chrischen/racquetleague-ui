@genType
let \"Component" = ClubEventsPage.make

type params = {slug: string, lang: option<string>, afterDate: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/ClubEventsPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/ClubEventsPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/ClubEventsPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/ClubEventsPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/ClubEventsPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/ClubEventsPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/ClubEventsPage.re/vi"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make

  let afterDate =
    url.searchParams
    ->Router.SearchParams.get("afterDate")
    ->Option.map(d => d->Js.Date.fromString->Util.Datetime.fromDate)

  let environment = RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr)

  let query = ClubEventsPageQuery_graphql.load(
    ~environment,
    ~variables={slug: params.slug, ?afterDate},
    ~fetchPolicy=RescriptRelay.StoreOrNetwork,
  )
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: query,
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

@genType
let \"Component" = EventsMapPage.make

type params = {activitySlug: option<string>, lang: option<string>}

module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  ja: Lingui.import("../../locales/src/components/pages/EventsMapPage.re/ja"),
  en: Lingui.import("../../locales/src/components/pages/EventsMapPage.re/en"),
  th: Lingui.import("../../locales/src/components/pages/EventsMapPage.re/th"),
  zhCN: Lingui.import("../../locales/src/components/pages/EventsMapPage.re/zh-CN"),
  zhTW: Lingui.import("../../locales/src/components/pages/EventsMapPage.re/zh-TW"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let validLangs = ["en", "ja", "th", "zh-TW", "zh-CN"]
  switch params.lang {
  | Some(lang) if !(validLangs->Array.includes(lang)) => raise(Lang.InvalidLanguageException(lang))
  | _ => ()
  }
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  let activity = params.activitySlug->Option.getOr("pickleball")

  let shadow =
    url.searchParams
    ->Router.SearchParams.get("shadow")
    ->Option.map(v => v == "true")
    ->Option.getOr(true)
  let afterDate =
    url.searchParams
    ->Router.SearchParams.get("afterDate")
    ->Option.map(d => {
      d->Js.Date.fromString->Util.Datetime.fromDate
    })

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  {
    WaitForMessages.data: EventsMapPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={
        ?after,
        ?before,
        ?afterDate,
        filters: {
          activitySlug: activity,
          shadow,
        },
      },
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  }
}

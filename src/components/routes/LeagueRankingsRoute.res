/* module Fragment = %relay(`
  fragment Events_event on Event {
    ... Event_event
  }
`)*/
/* module Query = %relay(`
  query EventQuery {
    event(id: "1") {
      title
			... EventRsvps_event
		}
  }
`)*/

@genType
let \"Component" = LeagueRankingsPage.make

type params = {
  ns?: string,
  ...LeagueRankingsPageQuery_graphql.Types.variables,
  lang: option<string>,
}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/vi"),
})

type loaderData = LeagueRankingsPage.loaderData

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  // When only :ns is matched, it could be a namespace or a club slug
  let knownNamespaces = ["doubles:comp", "singles:comp"]
  let (namespace, clubSlug) = switch (params.ns, params.clubSlug) {
  | (Some(ns), Some(club)) => (ns, Some(club))
  | (Some(value), None) =>
    if knownNamespaces->Array.includes(value) {
      (value, None)
    } else {
      ("doubles:comp", Some(value))
    }
  | (None, _) => ("doubles:comp", None)
  }

  // await Promise.make((resolve, _) => setTimeout(_ => {Js.log("Delay loader");resolve()}, 200)->ignore)
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  {
    WaitForMessages.data: {
      LeagueRankingsPage.query: RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr)->(
        env =>
          LeagueRankingsPageQuery_graphql.load(
            ~environment=env,
            ~variables={
              ?after,
              ?before,
              activitySlug: params.activitySlug,
              namespace,
              ?clubSlug,
            },
            ~fetchPolicy=RescriptRelay.StoreOrNetwork,
          )
      ),
    },
    // i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
    // i18nData: !RelaySSRUtils.ssr ? await Localized.loadMessages(params.lang, loadMessages) : %raw("[]"),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  }
}
@genType
let \"HydrateFallbackElement" =
  <div> {React.string("Loading fallback...")} </div>

// %raw("loade;.hydrate = true")

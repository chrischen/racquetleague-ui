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
  ja: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/ja"),
  en: Lingui.import("../../locales/src/components/pages/LeagueRankingsPage.re/en"),
})

type loaderData = LeagueRankingsPage.loaderData

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")
  let namespace = params.ns->Option.getOr("doubles:comp")

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

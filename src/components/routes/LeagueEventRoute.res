@genType
let \"Component" = LeagueEventPage.make


type params = {
  ...EventQuery_graphql.Types.variables,
  activitySlug: string,
  lang: option<string>,
}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = lang => {
  let messages = switch lang {
  | "ja" => Lingui.import("../../locales/src/components/pages/LeagueEventPage.re/ja")
  | _ => Lingui.import("../../locales/src/components/pages/LeagueEventPage.re/en")
  }->Promise.thenResolve(messages =>
    Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  )
  [messages]
}
@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make

  // let lang = params.lang->Option.getOr("en")

  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")

  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore

  Router.defer({
    WaitForMessages.data: LeagueEventPageQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={eventId: params.eventId, ?after, ?before, first: 3, activitySlug: params.activitySlug, namespace: "doubles:rec"},
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}

// @genType
// let \"HydrateFallbackElement" =
//   <div> {React.string("Loading fallback...")} </div>

// %raw("loade;.hydrate = true")

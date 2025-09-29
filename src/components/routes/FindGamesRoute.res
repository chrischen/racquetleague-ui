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
let \"Component" = FindGamesPage.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context?: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/FindGamesPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/FindGamesPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/FindGamesPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/FindGamesPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/FindGamesPage.re/zh-CN"),
})
// Debug code to delay client message bundle loading
// ->Promise.then(messages =>
//   Promise.make((resolve, _) =>
//     setTimeout(
//       _ => {
//         Js.log("Events Messages Load")
//         Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
//         resolve()
//       },
//       RelaySSRUtils.ssr ? 0 : 3000,
//     )->ignore
//   )
// )
@genType
let loader = async ({params}: LoaderArgs.t) => {
  // await Promise.make((resolve, _) => setTimeout(_ => {Js.log("Delay loader");resolve()}, 200)->ignore)
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  {
    WaitForMessages.data: None,
    // WaitForMessages.data: Option.map(RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr), env =>
    //   FindGamesPageQuery_graphql.load(
    //     ~environment=env,
    //     ~variables={
    //       ?after,
    //       ?before,
    //       activitySlug: "pickleball",
    //       namespace: "doubles:rec"
    //     },
    //     ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    //   )
    // ),
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

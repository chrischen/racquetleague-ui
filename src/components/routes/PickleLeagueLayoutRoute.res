%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
// %%raw("import '../../global/static.css'")

@genType
let \"Component" = LeagueLayout.make

let loadMessages = lang => {
  let messages = switch lang {
  | "ja" => Lingui.import("../../locales/src/components/pages/LeagueLayout.re/ja")
  | _ => Lingui.import("../../locales/src/components/pages/LeagueLayout.re/en")
  }->Promise.thenResolve(messages => {
    Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  })
  // }->Promise.thenResolve(messages => Lingui.i18n.loadAndActivate({locale: lang, messages: messages["messages"]}))
  [messages]
}
type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}
@genType
let loader = async ({context, params}: LoaderArgs.t) => {
  Router.defer({
    WaitForMessages.data: DefaultLayoutQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables=(),
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}
@genType
let \"HydrateFallbackElement" =
  <Layout.Container> {React.string("Loading fallback...")} </Layout.Container>
// %raw("loader.hydrate = true")

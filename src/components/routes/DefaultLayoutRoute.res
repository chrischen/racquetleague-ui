%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
// %%raw("import '../../global/static.css'")

@genType
let \"Component" = DefaultLayoutMap.make

let loadMessages = Lingui.loadMessages({
  ja: Lingui.import("../../locales/src/components/pages/DefaultLayoutMap.re/ja"),
  en: Lingui.import("../../locales/src/components/pages/DefaultLayoutMap.re/en"),
})

type params = {activitySlug: string, lang: option<string>}
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
    WaitForMessages.data: DefaultLayoutMapQuery_graphql.load(
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

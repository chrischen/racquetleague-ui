%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

@genType
let \"Component" = PkuruLayout.make

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/PkuruLayout.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/PkuruLayout.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/PkuruLayout.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/PkuruLayout.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/PkuruLayout.re/zh-CN"),
  ko: Lingui.import("../../locales/src/components/pages/PkuruLayout.re/ko"),
  vi: Lingui.import("../../locales/src/components/pages/PkuruLayout.re/vi"),
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
    WaitForMessages.data: PkuruLayoutQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables=(),
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}
// @genType
// let \"HydrateFallbackElement" =
//   <div className="flex h-screen w-full bg-white dark:bg-[#1a1a1e]">
//     <div className="hidden md:flex w-[200px] flex-shrink-0 border-r border-gray-200 dark:border-[#2a2b30] bg-white dark:bg-[#1e1f23] flex-col" />
//     <div className="flex-1 flex flex-col min-w-0 bg-white dark:bg-[#222326]">
//       <div className="h-14 border-b border-gray-200 dark:border-[#2a2b30] flex-shrink-0" />
//       <div className="flex-1" />
//     </div>
//   </div>

@genType
let \"HydrateFallbackElement" =
  <Layout.Container> {React.string("Loading fallback...")} </Layout.Container>

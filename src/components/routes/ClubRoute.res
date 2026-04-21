@genType
let \"Component" = ClubPage.make

type params = {slug: string, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/ClubPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/ClubPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/ClubPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/ClubPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/ClubPage.re/zh-CN"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let environment = RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr)

  let query = ClubPageQuery_graphql.load(
    ~environment,
    ~variables={
      slug: params.slug,
    },
    ~fetchPolicy=RescriptRelay.StoreOrNetwork,
  )
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: query,
    // Localized.i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

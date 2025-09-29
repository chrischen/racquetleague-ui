@genType
let \"Component" = ClubMembersPage.make

type params = {slug: string, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/ClubMembersPage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/ClubMembersPage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/ClubMembersPage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/ClubMembersPage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/ClubMembersPage.re/zh-CN"),
})

@genType
let loader = async ({context, params, request}: LoaderArgs.t) => {
  let url = request.url->Router.URL.make
  let after = url.searchParams->Router.SearchParams.get("after")
  let before = url.searchParams->Router.SearchParams.get("before")
  let first =
    url.searchParams
    ->Router.SearchParams.get("first")
    ->Option.flatMap(str => Int.fromString(str))
    ->Option.getOr(20)

  let query = ClubMembersPageQuery_graphql.load(
    ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
    ~variables={
      slug: params.slug,
    },
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

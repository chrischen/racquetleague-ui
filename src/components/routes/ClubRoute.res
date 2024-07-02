@genType
let \"Component" = ClubPage.make

type params = {clubId: string, lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = lang => {
  let messages = switch lang {
  | "ja" => Lingui.import("../../locales/src/components/pages/ClubPage.re/ja")
  | _ => Lingui.import("../../locales/src/components/pages/ClubPage.re/en")
  }->Promise.thenResolve(messages =>
    Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  )

  [messages]
}

@genType
let loader = async ({context, params}: LoaderArgs.t) => {
  let query = ClubPageQuery_graphql.load(
    ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
    ~variables={id: params.clubId, filters: {clubId: params.clubId}},
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

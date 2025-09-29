type data<'a> = Promise('a) | Empty

let isEmptyObj: 'a => bool = %raw(
  "obj => Object.keys(obj).length === 0 && obj.constructor === Object"
)
let parseData: 'a => data<'a> = json => {
  if isEmptyObj(json) {
    Empty
  } else {
    Promise(json)
  }
}

@genType
let \"Component" = SettingsProfilePage.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}

let loadMessages = Lingui.loadMessages({
  en: Lingui.import("../../locales/src/components/pages/SettingsProfilePage.re/en"),
  ja: Lingui.import("../../locales/src/components/pages/SettingsProfilePage.re/ja"),
  th: Lingui.import("../../locales/src/components/pages/SettingsProfilePage.re/th"),
  zhTW: Lingui.import("../../locales/src/components/pages/SettingsProfilePage.re/zh-TW"),
  zhCN: Lingui.import("../../locales/src/components/pages/SettingsProfilePage.re/zh-CN"),
})

@genType
let loader = async ({context, params}: LoaderArgs.t) => {
  let query = SettingsProfilePageQuery_graphql.load(
    ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
    ~variables=(),
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

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
let \"Component" = CreateLocation.make

type params = {lang: option<string>}
module LoaderArgs = {
  type t = {
    context?: RelayEnv.context,
    params: params,
    request: Router.RouterRequest.t,
  }
}
let loadMessages = lang => {
  let messages = switch lang {
  | "ja" => Lingui.import("../../locales/src/components/organisms/CreateLocation.re/ja")
  | _ => Lingui.import("../../locales/src/components/organisms/CreateLocation.re/en")
  }->Promise.thenResolve(messages =>
    Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  )

  [messages]
}

@genType
let loader = async ({params}: LoaderArgs.t) => {
  (RelaySSRUtils.ssr ? Some(await Localized.loadMessages(params.lang, loadMessages)) : None)->ignore
  Router.defer({
    WaitForMessages.data: None,
    // Localized.i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
    i18nLoaders: ?(
      RelaySSRUtils.ssr ? None : Some(Localized.loadMessages(params.lang, loadMessages))
    ),
  })
}

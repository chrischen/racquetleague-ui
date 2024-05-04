// %%raw("import { css, cx } from '@linaria/core'")
// %%raw(`import { I18nProvider } from "@lingui/react"`)
// %%raw("import { t } from '@lingui/macro'")

// @module("../locales/ja/messages")
module RouteParams = {
  type t = {lang: option<string>, locale: option<string>}

  let parse = (json: Js.Json.t): result<t, string> => {
    open JsonCombinators.Json.Decode

    let decoder = object(field => {
      lang: field.optional("lang", string),
      locale: field.optional("locale", string),
    })
    try {
      json->JsonCombinators.Json.decode(decoder)
    } catch {
    | _ => Error("An unexpected error occurred when checking the id.")
    }
  }
}

module LoaderArgs = {
  type t = {
    context?: RelayEnv.context,
    params: RouteParams.t,
    request: Router.RouterRequest.t,
  }
}

@val external importLang: 'a => Js.Promise.t<{"messages": Lingui.Messages.t}> = "import"

@genType
let loader = async ({ params }: LoaderArgs.t) => {
  let lang = params.lang->Option.getOr("en")
  let locale = switch lang {
  | "ja" => "jp"
  | _ => "us"
  }

  Lingui.i18n.activate(lang)
  {
    LangProvider.locale,
    lang,
    timezone: "jst"
  }
}
// %raw("loader.hydrate = false")

@genType
let \"Component" = LangProvider.make

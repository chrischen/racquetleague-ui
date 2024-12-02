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

external window: LocaleDetector.window = "window"
@genType
let loader = async ({params}: LoaderArgs.t) => {
  let lang = params.lang->Option.getOr("en")
  let locale = switch lang {
  | "ja" => "jp"
  | _ => "us"
  }

  let detectedLocale = Some(
    RelaySSRUtils.ssr
      ? LocaleDetector.detect([
          LocaleDetector.fromNavigator({language: lang}),
          switch lang {
          | "ja" => LocaleDetector.jaFallback
          | _ => LocaleDetector.enFallback
          },
        ])
      : {
          LocaleDetector.detect([
            LocaleDetector.fromNavigator(window.navigator),
            switch lang {
            | "ja" => LocaleDetector.jaFallback
            | _ => LocaleDetector.enFallback
            },
          ])
        }->String.toLowerCase,
  )

  Lingui.i18n.activate(lang)

  let detectedLang = detectedLocale->(Option.flatMap(_, LangProvider.parseLang))

  {
    LangProvider.locale,
    detectedLocale: ?detectedLocale->(Option.flatMap(_, LangProvider.parseLocale)),
    ?detectedLang,
    lang,
    timezone: "jst",
  }
}
// %raw("loader.hydrate = false")

@genType
let \"Component" = LangProvider.make

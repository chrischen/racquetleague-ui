%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

@genType
let \"Component" = DefaultLayoutContentPage.make

let loadMessages = lang => {
  let messages = switch lang {
  | "ja" => Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/ja")
  | _ => Lingui.import("../../locales/src/components/pages/DefaultLayoutContentPage.re/en")
  }->Promise.thenResolve(messages => {
    Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  })
  // }->Promise.thenResolve(messages => Lingui.i18n.loadAndActivate({locale: lang, messages: messages["messages"]}))
  [messages]
}

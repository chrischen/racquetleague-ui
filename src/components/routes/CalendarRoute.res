@genType
let \"Component" = Calendar.make

let loadMessages = lang => {
  let messages = switch lang {
  | "ja" => Lingui.import("../../locales/src/components/organisms/Calendar.re/ja")
  | _ => Lingui.import("../../locales/src/components/organisms/Calendar.re/en")
  }->Promise.thenResolve(messages =>
    Util.startTransition(() => Lingui.i18n.load(lang, messages["messages"]))
  )

  [messages]
}


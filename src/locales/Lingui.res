module Messages: {
  type t
  // let merge: (t, t) => t;
  let empty: t
} = {
  type t = Js.Json.t
  let empty = Json.Encode.object([])

  // let merge: (t, t) => t = %raw(`function(a, b) { return {...a, ...b}}`)
}
// type msgs = string
type loadAndActivateOpts = {
  locale: string,
  messages: Messages.t,
  locales?: array<string>,
}
type t = {
  load: (string, Messages.t) => unit,
  loadAndActivate: loadAndActivateOpts => unit,
  activate: string => unit,
  locale: string,
}
type lingui = {i18n: t}
@module("@lingui/react")
external useLingui: unit => lingui = "useLingui"

type core = {i18n: t}
// @module("@lingui/core")
// external linguiCore: core = "default"

@module("@lingui/core")
external i18n: t = "i18n"
let i18n = i18n

@send
external trans: (t, string) => string = "_"

type transOpts = {
  message: string,
  id?: string,
  comment?: string,
}
@send
external trans2: (t, transOpts) => string = "_"

type setupOpts = {locale: string}
@module("@lingui/core")
external setupI18n: (~opts: option<setupOpts>=?) => t = "setupI18n"
let detectedI18n = setupI18n()

module I18nProvider = {
  @module("@lingui/react") @react.component
  external // @react.component
  make: (~i18n: t, ~children: React.element) => React.element = "I18nProvider"
}

type messageBundle = {messages: Messages.t}
@val external import: 'a => Js.Promise.t<messageBundle> = "import"

type srcMap = {
  en: promise<messageBundle>,
  ja: promise<messageBundle>,
  th: promise<messageBundle>,
  zhTW: promise<messageBundle>,
  zhCN: promise<messageBundle>,
}
let loadMessages = src => lang => {
  let messages = switch lang {
  | "en" => src.en
  | "ja" => src.ja
  | "th" => src.th
  | "zh-TW" => src.zhTW
  | "zh-CN" => src.zhCN
  | _ => src.en
  }->Promise.thenResolve(messages => {
    Util.startTransition(() => i18n.load(lang, messages.messages))
  })
  // }->Promise.thenResolve(messages => Lingui.i18n.loadAndActivate({locale: lang, messages: messages["messages"]}))
  [messages]
}

let loadMessagesForDetected = src => lang => {
  let messages = switch lang {
  | "en" => src.en
  | "ja" => src.ja
  | "th" => src.th
  | "zh-TW" => src.zhTW
  | "zh-CN" => src.zhCN
  | _ => src.en
  }->Promise.thenResolve(messages => {
    Util.startTransition(() => detectedI18n.load(lang, messages.messages))
  })
  // }->Promise.thenResolve(messages => Lingui.i18n.loadAndActivate({locale: lang, messages: messages["messages"]}))
  [messages]
}

module Util = {
  @val @taggedTemplate
  external t: (array<string>, array<string>) => React.element = "t"

  @val @taggedTemplate
  external tr: (array<string>, array<React.element>) => React.element = "t"

  type pluralOpts = {
    one: string,
    other: string,
  }
  @val
  external plural: (int, pluralOpts) => React.element = "plural"
}
module UtilString = {
  type msgObj = {id?: string, comment?: string, message?: string}
  @val
  external td: msgObj => string = "t"
  @val @taggedTemplate
  external t: (array<string>, array<string>) => string = "t"

  type pluralOpts = {
    one: string,
    other: string,
  }
  @val
  external plural: (int, pluralOpts) => string = "plural"

  @module("@lingui/core") @scope("i18n")
  external dynamic: string => string = "_"
}

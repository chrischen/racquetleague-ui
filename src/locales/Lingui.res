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

module I18nProvider = {
  @module("@lingui/react") @react.component
  external // @react.component
  make: (~i18n: t, ~children: React.element) => React.element = "I18nProvider"
}

type messageBundle = {messages: Messages.t}
@val external import: 'a => Js.Promise.t<messageBundle> = "import"

type srcMap = {
  ja: promise<messageBundle>,
  en: promise<messageBundle>,
}
let loadMessages = src => lang => {
  let messages = switch lang {
  | "ja" => src.ja
  | _ => src.en
  }->Promise.thenResolve(messages => {
    Util.startTransition(() => i18n.load(lang, messages.messages))
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

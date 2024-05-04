/* @variadic @val external cx: array<string> => string = "cx" */
@variadic @module("@linaria/core") external cx: array<string> => string = "cx"

type inlineScript = {
  @as("type")
  type_: string,
  innerHTML: string,
}
module Helmet = {
  @module("react-helmet-async") @react.component
  external make: (
    ~children: React.element,
    ~script: option<array<inlineScript>>=?,
  ) => React.element = "Helmet"
}

@live
module Datetime: {
  /** A date. */
  @gql.scalar
  type t

  let parse: Js.Json.t => t
  let serialize: t => Js.Json.t
  let fromDate: Date.t => t
  let toDate: t => Date.t
} = {
  type t = Date.t

  let fromDate = d => d
  let parse = d => d->Json.decode(Json.Decode.string)->Result.map(Date.fromString)->Result.getExn

  let serialize = d => Json.Encode.string(d->Date.toString)
  let toDate = d => d
}

@module("react")
external startTransition: (unit => unit) => unit = "startTransition"

@val external encodeURIComponent: string => string = "encodeURIComponent"

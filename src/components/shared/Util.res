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

module NonEmptyArray = {
  type t<'a> = option<array<'a>>
  let map = (arr: t<'a>, f: 'a => 'b): t<'b> => arr->Option.map(Array.map(_, f))
  let mapWithIndex: (t<'a>, ('a, int) => 'b) => t<'b> = (arr, f) => arr->Option.map(Array.mapWithIndex(_, f))
  let toArray = (arr: t<'a>): array<'a> => arr->Option.getOr([])
  let fromArray = (arr: array<'a>): t<'a> => arr->Array.length == 0 ? None : Some(arr)
  let empty = None
  let pure = x => Some([x])
  let concat = (a: t<'a>, b: t<'a>): t<'a> =>
    switch (a, b) {
    | (Some(a), Some(b)) => Some(a->Array.concat(b))
    | _ => b
    }
  let flatMap = (arr: t<'a>, f: 'a => t<'b>): t<'b> =>
    switch arr {
    | Some(arr) =>
      switch arr
      ->Array.map(i => f(i))
      ->Array.reduce([], (acc, x) =>
        switch x {
        | Some(x) => acc->Array.concat(x)
        | None => acc
        }
      ) {
      | [] => None
      | arr => Some(arr)
      }
    | None => None
    }
  let toSet: t<'a> => Set.t<'a> = arr => arr->Option.getOr([])->Set.fromArray
  let filter: (t<'a>, 'a => bool) => t<'a> = (arr, f) =>
    switch arr {
    | Some(arr) =>
      (
        arr =>
          switch arr {
          | [] => None
          | arr => Some(arr)
          }
      )(arr->Array.filter(f))

    | None => None
    }
  let filterWithIndex: (t<'a>, ('a, int) => bool) => t<'a> = (arr, f) =>
    switch arr {
    | Some(arr) =>
      arr
      ->Array.filterWithIndex(f)
      ->(
        arr =>
          switch arr {
          | [] => None
          | arr => Some(arr)
          }
      )

    | None => None
    }
}

module JsSet = {
  type t<'a> = Set.t<'a>;

  @send
  external difference: (t<'a>, t<'a>) => t<'a> = "difference"
}

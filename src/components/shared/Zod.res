type t

@module("zod")
external z: t = "z"

type string_ = string
type number = float
type object<'form> = 'form
type optional<'value> = option<'value>
type optional2<'value> = Js.Null.t<'value>
type array<'value> = array<'value>
type params = {required_error?: string, invalid_type_error?: string}

type zodEffect;
@send
external string: (t, params) => string_ = "string"

module String = {
  @send
  external min: (string_, int) => string_ = "min"

  @send
  external max: (string_, int) => string_ = "max"
}

module Int = {
  @send
  external min: (number, int) => number = "min"

  @send
  external max: (number, int) => number = "max"

  @send
  external positive: number => number = "positive"

  @send
  external int: number => number = "int"
}

module Number = {
  @send
  external union: (t, array<number>) => number = "union"

  @send
  external gte: (number, number) => number = "gte"

  @send
  external lte: (number, number) => number = "lte"
}
@send
external number: (t, params) => number = "number"
@send
external numberInt: (t, params) => int = "number"

@send
external boolean: (t, params) => bool = "boolean"

@send
external nan: t => number = "nan"

@get
external coerce: t => t = "coerce"

@send
external object: (t, 'schema) => object<'schema> = "object"

@send
external optional: 'z => optional<'z> = "optional"

@send
external optional2: 'z => Js.Null.t<'z> = "optional"

@send
external array: 'z => array<'z> = "array"

@send
external preprocess: (t, 'a => 'b, 'b) => 'b = "preprocess"

type issue = {
  code: int,
  expected: string,
}
type error = {message: string}
type errorMap = issue => error
@send
external setErrorMap: (t, errorMap) => unit = "setErrorMap"

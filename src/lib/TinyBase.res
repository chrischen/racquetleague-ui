// TinyBase bindings
type store

// TinyBase stores JavaScript primitives (string, number, boolean)
// We use Js.Json.t since it can represent any JSON-compatible value
type row = Js.Dict.t<Js.Json.t>
type table = Js.Dict.t<row>

@module("tinybase") external createStore: unit => store = "createStore"
@send external setValue: (store, string, Js.Json.t) => unit = "setValue"
@send external getValue: (store, string) => Js.Json.t = "getValue"
@send external setCell: (store, string, string, string, Js.Json.t) => unit = "setCell"
@send external getCell: (store, string, string, string) => Js.Json.t = "getCell"
@send external setRow: (store, string, string, row) => unit = "setRow"
@send external getRow: (store, string, string) => row = "getRow"
@send external delRow: (store, string, string) => unit = "delRow"
@send external getTable: (store, string) => table = "getTable"
@send external setTable: (store, string, table) => unit = "setTable"
@send external delTable: (store, string) => unit = "delTable"

// IndexedDB Persister
type persister

@module("tinybase/persisters/persister-indexed-db")
external createIndexedDbPersister: (store, string) => persister = "createIndexedDbPersister"

@send external startAutoSave: persister => Promise.t<persister> = "startAutoSave"
@send external startAutoLoad: (persister, Js.Json.t) => Promise.t<persister> = "startAutoLoad"
@send external save: persister => Promise.t<persister> = "save"
@send external load: (persister, Js.Json.t) => Promise.t<persister> = "load"
@send external destroy: persister => unit = "destroy"

module React = {
  @module("tinybase/ui-react")
  external useValue: (string, store) => Js.Json.t = "useValue"

  @module("tinybase/ui-react")
  external useTable: (string, store) => table = "useTable"

  @module("tinybase/ui-react")
  external useRow: (string, string, store) => row = "useRow"

  @module("tinybase/ui-react")
  external useCell: (string, string, string, store) => Js.Json.t = "useCell"
}

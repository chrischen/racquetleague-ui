module PlayerState = {
  type t = {count: int, paid: bool}
  let make = () => {count: 0, paid: false}
}
type t = Js.Dict.t<PlayerState.t>
let make = () => Js.Dict.empty()
let get = (session: t, id: string) => session->Js.Dict.get(id)->Option.getOr(PlayerState.make())
let update = (session: t, id: string, f: PlayerState.t => PlayerState.t) => {
  let session = Js.Dict.fromArray(session->Js.Dict.entries)
  switch session->Js.Dict.get(id)->Option.map(state => session->Js.Dict.set(id, f(state))) {
  | Some(_) => ()
  | None => session->Js.Dict.set(id, f(PlayerState.make()))
  }
  session
}

let saveState = (t: t, namespace: string) =>
  Dom.Storage2.localStorage->Dom.Storage2.setItem(
    namespace ++ "-sessionState",
    t->Js.Json.stringifyAny->Option.getOr(""),
  )

external parse: string => t = "JSON.parse"

let loadState = (namespace: string): t => {
  switch Dom.Storage2.localStorage->Dom.Storage2.getItem(namespace ++ "-sessionState") {
  | Some(state) => state->parse
  | None => Js.Dict.empty()
  }
}

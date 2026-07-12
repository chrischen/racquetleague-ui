@val external apiEndpoint: option<string> = "import.meta.env.VITE_API_ENDPOINT"
@val external dev: bool = "import.meta.env.DEV"

type response
@val external fetch: (string, Js.Json.t) => promise<response> = "fetch"
@send external json: response => promise<Js.Json.t> = "json"

let errorToMessage = exn =>
  exn->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")

let execute: (~query: string, ~variablesJson: string) => promise<result<Js.Json.t, string>> =
  async (~query, ~variablesJson) => {
    try {
      let variables = variablesJson->Js.Json.parseExn
      let endpoint = if dev {
        apiEndpoint->Option.getOr("http://localhost:4555/graphql")
      } else {
        "/graphql"
      }

      let headers = Js.Dict.fromArray([("content-type", Js.Json.string("application/json"))])
      let body =
        Js.Dict.fromArray([("query", Js.Json.string(query)), ("variables", variables)])
        ->Js.Json.object_
        ->Js.Json.stringifyAny
        ->Option.getOr("")

      let options = Js.Dict.fromArray([
        ("method", Js.Json.string("POST")),
        ("credentials", Js.Json.string("include")),
        ("headers", headers->Js.Json.object_),
        ("body", Js.Json.string(body)),
      ])

      let response = await fetch(endpoint, options->Js.Json.object_)
      let responseJson = await response->json
      Ok(responseJson)
    } catch {
    | exn => Error(errorToMessage(exn))
    }
  }

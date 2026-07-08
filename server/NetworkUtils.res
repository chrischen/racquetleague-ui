@val external dev: bool = "import.meta.env.DEV"
@val external apiEndpoint: option<string> = "import.meta.env.VITE_API_ENDPOINT"

// SSR runs in Node and cannot fetch a relative URL like "/graphql".
// When VITE_API_ENDPOINT is relative (used to let the browser go through
// the Vite proxy for HTTPS-tunnel / CORS reasons in dev), the SSR side
// still needs an absolute URL to reach the backend directly.
let serverApiEndpoint = () =>
  switch apiEndpoint {
  | Some(url) if !(url->String.startsWith("/")) => url
  | _ => "http://localhost:4555/graphql"
  }

// This is a simple example of how one could leverage `preloadAsset` to preload
// things from the GraphQL response. This should live inside of the
// (comprehensive) example application we're going to build eventually.
let preloadFromResponse = (part: Js.Json.t, ~preloadAsset: RelayRouter__Types.preloadAssetFn) => {
  switch part->Js.Json.decodeObject {
  | None => ()
  | Some(obj) =>
    switch obj->Dict.get("extensions") {
    | None => ()
    | Some(extensions) =>
      switch extensions->Js.Json.decodeObject {
      | None => ()
      | Some(extensions) =>
        extensions
        ->Dict.get("preloadableImages")
        ->Option.map(images =>
          images
          ->Js.Json.decodeArray
          ->Option.getOr([])
          ->Array.filterMap(item => item->Js.Json.decodeString)
        )
        ->Option.getOr([])
        ->Array.forEach(imgUrl => {
          preloadAsset(~priority=RelayRouter.Types.Default, RelayRouter.Types.Image({url: imgUrl}))
        })
      }
    }
  }
}

module OptionArray = {
  let sequence: array<option<'a>> => option<array<'a>> = xs => {
    Some(xs->Array.filterMap(x => x))
  }
}

external unsafeMergeJson: (@as(json`{}`) _, Js.Json.t, Js.Json.t) => Js.Json.t = "Object.assign"

module GraphQLIncrementalResponse = {
  type t<'a> = {incremental: array<'a>, hasNext: bool}
}

module GraphQLResponse = {
  type data = {.}
  type t<'a> = Incremental(GraphQLIncrementalResponse.t<'a>) | Response('a)

  let mapIncrementalWithDefault: (
    t<'a>,
    GraphQLIncrementalResponse.t<'a> => array<'b>,
    'a => array<'b>,
  ) => array<'b> = (t, withIncremental, default) => {
    switch t {
    | Incremental(incremental) => withIncremental(incremental)
    | Response(json) => default(json)
    }
  }
  let fromIncremental = data => Incremental(data)
  let makeResponse = data => Response(data)

  // Use parser to parse fully type-safe response
  let parse:
    type a. (Js.Json.t, Js.Json.t => option<a>) => option<t<a>> =
    (json, parseFn) =>
      switch json->Js.Json.decodeObject {
      | Some(dict) =>
        switch dict->Js.Dict.get("incremental") {
        | Some(data) =>
          switch data->Js.Json.decodeArray {
          | Some(arrayData) =>
            arrayData
            ->Array.map(parseFn)
            ->OptionArray.sequence
            ->Option.flatMap(data => Some(
              Incremental({
                incremental: data,
                hasNext: dict
                ->Js.Dict.get("hasNext")
                ->Option.mapOr(false, v => v->Js.Json.decodeBoolean->Option.mapOr(false, v => v)),
              }),
            ))
          | None => {
              let data = parseFn(json)
              switch data {
              | Some(data) => Some(Response(data))
              | None => None
              }
            }
          }
        | None => {
            let data = parseFn(json)
            switch data {
            | Some(data) => Some(Response(data))
            | None => None
            }
          }
        }
      | None => None
      }

  // Partially parse response
  let fromJson: Js.Json.t => t<'a> = json =>
    switch json->Js.Json.decodeObject {
    | Some(dict) =>
      switch dict->Js.Dict.get("incremental") {
      | Some(data) =>
        switch data->Js.Json.decodeArray {
        | Some(arrayData) =>
          Incremental({
            incremental: arrayData,
            hasNext: dict
            ->Js.Dict.get("hasNext")
            ->Option.mapOr(false, v => v->Js.Json.decodeBoolean->Option.mapOr(false, v => v)),
          })
        | None => Response(json)
        }
      | None => Response(json)
      }
    | None => Response(json)
    }
}

module RelayDeferResponse = {
  type t<'a> = array<'a>

  // Type safe conversion from a GraphQL spec response
  let fromIncrementalResponse: GraphQLIncrementalResponse.t<{..} as 'a> => t<{..} as 'a> = ({
    incremental,
    hasNext,
  }) => {
    incremental->Array.mapWithIndex((data, i) => {
      let hasNext = i === incremental->Array.length - 1 ? hasNext : true

      Object.assign(data, {"hasNext": hasNext, "extensions": {"is_final": !hasNext}})
    })
  }

  external toJson: 'a => Js.Json.t = "%identity"

  // Not type safe conversion due to use of Json.t and object merging
  let fromJsonIncrementalResponse: GraphQLIncrementalResponse.t<Js.Json.t> => array<Js.Json.t> = ({
    incremental,
    hasNext,
  }) => {
    incremental->Array.mapWithIndex((data, i) => {
      let hasNext = i === incremental->Array.length - 1 ? hasNext : true

      unsafeMergeJson(data, {"hasNext": hasNext, "extensions": {"is_final": !hasNext}}->toJson)
    })
  }
}

// Not type safe conversion of GraphQL spec defer response to Relay-compatible
// version
let adaptJsonIncrementalResponseToRelay: Js.Json.t => array<Js.Json.t> = part =>
  part
  ->GraphQLResponse.fromJson
  ->GraphQLResponse.mapIncrementalWithDefault(
    RelayDeferResponse.fromJsonIncrementalResponse,
    part => [part],
  )

/* type test = {
  test: bool
}
let adaptIncrementalResponseToRelay: Js.Json.t => option<array<{.. } as 'a>> = part =>
  part
  ->GraphQLResponse.parse(json => Some({"test": true}))
  ->Option.map(GraphQLResponse.mapIncrementalWithDefault(_,
    x => x->(x => x->RelayDeferResponse.fromIncrementalResponse),
    part => [part],
  )) */

// The client and server fetch query are currently copied, but one could easily
// set them up so that they use the same base, and just take whatever config
// they need.
let makeFetchQuery = () =>
  RelaySSRUtils.makeClientFetchFunction((sink, operation, variables, _cacheConfig, _uploads) => {
    open RelayRouter.NetworkUtils

    fetch(
      dev ? apiEndpoint->Option.getOr("http://localhost:4555/graphql") : "/graphql",
      {
        "method": "POST",
        "credentials": "include",
        "headers": Js.Dict.fromArray([("content-type", "application/json")]),
        "body": {"query": operation.text, "variables": variables}
        ->Js.Json.stringifyAny
        ->Option.getOr(""),
      },
    )
    ->Promise.then(r => {
      r->getChunks(
        ~onNext=part => {
          /* part->preloadFromResponse(~preloadAsset) */
          part->adaptJsonIncrementalResponseToRelay->Array.map(sink.next)->ignore
        },
        ~onError=err => {
          sink.error(err)
        },
        ~onComplete=() => {
          sink.complete()
        },
      )
    })
    ->ignore

    None
  })

// The SSR fetch forwards the user's session cookie to the backend, which may
// respond with a refreshed session cookie (sliding expiry). Copy any
// Set-Cookie headers onto the Express response so they reach the browser
// instead of being silently dropped with the rest of the response headers.
module ExpressResponse = {
  type t
  @get external headersSent: t => bool = "headersSent"
  @send external append: (t, string, string) => unit = "append"
}

// @remix-run/web-fetch's Headers has the non-standard getAll() instead of the
// standard getSetCookie(); support both in case the fetch impl changes.
let getSetCookies: RelayRouter.NetworkUtils.response => array<string> = %raw(`function (r) {
  const headers = r.headers;
  if (typeof headers.getSetCookie === "function") return headers.getSetCookie();
  if (typeof headers.getAll === "function") return headers.getAll("set-cookie");
  const single = headers.get("set-cookie");
  return single ? [single] : [];
}`)

let forwardSetCookies = (r, expressResponse) =>
  if !(expressResponse->ExpressResponse.headersSent) {
    r
    ->getSetCookies
    ->Array.forEach(cookie => expressResponse->ExpressResponse.append("Set-Cookie", cookie))
  }

let makeServerFetchQuery = (
  ~onQuery,
  ~headers: Js.Dict.t<string>,
  ~expressResponse: ExpressResponse.t,
): /* ~preloadAsset, */
RescriptRelay.Network.fetchFunctionObservable => {
  RelaySSRUtils.makeServerFetchFunction(onQuery, (
    sink,
    operation,
    variables,
    _cacheConfig,
    _uploads,
  ) => {
    open RelayRouter.NetworkUtils

    fetchServer(
      serverApiEndpoint(),
      {
        "mode": "no-cors",
        "method": "POST",
        "headers": Js.Dict.fromArray(
          headers->Js.Dict.entries->Array.concat([("content-type", "application/json")]),
        ),
        "body": {"query": operation.text, "variables": variables}
        ->Js.Json.stringifyAny
        ->Option.getOr(""),
      },
    )
    ->Promise.then(r => {
      r->forwardSetCookies(expressResponse)
      r->getChunks(
        ~onNext=part => {
          /* part->preloadFromResponse(~preloadAsset) */
          part->adaptJsonIncrementalResponseToRelay->Array.map(sink.next)->ignore
        },
        ~onError=err => {
          sink.error(err)
        },
        ~onComplete=() => {
          sink.complete()
        },
      )
    })
    ->Promise.catch(e => {
      Promise.resolve(e->Js.Exn.asJsExn->Option.map(sink.error)->ignore)
    })
    ->ignore

    None
  })
}

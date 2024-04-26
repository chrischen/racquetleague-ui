/* @sourceLoc CreateLocationEventPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_location = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #CreateLocationEvent_location]>,
  }
  type response = {
    location: option<response_location>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #CreateLocationEvent_activities]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    locationId: string,
  }
  @live
  type refetchVariables = {
    locationId: option<string>,
  }
  @live let makeRefetchVariables = (
    ~locationId=?,
  ): refetchVariables => {
    locationId: locationId
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{}`
  )
  @live
  let variablesConverterMap = ()
  @live
  let convertVariables = v => v->RescriptRelay.convertObj(
    variablesConverter,
    variablesConverterMap,
    Js.undefined
  )
  @live
  type wrapResponseRaw
  @live
  let wrapResponseConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"location":{"f":""},"":{"f":""}}}`
  )
  @live
  let wrapResponseConverterMap = ()
  @live
  let convertWrapResponse = v => v->RescriptRelay.convertObj(
    wrapResponseConverter,
    wrapResponseConverterMap,
    Js.null
  )
  @live
  type responseRaw
  @live
  let responseConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"location":{"f":""},"":{"f":""}}}`
  )
  @live
  let responseConverterMap = ()
  @live
  let convertResponse = v => v->RescriptRelay.convertObj(
    responseConverter,
    responseConverterMap,
    Js.undefined
  )
  type wrapRawResponseRaw = wrapResponseRaw
  @live
  let convertWrapRawResponse = convertWrapResponse
  type rawResponseRaw = responseRaw
  @live
  let convertRawResponse = convertResponse
  type rawPreloadToken<'response> = {source: Js.Nullable.t<RescriptRelay.Observable.t<'response>>}
  external tokenToRaw: queryRef => rawPreloadToken<Types.response> = "%identity"
}
module Utils = {
  @@warning("-33")
  open Types
}

type relayOperationNode
type operationType = RescriptRelay.queryNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "locationId"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "locationId"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "CreateLocationEventPageQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "Location",
        "kind": "LinkedField",
        "name": "location",
        "plural": false,
        "selections": [
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "CreateLocationEvent_location"
          }
        ],
        "storageKey": null
      },
      {
        "args": null,
        "kind": "FragmentSpread",
        "name": "CreateLocationEvent_activities"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "CreateLocationEventPageQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "Location",
        "kind": "LinkedField",
        "name": "location",
        "plural": false,
        "selections": [
          (v2/*: any*/),
          (v3/*: any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "details",
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Activity",
        "kind": "LinkedField",
        "name": "activities",
        "plural": true,
        "selections": [
          (v2/*: any*/),
          (v3/*: any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "slug",
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "9b2de24ae038c3d2dd4a4b2ecc905eca",
    "id": null,
    "metadata": {},
    "name": "CreateLocationEventPageQuery",
    "operationKind": "query",
    "text": "query CreateLocationEventPageQuery(\n  $locationId: ID!\n) {\n  location(id: $locationId) {\n    ...CreateLocationEvent_location\n    id\n  }\n  ...CreateLocationEvent_activities\n}\n\nfragment CreateLocationEvent_activities on Query {\n  activities {\n    id\n    name\n    slug\n  }\n}\n\nfragment CreateLocationEvent_location on Location {\n  id\n  name\n  details\n}\n"
  }
};
})() `)

let load: (
  ~environment: RescriptRelay.Environment.t,
  ~variables: Types.variables,
  ~fetchPolicy: RescriptRelay.fetchPolicy=?,
  ~fetchKey: string=?,
  ~networkCacheConfig: RescriptRelay.cacheConfig=?,
) => queryRef = (
  ~environment,
  ~variables,
  ~fetchPolicy=?,
  ~fetchKey=?,
  ~networkCacheConfig=?,
) =>
  RescriptRelay.loadQuery(
    environment,
    node,
    variables->Internal.convertVariables,
    {
      fetchKey,
      fetchPolicy,
      networkCacheConfig,
    },
  )
  
let queryRefToObservable = token => {
  let raw = token->Internal.tokenToRaw
  raw.source->Js.Nullable.toOption
}
  
let queryRefToPromise = token => {
  Js.Promise.make((~resolve, ~reject as _) => {
    switch token->queryRefToObservable {
    | None => resolve(Error())
    | Some(o) =>
      open RescriptRelay.Observable
      let _: subscription = o->subscribe(makeObserver(~complete=() => resolve(Ok())))
    }
  })
}

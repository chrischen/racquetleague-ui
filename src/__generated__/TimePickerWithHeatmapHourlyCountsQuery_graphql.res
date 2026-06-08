/* @sourceLoc TimePickerWithHeatmap.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_availabilityHourlyCounts = {
    count: int,
    hour: int,
  }
  type response = {
    availabilityHourlyCounts: array<response_availabilityHourlyCounts>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activityId: string,
    clubId?: string,
    localDate: string,
  }
  @live
  type refetchVariables = {
    activityId: option<string>,
    clubId: option<option<string>>,
    localDate: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activityId=?,
    ~clubId=?,
    ~localDate=?,
  ): refetchVariables => {
    activityId: activityId,
    clubId: clubId,
    localDate: localDate
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
    json`{}`
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
    json`{}`
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
var v0 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "activityId"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "clubId"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "localDate"
},
v3 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "activityId",
        "variableName": "activityId"
      },
      {
        "kind": "Variable",
        "name": "clubId",
        "variableName": "clubId"
      },
      {
        "kind": "Variable",
        "name": "localDate",
        "variableName": "localDate"
      }
    ],
    "concreteType": "AvailabilityHourCount",
    "kind": "LinkedField",
    "name": "availabilityHourlyCounts",
    "plural": true,
    "selections": [
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "hour",
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "count",
        "storageKey": null
      }
    ],
    "storageKey": null
  }
];
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "TimePickerWithHeatmapHourlyCountsQuery",
    "selections": (v3/*: any*/),
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v2/*: any*/),
      (v0/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Operation",
    "name": "TimePickerWithHeatmapHourlyCountsQuery",
    "selections": (v3/*: any*/)
  },
  "params": {
    "cacheID": "b09fe127ffbddcb6afe78ffd64ae8925",
    "id": null,
    "metadata": {},
    "name": "TimePickerWithHeatmapHourlyCountsQuery",
    "operationKind": "query",
    "text": "query TimePickerWithHeatmapHourlyCountsQuery(\n  $localDate: String!\n  $activityId: ID!\n  $clubId: ID\n) {\n  availabilityHourlyCounts(localDate: $localDate, activityId: $activityId, clubId: $clubId) {\n    hour\n    count\n  }\n}\n"
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

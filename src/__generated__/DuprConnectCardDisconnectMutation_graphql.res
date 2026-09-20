/* @sourceLoc DuprConnectCard.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_disconnectDupr_errors = {
    message: string,
  }
  @live
  and response_disconnectDupr_viewer_dupr = {
    doubles: option<float>,
    doublesReliable: bool,
    duprId: string,
    singles: option<float>,
    singlesReliable: bool,
    syncedAt: option<Util.Datetime.t>,
  }
  @live
  and response_disconnectDupr_viewer = {
    dupr: option<response_disconnectDupr_viewer_dupr>,
    @live id: string,
  }
  @live
  and response_disconnectDupr = {
    errors: option<array<response_disconnectDupr_errors>>,
    viewer: option<response_disconnectDupr_viewer>,
  }
  @live
  type response = {
    disconnectDupr: response_disconnectDupr,
  }
  @live
  type rawResponse = response
  @live
  type variables = unit
}

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
    json`{"__root":{"disconnectDupr_viewer_dupr_syncedAt":{"c":"Util.Datetime"}}}`
  )
  @live
  let wrapResponseConverterMap = {
    "Util.Datetime": Util.Datetime.serialize,
  }
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
    json`{"__root":{"disconnectDupr_viewer_dupr_syncedAt":{"c":"Util.Datetime"}}}`
  )
  @live
  let responseConverterMap = {
    "Util.Datetime": Util.Datetime.parse,
  }
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
}
module Utils = {
  @@warning("-33")
  open Types
}

type relayOperationNode
type operationType = RescriptRelay.mutationNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "alias": null,
    "args": null,
    "concreteType": "DuprResult",
    "kind": "LinkedField",
    "name": "disconnectDupr",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "User",
        "kind": "LinkedField",
        "name": "viewer",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "id",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "DuprLink",
            "kind": "LinkedField",
            "name": "dupr",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "duprId",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "doubles",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "singles",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "doublesReliable",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "singlesReliable",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "syncedAt",
                "storageKey": null
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Error",
        "kind": "LinkedField",
        "name": "errors",
        "plural": true,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "message",
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "storageKey": null
  }
];
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "DuprConnectCardDisconnectMutation",
    "selections": (v0/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "DuprConnectCardDisconnectMutation",
    "selections": (v0/*: any*/)
  },
  "params": {
    "cacheID": "580c43d6d5b00cc0a03da4bd6aca9401",
    "id": null,
    "metadata": {},
    "name": "DuprConnectCardDisconnectMutation",
    "operationKind": "mutation",
    "text": "mutation DuprConnectCardDisconnectMutation {\n  disconnectDupr {\n    viewer {\n      id\n      dupr {\n        duprId\n        doubles\n        singles\n        doublesReliable\n        singlesReliable\n        syncedAt\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



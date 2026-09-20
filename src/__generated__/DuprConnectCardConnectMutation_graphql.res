/* @sourceLoc DuprConnectCard.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type connectDuprInput = RelaySchemaAssets_graphql.input_ConnectDuprInput
  @live
  type rec response_connectDupr_errors = {
    message: string,
  }
  @live
  and response_connectDupr_viewer_dupr = {
    doubles: option<float>,
    doublesReliable: bool,
    duprId: string,
    singles: option<float>,
    singlesReliable: bool,
    syncedAt: option<Util.Datetime.t>,
  }
  @live
  and response_connectDupr_viewer = {
    dupr: option<response_connectDupr_viewer_dupr>,
    @live id: string,
  }
  @live
  and response_connectDupr = {
    errors: option<array<response_connectDupr_errors>>,
    viewer: option<response_connectDupr_viewer>,
  }
  @live
  type response = {
    connectDupr: response_connectDupr,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: connectDuprInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"connectDuprInput":{},"__root":{"input":{"r":"connectDuprInput"}}}`
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
    json`{"__root":{"connectDupr_viewer_dupr_syncedAt":{"c":"Util.Datetime"}}}`
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
    json`{"__root":{"connectDupr_viewer_dupr_syncedAt":{"c":"Util.Datetime"}}}`
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
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "input"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "input",
        "variableName": "input"
      }
    ],
    "concreteType": "DuprResult",
    "kind": "LinkedField",
    "name": "connectDupr",
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
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "DuprConnectCardConnectMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "DuprConnectCardConnectMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "e95293bcca2f229f7a6b88bb309617bc",
    "id": null,
    "metadata": {},
    "name": "DuprConnectCardConnectMutation",
    "operationKind": "mutation",
    "text": "mutation DuprConnectCardConnectMutation(\n  $input: ConnectDuprInput!\n) {\n  connectDupr(input: $input) {\n    viewer {\n      id\n      dupr {\n        duprId\n        doubles\n        singles\n        doublesReliable\n        singlesReliable\n        syncedAt\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



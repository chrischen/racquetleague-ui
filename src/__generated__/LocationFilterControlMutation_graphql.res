/* @sourceLoc LocationFilterControl.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type updateViewerLocationInput = RelaySchemaAssets_graphql.input_UpdateViewerLocationInput
  @live
  type rec response_updateViewerLocation_errors = {
    message: string,
  }
  @live
  and response_updateViewerLocation_viewer_coords = {
    lat: float,
    lng: float,
  }
  @live
  and response_updateViewerLocation_viewer = {
    coords: option<response_updateViewerLocation_viewer_coords>,
    @live id: string,
  }
  @live
  and response_updateViewerLocation = {
    errors: option<array<response_updateViewerLocation_errors>>,
    viewer: option<response_updateViewerLocation_viewer>,
  }
  @live
  type response = {
    updateViewerLocation: response_updateViewerLocation,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: updateViewerLocationInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"updateViewerLocationInput":{},"__root":{"input":{"r":"updateViewerLocationInput"}}}`
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
    "concreteType": "UpdateViewerLocationResult",
    "kind": "LinkedField",
    "name": "updateViewerLocation",
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
            "concreteType": "Coords",
            "kind": "LinkedField",
            "name": "coords",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "lat",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "lng",
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
    "name": "LocationFilterControlMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "LocationFilterControlMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "94381994496ed83e69d4b4fdb371210a",
    "id": null,
    "metadata": {},
    "name": "LocationFilterControlMutation",
    "operationKind": "mutation",
    "text": "mutation LocationFilterControlMutation(\n  $input: UpdateViewerLocationInput!\n) {\n  updateViewerLocation(input: $input) {\n    viewer {\n      id\n      coords {\n        lat\n        lng\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



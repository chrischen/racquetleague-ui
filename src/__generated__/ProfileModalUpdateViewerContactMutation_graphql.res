/* @sourceLoc ProfileModal.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type updateViewerContactInput = RelaySchemaAssets_graphql.input_UpdateViewerContactInput
  @live
  type rec response_updateViewerContact_errors = {
    message: string,
  }
  @live
  and response_updateViewerContact_viewer = {
    email: option<string>,
    @live id: string,
    lineUsername: option<string>,
  }
  @live
  and response_updateViewerContact = {
    errors: option<array<response_updateViewerContact_errors>>,
    viewer: option<response_updateViewerContact_viewer>,
  }
  @live
  type response = {
    updateViewerContact: response_updateViewerContact,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: updateViewerContactInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"updateViewerContactInput":{},"__root":{"input":{"r":"updateViewerContactInput"}}}`
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
    "concreteType": "UpdateViewerContactResult",
    "kind": "LinkedField",
    "name": "updateViewerContact",
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
            "kind": "ScalarField",
            "name": "lineUsername",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "email",
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
    "name": "ProfileModalUpdateViewerContactMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ProfileModalUpdateViewerContactMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "7bc335d7063e6484600dc4c9603933fa",
    "id": null,
    "metadata": {},
    "name": "ProfileModalUpdateViewerContactMutation",
    "operationKind": "mutation",
    "text": "mutation ProfileModalUpdateViewerContactMutation(\n  $input: UpdateViewerContactInput!\n) {\n  updateViewerContact(input: $input) {\n    viewer {\n      id\n      lineUsername\n      email\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



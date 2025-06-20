/* @sourceLoc EventRsvps.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type updateViewerRsvpMessageInput = RelaySchemaAssets_graphql.input_UpdateViewerRsvpMessageInput
  @live
  type rec response_updateViewerRsvpMessage = {
    @live id: string,
    message: option<string>,
  }
  @live
  type response = {
    updateViewerRsvpMessage: option<response_updateViewerRsvpMessage>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: updateViewerRsvpMessageInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"updateViewerRsvpMessageInput":{},"__root":{"input":{"r":"updateViewerRsvpMessageInput"}}}`
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
    "concreteType": "Rsvp",
    "kind": "LinkedField",
    "name": "updateViewerRsvpMessage",
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
        "name": "message",
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
    "name": "EventRsvpsUpdateMessageMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "EventRsvpsUpdateMessageMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "e385412953d44b93bffd2fd2aa804791",
    "id": null,
    "metadata": {},
    "name": "EventRsvpsUpdateMessageMutation",
    "operationKind": "mutation",
    "text": "mutation EventRsvpsUpdateMessageMutation(\n  $input: UpdateViewerRsvpMessageInput!\n) {\n  updateViewerRsvpMessage(input: $input) {\n    id\n    message\n  }\n}\n"
  }
};
})() `)



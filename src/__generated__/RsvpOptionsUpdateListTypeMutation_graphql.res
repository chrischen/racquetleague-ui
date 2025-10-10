/* @sourceLoc RsvpOptions.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type updateRsvpListTypeInput = RelaySchemaAssets_graphql.input_UpdateRsvpListTypeInput
  @live
  type rec response_updateRsvpListType_errors = {
    message: string,
  }
  @live
  and response_updateRsvpListType_rsvp = {
    @live id: string,
    listType: option<int>,
  }
  @live
  and response_updateRsvpListType = {
    errors: option<array<response_updateRsvpListType_errors>>,
    rsvp: option<response_updateRsvpListType_rsvp>,
  }
  @live
  type response = {
    updateRsvpListType: response_updateRsvpListType,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: updateRsvpListTypeInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"updateRsvpListTypeInput":{},"__root":{"input":{"r":"updateRsvpListTypeInput"}}}`
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
    "concreteType": "UpdateRsvpListTypeResult",
    "kind": "LinkedField",
    "name": "updateRsvpListType",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Rsvp",
        "kind": "LinkedField",
        "name": "rsvp",
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
            "name": "listType",
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
    "name": "RsvpOptionsUpdateListTypeMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "RsvpOptionsUpdateListTypeMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "a05056ba9d767e9753558a69298c82ad",
    "id": null,
    "metadata": {},
    "name": "RsvpOptionsUpdateListTypeMutation",
    "operationKind": "mutation",
    "text": "mutation RsvpOptionsUpdateListTypeMutation(\n  $input: UpdateRsvpListTypeInput!\n) {\n  updateRsvpListType(input: $input) {\n    rsvp {\n      id\n      listType\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



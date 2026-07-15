/* @sourceLoc CreateEventsButton.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type autocompleteLocationInput = RelaySchemaAssets_graphql.input_AutocompleteLocationInput
  @live
  type rec response_autocompleteLocation_location = {
    @live id: string,
  }
  @live
  and response_autocompleteLocation = {
    location: option<response_autocompleteLocation_location>,
  }
  @live
  type response = {
    autocompleteLocation: response_autocompleteLocation,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: autocompleteLocationInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"autocompleteLocationInput":{},"__root":{"input":{"r":"autocompleteLocationInput"}}}`
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
    "concreteType": "MutationResult",
    "kind": "LinkedField",
    "name": "autocompleteLocation",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Location",
        "kind": "LinkedField",
        "name": "location",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "id",
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
    "name": "CreateEventsButtonAutocompleteLocationMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "CreateEventsButtonAutocompleteLocationMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "307dc1bb6b38506ceb99d60882212310",
    "id": null,
    "metadata": {},
    "name": "CreateEventsButtonAutocompleteLocationMutation",
    "operationKind": "mutation",
    "text": "mutation CreateEventsButtonAutocompleteLocationMutation(\n  $input: AutocompleteLocationInput!\n) {\n  autocompleteLocation(input: $input) {\n    location {\n      id\n    }\n  }\n}\n"
  }
};
})() `)



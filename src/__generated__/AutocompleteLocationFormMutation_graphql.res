/* @sourceLoc AutocompleteLocation.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type autocompleteLocationInput = RelaySchemaAssets_graphql.input_AutocompleteLocationInput
  @live
  type rec response_autocompleteLocation_location = {
    @live __typename: [ | #Location],
    address: option<string>,
    @live id: string,
    links: option<array<string>>,
    name: option<string>,
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
            "name": "__typename",
            "storageKey": null
          },
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
            "name": "name",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "links",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "address",
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
    "name": "AutocompleteLocationFormMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "AutocompleteLocationFormMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "c8c14bbb1c4d208097f8c780c862c396",
    "id": null,
    "metadata": {},
    "name": "AutocompleteLocationFormMutation",
    "operationKind": "mutation",
    "text": "mutation AutocompleteLocationFormMutation(\n  $input: AutocompleteLocationInput!\n) {\n  autocompleteLocation(input: $input) {\n    location {\n      __typename\n      id\n      name\n      links\n      address\n    }\n  }\n}\n"
  }
};
})() `)



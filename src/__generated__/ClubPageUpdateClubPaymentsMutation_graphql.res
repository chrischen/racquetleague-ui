/* @sourceLoc ClubPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type updateClubInput = RelaySchemaAssets_graphql.input_UpdateClubInput
  @live
  type rec response_updateClub_club = {
    exemptMembersFromPayment: bool,
    @live id: string,
  }
  @live
  and response_updateClub_errors = {
    message: string,
  }
  @live
  and response_updateClub = {
    club: option<response_updateClub_club>,
    errors: option<array<response_updateClub_errors>>,
  }
  @live
  type response = {
    updateClub: response_updateClub,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: updateClubInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"updateClubInput":{},"__root":{"input":{"r":"updateClubInput"}}}`
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
    "concreteType": "UpdateClubResult",
    "kind": "LinkedField",
    "name": "updateClub",
    "plural": false,
    "selections": [
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
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
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
            "name": "exemptMembersFromPayment",
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
    "name": "ClubPageUpdateClubPaymentsMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ClubPageUpdateClubPaymentsMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "82932ab00044aa57b86c01ecf74895f6",
    "id": null,
    "metadata": {},
    "name": "ClubPageUpdateClubPaymentsMutation",
    "operationKind": "mutation",
    "text": "mutation ClubPageUpdateClubPaymentsMutation(\n  $input: UpdateClubInput!\n) {\n  updateClub(input: $input) {\n    errors {\n      message\n    }\n    club {\n      id\n      exemptMembersFromPayment\n    }\n  }\n}\n"
  }
};
})() `)



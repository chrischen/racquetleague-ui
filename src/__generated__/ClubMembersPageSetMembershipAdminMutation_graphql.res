/* @sourceLoc ClubMembersPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type setMembershipAdminInput = RelaySchemaAssets_graphql.input_SetMembershipAdminInput
  @live
  type rec response_setMembershipAdmin_errors = {
    message: string,
  }
  @live
  and response_setMembershipAdmin_membership = {
    @live id: string,
    isAdmin: option<bool>,
  }
  @live
  and response_setMembershipAdmin = {
    errors: option<array<response_setMembershipAdmin_errors>>,
    membership: option<response_setMembershipAdmin_membership>,
  }
  @live
  type response = {
    setMembershipAdmin: response_setMembershipAdmin,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: setMembershipAdminInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"setMembershipAdminInput":{},"__root":{"input":{"r":"setMembershipAdminInput"}}}`
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
    "concreteType": "SetMembershipAdminResult",
    "kind": "LinkedField",
    "name": "setMembershipAdmin",
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
        "concreteType": "Membership",
        "kind": "LinkedField",
        "name": "membership",
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
            "name": "isAdmin",
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
    "name": "ClubMembersPageSetMembershipAdminMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ClubMembersPageSetMembershipAdminMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "811ce49e142bcf5ac0d9d7bac265ca33",
    "id": null,
    "metadata": {},
    "name": "ClubMembersPageSetMembershipAdminMutation",
    "operationKind": "mutation",
    "text": "mutation ClubMembersPageSetMembershipAdminMutation(\n  $input: SetMembershipAdminInput!\n) {\n  setMembershipAdmin(input: $input) {\n    errors {\n      message\n    }\n    membership {\n      id\n      isAdmin\n    }\n  }\n}\n"
  }
};
})() `)



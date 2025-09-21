/* @sourceLoc ClubPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type removeUserFromClubInput = RelaySchemaAssets_graphql.input_RemoveUserFromClubInput
  @live
  type rec response_removeUserFromClub_club_viewerMembership = {
    status: option<RelaySchemaAssets_graphql.enum_T>,
  }
  @live
  and response_removeUserFromClub_club = {
    viewerMembership: option<response_removeUserFromClub_club_viewerMembership>,
  }
  @live
  and response_removeUserFromClub_errors = {
    message: string,
  }
  @live
  and response_removeUserFromClub = {
    club: option<response_removeUserFromClub_club>,
    errors: option<array<response_removeUserFromClub_errors>>,
    membershipIds: option<array<string>>,
  }
  @live
  type response = {
    removeUserFromClub: response_removeUserFromClub,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: removeUserFromClubInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"removeUserFromClubInput":{},"__root":{"input":{"r":"removeUserFromClubInput"}}}`
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
  @live
  external t_toString: RelaySchemaAssets_graphql.enum_T => string = "%identity"
  @live
  external t_input_toString: RelaySchemaAssets_graphql.enum_T_input => string = "%identity"
  @live
  let t_decode = (enum: RelaySchemaAssets_graphql.enum_T): option<RelaySchemaAssets_graphql.enum_T_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let t_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_T_input> => {
    t_decode(Obj.magic(str))
  }
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
    "kind": "Variable",
    "name": "input",
    "variableName": "input"
  }
],
v2 = {
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
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "membershipIds",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "status",
  "storageKey": null
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "ClubPageRemoveUserFromClubMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "CreateClubResult",
        "kind": "LinkedField",
        "name": "removeUserFromClub",
        "plural": false,
        "selections": [
          (v2/*: any*/),
          (v3/*: any*/),
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
                "concreteType": "Membership",
                "kind": "LinkedField",
                "name": "viewerMembership",
                "plural": false,
                "selections": [
                  (v4/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ClubPageRemoveUserFromClubMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "CreateClubResult",
        "kind": "LinkedField",
        "name": "removeUserFromClub",
        "plural": false,
        "selections": [
          (v2/*: any*/),
          (v3/*: any*/),
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
                "concreteType": "Membership",
                "kind": "LinkedField",
                "name": "viewerMembership",
                "plural": false,
                "selections": [
                  (v4/*: any*/),
                  (v5/*: any*/)
                ],
                "storageKey": null
              },
              (v5/*: any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "dfd6cde14777611ba95c77b4d44756ef",
    "id": null,
    "metadata": {},
    "name": "ClubPageRemoveUserFromClubMutation",
    "operationKind": "mutation",
    "text": "mutation ClubPageRemoveUserFromClubMutation(\n  $input: RemoveUserFromClubInput!\n) {\n  removeUserFromClub(input: $input) {\n    errors {\n      message\n    }\n    membershipIds\n    club {\n      viewerMembership {\n        status\n        id\n      }\n      id\n    }\n  }\n}\n"
  }
};
})() `)



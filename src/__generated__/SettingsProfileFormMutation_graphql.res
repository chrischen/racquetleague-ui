/* @sourceLoc SettingsProfileForm.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type updateProfileInput = RelaySchemaAssets_graphql.input_UpdateProfileInput
  @live
  type rec response_updateProfile_errors = {
    message: string,
  }
  @live
  and response_updateProfile_viewer = {
    biography: option<string>,
    fullName: option<string>,
    lineUsername: option<string>,
  }
  @live
  and response_updateProfile = {
    errors: option<array<response_updateProfile_errors>>,
    viewer: option<response_updateProfile_viewer>,
  }
  @live
  type response = {
    updateProfile: response_updateProfile,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: updateProfileInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"updateProfileInput":{},"__root":{"input":{"r":"updateProfileInput"}}}`
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
    "kind": "Variable",
    "name": "input",
    "variableName": "input"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "fullName",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "biography",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v5 = {
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
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "SettingsProfileFormMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "UpdateProfileResult",
        "kind": "LinkedField",
        "name": "updateProfile",
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
              (v2/*: any*/),
              (v3/*: any*/),
              (v4/*: any*/)
            ],
            "storageKey": null
          },
          (v5/*: any*/)
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
    "name": "SettingsProfileFormMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "UpdateProfileResult",
        "kind": "LinkedField",
        "name": "updateProfile",
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
              (v2/*: any*/),
              (v3/*: any*/),
              (v4/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "id",
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v5/*: any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "f1bc27c3bc07f96281642c2824618ccc",
    "id": null,
    "metadata": {},
    "name": "SettingsProfileFormMutation",
    "operationKind": "mutation",
    "text": "mutation SettingsProfileFormMutation(\n  $input: UpdateProfileInput!\n) {\n  updateProfile(input: $input) {\n    viewer {\n      fullName\n      biography\n      lineUsername\n      id\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



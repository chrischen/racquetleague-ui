/* @sourceLoc SubscribeActivity.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type createActivitySubscriptionInput = RelaySchemaAssets_graphql.input_CreateActivitySubscriptionInput
  @live
  type rec response_createActivitySubscription_activity_sub = {
    @live id: string,
  }
  @live
  and response_createActivitySubscription_activity = {
    @live id: string,
    sub: option<response_createActivitySubscription_activity_sub>,
  }
  @live
  and response_createActivitySubscription_errors = {
    message: string,
  }
  @live
  and response_createActivitySubscription = {
    activity: option<response_createActivitySubscription_activity>,
    errors: option<array<response_createActivitySubscription_errors>>,
  }
  @live
  type response = {
    createActivitySubscription: response_createActivitySubscription,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: createActivitySubscriptionInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"createActivitySubscriptionInput":{},"__root":{"input":{"r":"createActivitySubscriptionInput"}}}`
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
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v2 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "input",
        "variableName": "input"
      }
    ],
    "concreteType": "ActivitySubscriptionMutationResult",
    "kind": "LinkedField",
    "name": "createActivitySubscription",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Activity",
        "kind": "LinkedField",
        "name": "activity",
        "plural": false,
        "selections": [
          (v1/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Subscription",
            "kind": "LinkedField",
            "name": "sub",
            "plural": false,
            "selections": [
              (v1/*: any*/)
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
    "name": "SubscribeActivityMutation",
    "selections": (v2/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "SubscribeActivityMutation",
    "selections": (v2/*: any*/)
  },
  "params": {
    "cacheID": "d87fb257e56c060c3bd7a47da3b6ef0d",
    "id": null,
    "metadata": {},
    "name": "SubscribeActivityMutation",
    "operationKind": "mutation",
    "text": "mutation SubscribeActivityMutation(\n  $input: CreateActivitySubscriptionInput!\n) {\n  createActivitySubscription(input: $input) {\n    activity {\n      id\n      sub {\n        id\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



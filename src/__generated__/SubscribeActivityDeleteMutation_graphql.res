/* @sourceLoc SubscribeActivity.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type deleteActivitySubscriptionInput = RelaySchemaAssets_graphql.input_DeleteActivitySubscriptionInput
  @live
  type rec response_deleteActivitySubscription_activity_sub = {
    @live id: string,
  }
  @live
  and response_deleteActivitySubscription_activity = {
    @live id: string,
    sub: option<response_deleteActivitySubscription_activity_sub>,
  }
  @live
  and response_deleteActivitySubscription_errors = {
    message: string,
  }
  @live
  and response_deleteActivitySubscription = {
    activity: option<response_deleteActivitySubscription_activity>,
    errors: option<array<response_deleteActivitySubscription_errors>>,
  }
  @live
  type response = {
    deleteActivitySubscription: response_deleteActivitySubscription,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: deleteActivitySubscriptionInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"deleteActivitySubscriptionInput":{},"__root":{"input":{"r":"deleteActivitySubscriptionInput"}}}`
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
    "name": "deleteActivitySubscription",
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
    "name": "SubscribeActivityDeleteMutation",
    "selections": (v2/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "SubscribeActivityDeleteMutation",
    "selections": (v2/*: any*/)
  },
  "params": {
    "cacheID": "5aef1e6dee08e9dccc7c83bd0d7d3e00",
    "id": null,
    "metadata": {},
    "name": "SubscribeActivityDeleteMutation",
    "operationKind": "mutation",
    "text": "mutation SubscribeActivityDeleteMutation(\n  $input: DeleteActivitySubscriptionInput!\n) {\n  deleteActivitySubscription(input: $input) {\n    activity {\n      id\n      sub {\n        id\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



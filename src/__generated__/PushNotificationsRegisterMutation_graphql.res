/* @sourceLoc PushNotifications.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type registerPushSubscriptionInput = RelaySchemaAssets_graphql.input_RegisterPushSubscriptionInput
  @live
  type rec response_registerPushSubscription_errors = {
    message: string,
  }
  @live
  and response_registerPushSubscription = {
    errors: option<array<response_registerPushSubscription_errors>>,
    success: option<bool>,
  }
  @live
  type response = {
    registerPushSubscription: response_registerPushSubscription,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: registerPushSubscriptionInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"registerPushSubscriptionInput":{},"__root":{"input":{"r":"registerPushSubscriptionInput"}}}`
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
    "concreteType": "PushSubscriptionResult",
    "kind": "LinkedField",
    "name": "registerPushSubscription",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "success",
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
    "name": "PushNotificationsRegisterMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "PushNotificationsRegisterMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "3b4e77dcc85f37e5eb63ca1ce5640ad2",
    "id": null,
    "metadata": {},
    "name": "PushNotificationsRegisterMutation",
    "operationKind": "mutation",
    "text": "mutation PushNotificationsRegisterMutation(\n  $input: RegisterPushSubscriptionInput!\n) {\n  registerPushSubscription(input: $input) {\n    success\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



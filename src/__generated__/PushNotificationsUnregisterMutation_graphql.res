/* @sourceLoc PushNotifications.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_unregisterPushSubscription_errors = {
    message: string,
  }
  @live
  and response_unregisterPushSubscription = {
    errors: option<array<response_unregisterPushSubscription_errors>>,
    success: option<bool>,
  }
  @live
  type response = {
    unregisterPushSubscription: response_unregisterPushSubscription,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    endpoint: string,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{}`
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
    "name": "endpoint"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "endpoint",
        "variableName": "endpoint"
      }
    ],
    "concreteType": "PushSubscriptionResult",
    "kind": "LinkedField",
    "name": "unregisterPushSubscription",
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
    "name": "PushNotificationsUnregisterMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "PushNotificationsUnregisterMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "dc46b85b9bd70620733f18408624a838",
    "id": null,
    "metadata": {},
    "name": "PushNotificationsUnregisterMutation",
    "operationKind": "mutation",
    "text": "mutation PushNotificationsUnregisterMutation(\n  $endpoint: String!\n) {\n  unregisterPushSubscription(endpoint: $endpoint) {\n    success\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



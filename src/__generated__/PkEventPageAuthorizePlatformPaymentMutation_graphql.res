/* @sourceLoc PkEventPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_authorizePlatformRsvpPayment_errors = {
    message: string,
  }
  @live
  and response_authorizePlatformRsvpPayment = {
    clientSecret: option<string>,
    errors: option<array<response_authorizePlatformRsvpPayment_errors>>,
  }
  @live
  type response = {
    authorizePlatformRsvpPayment: response_authorizePlatformRsvpPayment,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    rsvpId: string,
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
    "name": "rsvpId"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "rsvpId",
        "variableName": "rsvpId"
      }
    ],
    "concreteType": "AuthorizePaymentResult",
    "kind": "LinkedField",
    "name": "authorizePlatformRsvpPayment",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "clientSecret",
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
    "name": "PkEventPageAuthorizePlatformPaymentMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "PkEventPageAuthorizePlatformPaymentMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "2a6f57457ff876714636326cc6d8da6b",
    "id": null,
    "metadata": {},
    "name": "PkEventPageAuthorizePlatformPaymentMutation",
    "operationKind": "mutation",
    "text": "mutation PkEventPageAuthorizePlatformPaymentMutation(\n  $rsvpId: ID!\n) {\n  authorizePlatformRsvpPayment(rsvpId: $rsvpId) {\n    clientSecret\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



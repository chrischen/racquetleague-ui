/* @sourceLoc PkRSVPSection.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_captureEventRsvpPayments_errors = {
    message: string,
  }
  @live
  and response_captureEventRsvpPayments_payments = {
    @live id: string,
    status: int,
  }
  @live
  and response_captureEventRsvpPayments = {
    errors: option<array<response_captureEventRsvpPayments_errors>>,
    payments: option<array<response_captureEventRsvpPayments_payments>>,
  }
  @live
  type response = {
    captureEventRsvpPayments: response_captureEventRsvpPayments,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    eventId: string,
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
    "name": "eventId"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "eventId",
        "variableName": "eventId"
      }
    ],
    "concreteType": "CaptureEventPaymentsResult",
    "kind": "LinkedField",
    "name": "captureEventRsvpPayments",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Payment",
        "kind": "LinkedField",
        "name": "payments",
        "plural": true,
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
            "name": "status",
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
    "name": "PkRSVPSectionCaptureAllPaymentsMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "PkRSVPSectionCaptureAllPaymentsMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "97133439c6aaa8a896bf28b98256e8b5",
    "id": null,
    "metadata": {},
    "name": "PkRSVPSectionCaptureAllPaymentsMutation",
    "operationKind": "mutation",
    "text": "mutation PkRSVPSectionCaptureAllPaymentsMutation(\n  $eventId: ID!\n) {\n  captureEventRsvpPayments(eventId: $eventId) {\n    payments {\n      id\n      status\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



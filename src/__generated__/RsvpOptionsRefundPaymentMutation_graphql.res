/* @sourceLoc RsvpOptions.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_refundRsvpPayment_errors = {
    message: string,
  }
  @live
  and response_refundRsvpPayment_payment = {
    @live id: string,
    status: int,
  }
  @live
  and response_refundRsvpPayment = {
    errors: option<array<response_refundRsvpPayment_errors>>,
    payment: option<response_refundRsvpPayment_payment>,
  }
  @live
  type response = {
    refundRsvpPayment: response_refundRsvpPayment,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    paymentId: string,
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
    "name": "paymentId"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "paymentId",
        "variableName": "paymentId"
      }
    ],
    "concreteType": "RefundPaymentResult",
    "kind": "LinkedField",
    "name": "refundRsvpPayment",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Payment",
        "kind": "LinkedField",
        "name": "payment",
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
    "name": "RsvpOptionsRefundPaymentMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "RsvpOptionsRefundPaymentMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "be7687ec3af448c5e7765f629cad2774",
    "id": null,
    "metadata": {},
    "name": "RsvpOptionsRefundPaymentMutation",
    "operationKind": "mutation",
    "text": "mutation RsvpOptionsRefundPaymentMutation(\n  $paymentId: ID!\n) {\n  refundRsvpPayment(paymentId: $paymentId) {\n    payment {\n      id\n      status\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



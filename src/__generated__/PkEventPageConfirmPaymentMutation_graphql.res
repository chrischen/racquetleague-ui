/* @sourceLoc PkEventPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_confirmRsvpPayment_errors = {
    message: string,
  }
  @live
  and response_confirmRsvpPayment_rsvp_payment = {
    @live id: string,
    status: int,
  }
  @live
  and response_confirmRsvpPayment_rsvp = {
    @live id: string,
    listType: option<int>,
    payment: option<response_confirmRsvpPayment_rsvp_payment>,
  }
  @live
  and response_confirmRsvpPayment = {
    errors: option<array<response_confirmRsvpPayment_errors>>,
    rsvp: option<response_confirmRsvpPayment_rsvp>,
  }
  @live
  type response = {
    confirmRsvpPayment: response_confirmRsvpPayment,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    paymentIntentId: string,
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
var v0 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "paymentIntentId"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "rsvpId"
},
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v3 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "paymentIntentId",
        "variableName": "paymentIntentId"
      },
      {
        "kind": "Variable",
        "name": "rsvpId",
        "variableName": "rsvpId"
      }
    ],
    "concreteType": "CreatePaymentResult",
    "kind": "LinkedField",
    "name": "confirmRsvpPayment",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Rsvp",
        "kind": "LinkedField",
        "name": "rsvp",
        "plural": false,
        "selections": [
          (v2/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Payment",
            "kind": "LinkedField",
            "name": "payment",
            "plural": false,
            "selections": [
              (v2/*: any*/),
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
            "kind": "ScalarField",
            "name": "listType",
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
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "PkEventPageConfirmPaymentMutation",
    "selections": (v3/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v1/*: any*/),
      (v0/*: any*/)
    ],
    "kind": "Operation",
    "name": "PkEventPageConfirmPaymentMutation",
    "selections": (v3/*: any*/)
  },
  "params": {
    "cacheID": "4230a1e807e8a0e3cb61522c91351984",
    "id": null,
    "metadata": {},
    "name": "PkEventPageConfirmPaymentMutation",
    "operationKind": "mutation",
    "text": "mutation PkEventPageConfirmPaymentMutation(\n  $rsvpId: ID!\n  $paymentIntentId: String!\n) {\n  confirmRsvpPayment(rsvpId: $rsvpId, paymentIntentId: $paymentIntentId) {\n    rsvp {\n      id\n      payment {\n        id\n        status\n      }\n      listType\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



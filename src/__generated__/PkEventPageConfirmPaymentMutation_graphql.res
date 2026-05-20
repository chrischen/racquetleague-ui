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
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PaymentIndicator_payment]>,
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
    json`{"__root":{"confirmRsvpPayment_rsvp_payment":{"f":""}}}`
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
    json`{"__root":{"confirmRsvpPayment_rsvp_payment":{"f":""}}}`
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
v2 = [
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
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "listType",
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
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "PkEventPageConfirmPaymentMutation",
    "selections": [
      {
        "alias": null,
        "args": (v2/*: any*/),
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
              (v3/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "Payment",
                "kind": "LinkedField",
                "name": "payment",
                "plural": false,
                "selections": [
                  (v3/*: any*/),
                  {
                    "args": null,
                    "kind": "FragmentSpread",
                    "name": "PaymentIndicator_payment"
                  }
                ],
                "storageKey": null
              },
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
    "argumentDefinitions": [
      (v1/*: any*/),
      (v0/*: any*/)
    ],
    "kind": "Operation",
    "name": "PkEventPageConfirmPaymentMutation",
    "selections": [
      {
        "alias": null,
        "args": (v2/*: any*/),
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
              (v3/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "Payment",
                "kind": "LinkedField",
                "name": "payment",
                "plural": false,
                "selections": [
                  (v3/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "status",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "currency",
                    "storageKey": null
                  }
                ],
                "storageKey": null
              },
              (v4/*: any*/)
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
    "cacheID": "3ee98f14f77849c826f9a90c33323894",
    "id": null,
    "metadata": {},
    "name": "PkEventPageConfirmPaymentMutation",
    "operationKind": "mutation",
    "text": "mutation PkEventPageConfirmPaymentMutation(\n  $rsvpId: ID!\n  $paymentIntentId: String!\n) {\n  confirmRsvpPayment(rsvpId: $rsvpId, paymentIntentId: $paymentIntentId) {\n    rsvp {\n      id\n      payment {\n        id\n        ...PaymentIndicator_payment\n      }\n      listType\n    }\n    errors {\n      message\n    }\n  }\n}\n\nfragment PaymentIndicator_payment on Payment {\n  status\n  currency\n}\n"
  }
};
})() `)



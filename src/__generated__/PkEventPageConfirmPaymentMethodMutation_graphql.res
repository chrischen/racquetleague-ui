/* @sourceLoc PkEventPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_confirmRsvpPaymentMethod_errors = {
    message: string,
  }
  @live
  and response_confirmRsvpPaymentMethod_rsvp_payment = {
    chargeable: bool,
    @live id: string,
    status: int,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PaymentIndicator_payment]>,
  }
  @live
  and response_confirmRsvpPaymentMethod_rsvp = {
    @live id: string,
    listType: option<int>,
    payment: option<response_confirmRsvpPaymentMethod_rsvp_payment>,
  }
  @live
  and response_confirmRsvpPaymentMethod = {
    errors: option<array<response_confirmRsvpPaymentMethod_errors>>,
    rsvp: option<response_confirmRsvpPaymentMethod_rsvp>,
  }
  @live
  type response = {
    confirmRsvpPaymentMethod: response_confirmRsvpPaymentMethod,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    rsvpId: string,
    setupIntentId: string,
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
    json`{"__root":{"confirmRsvpPaymentMethod_rsvp_payment":{"f":""}}}`
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
    json`{"__root":{"confirmRsvpPaymentMethod_rsvp_payment":{"f":""}}}`
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
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "setupIntentId"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "rsvpId",
    "variableName": "rsvpId"
  },
  {
    "kind": "Variable",
    "name": "setupIntentId",
    "variableName": "setupIntentId"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "status",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "chargeable",
  "storageKey": null
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "listType",
  "storageKey": null
},
v6 = {
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
    "name": "PkEventPageConfirmPaymentMethodMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "CreatePaymentResult",
        "kind": "LinkedField",
        "name": "confirmRsvpPaymentMethod",
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
                  (v3/*: any*/),
                  (v4/*: any*/),
                  {
                    "args": null,
                    "kind": "FragmentSpread",
                    "name": "PaymentIndicator_payment"
                  }
                ],
                "storageKey": null
              },
              (v5/*: any*/)
            ],
            "storageKey": null
          },
          (v6/*: any*/)
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
    "name": "PkEventPageConfirmPaymentMethodMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "CreatePaymentResult",
        "kind": "LinkedField",
        "name": "confirmRsvpPaymentMethod",
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
                  (v3/*: any*/),
                  (v4/*: any*/),
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
              (v5/*: any*/)
            ],
            "storageKey": null
          },
          (v6/*: any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "7bbdd743229179710853a97bb9302452",
    "id": null,
    "metadata": {},
    "name": "PkEventPageConfirmPaymentMethodMutation",
    "operationKind": "mutation",
    "text": "mutation PkEventPageConfirmPaymentMethodMutation(\n  $rsvpId: ID!\n  $setupIntentId: String!\n) {\n  confirmRsvpPaymentMethod(rsvpId: $rsvpId, setupIntentId: $setupIntentId) {\n    rsvp {\n      id\n      payment {\n        id\n        status\n        chargeable\n        ...PaymentIndicator_payment\n      }\n      listType\n    }\n    errors {\n      message\n    }\n  }\n}\n\nfragment PaymentIndicator_payment on Payment {\n  status\n  currency\n}\n"
  }
};
})() `)



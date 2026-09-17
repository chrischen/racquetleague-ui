/* @sourceLoc PkEventPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_setupRsvpPaymentMethod_errors = {
    message: string,
  }
  @live
  and response_setupRsvpPaymentMethod_payment = {
    chargeable: bool,
    @live id: string,
    status: int,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PaymentIndicator_payment]>,
  }
  @live
  and response_setupRsvpPaymentMethod = {
    clientSecret: option<string>,
    connectedAccountId: option<string>,
    errors: option<array<response_setupRsvpPaymentMethod_errors>>,
    payment: option<response_setupRsvpPaymentMethod_payment>,
  }
  @live
  type response = {
    setupRsvpPaymentMethod: response_setupRsvpPaymentMethod,
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
    json`{"__root":{"setupRsvpPaymentMethod_payment":{"f":""}}}`
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
    json`{"__root":{"setupRsvpPaymentMethod_payment":{"f":""}}}`
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
    "kind": "Variable",
    "name": "rsvpId",
    "variableName": "rsvpId"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "clientSecret",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "connectedAccountId",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "status",
  "storageKey": null
},
v6 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "chargeable",
  "storageKey": null
},
v7 = {
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
    "name": "PkEventPageSetupPaymentMethodMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "AuthorizePaymentResult",
        "kind": "LinkedField",
        "name": "setupRsvpPaymentMethod",
        "plural": false,
        "selections": [
          (v2/*: any*/),
          (v3/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Payment",
            "kind": "LinkedField",
            "name": "payment",
            "plural": false,
            "selections": [
              (v4/*: any*/),
              (v5/*: any*/),
              (v6/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PaymentIndicator_payment"
              }
            ],
            "storageKey": null
          },
          (v7/*: any*/)
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
    "name": "PkEventPageSetupPaymentMethodMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "AuthorizePaymentResult",
        "kind": "LinkedField",
        "name": "setupRsvpPaymentMethod",
        "plural": false,
        "selections": [
          (v2/*: any*/),
          (v3/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Payment",
            "kind": "LinkedField",
            "name": "payment",
            "plural": false,
            "selections": [
              (v4/*: any*/),
              (v5/*: any*/),
              (v6/*: any*/),
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
          (v7/*: any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "d1886fe859d74d598972e3aa24e407c1",
    "id": null,
    "metadata": {},
    "name": "PkEventPageSetupPaymentMethodMutation",
    "operationKind": "mutation",
    "text": "mutation PkEventPageSetupPaymentMethodMutation(\n  $rsvpId: ID!\n) {\n  setupRsvpPaymentMethod(rsvpId: $rsvpId) {\n    clientSecret\n    connectedAccountId\n    payment {\n      id\n      status\n      chargeable\n      ...PaymentIndicator_payment\n    }\n    errors {\n      message\n    }\n  }\n}\n\nfragment PaymentIndicator_payment on Payment {\n  status\n  currency\n}\n"
  }
};
})() `)



/* @sourceLoc ReceivingEmailsCard.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_resendAlternateEmailVerification_errors = {
    message: string,
  }
  @live
  and response_resendAlternateEmailVerification_viewer_alternateEmails = {
    address: string,
    verified: bool,
  }
  @live
  and response_resendAlternateEmailVerification_viewer = {
    alternateEmails: array<response_resendAlternateEmailVerification_viewer_alternateEmails>,
    @live id: string,
  }
  @live
  and response_resendAlternateEmailVerification = {
    errors: option<array<response_resendAlternateEmailVerification_errors>>,
    viewer: option<response_resendAlternateEmailVerification_viewer>,
  }
  @live
  type response = {
    resendAlternateEmailVerification: response_resendAlternateEmailVerification,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    email: string,
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
    "name": "email"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "email",
        "variableName": "email"
      }
    ],
    "concreteType": "AlternateEmailResult",
    "kind": "LinkedField",
    "name": "resendAlternateEmailVerification",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "User",
        "kind": "LinkedField",
        "name": "viewer",
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
            "concreteType": "AlternateEmail",
            "kind": "LinkedField",
            "name": "alternateEmails",
            "plural": true,
            "selections": [
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "address",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "verified",
                "storageKey": null
              }
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
    "name": "ReceivingEmailsCardResendMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ReceivingEmailsCardResendMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "bb479de15653aea7eb0d330342fff838",
    "id": null,
    "metadata": {},
    "name": "ReceivingEmailsCardResendMutation",
    "operationKind": "mutation",
    "text": "mutation ReceivingEmailsCardResendMutation(\n  $email: String!\n) {\n  resendAlternateEmailVerification(email: $email) {\n    viewer {\n      id\n      alternateEmails {\n        address\n        verified\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



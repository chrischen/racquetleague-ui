/* @sourceLoc ReceivingEmailsCard.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_removeAlternateEmail_errors = {
    message: string,
  }
  @live
  and response_removeAlternateEmail_viewer_alternateEmails = {
    address: string,
    verified: bool,
  }
  @live
  and response_removeAlternateEmail_viewer = {
    alternateEmails: array<response_removeAlternateEmail_viewer_alternateEmails>,
    @live id: string,
  }
  @live
  and response_removeAlternateEmail = {
    errors: option<array<response_removeAlternateEmail_errors>>,
    viewer: option<response_removeAlternateEmail_viewer>,
  }
  @live
  type response = {
    removeAlternateEmail: response_removeAlternateEmail,
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
    "name": "removeAlternateEmail",
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
    "name": "ReceivingEmailsCardRemoveMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ReceivingEmailsCardRemoveMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "61d0b21b5c347b13d62a4f2d9eb10467",
    "id": null,
    "metadata": {},
    "name": "ReceivingEmailsCardRemoveMutation",
    "operationKind": "mutation",
    "text": "mutation ReceivingEmailsCardRemoveMutation(\n  $email: String!\n) {\n  removeAlternateEmail(email: $email) {\n    viewer {\n      id\n      alternateEmails {\n        address\n        verified\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



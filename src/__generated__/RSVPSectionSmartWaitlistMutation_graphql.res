/* @sourceLoc RSVPSection.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_smartWaitlist_errors = {
    message: string,
  }
  @live
  and response_smartWaitlist_rsvps = {
    @live id: string,
    joinTime: option<float>,
    listType: option<int>,
  }
  @live
  and response_smartWaitlist = {
    errors: option<array<response_smartWaitlist_errors>>,
    rsvps: option<array<response_smartWaitlist_rsvps>>,
  }
  @live
  type response = {
    smartWaitlist: response_smartWaitlist,
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
    "concreteType": "SmartWaitlistResult",
    "kind": "LinkedField",
    "name": "smartWaitlist",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Rsvp",
        "kind": "LinkedField",
        "name": "rsvps",
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
            "name": "listType",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "joinTime",
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
    "name": "RSVPSectionSmartWaitlistMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "RSVPSectionSmartWaitlistMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "7a8b8b3a671600b6b7c8a2cbb77f0948",
    "id": null,
    "metadata": {},
    "name": "RSVPSectionSmartWaitlistMutation",
    "operationKind": "mutation",
    "text": "mutation RSVPSectionSmartWaitlistMutation(\n  $eventId: ID!\n) {\n  smartWaitlist(eventId: $eventId) {\n    rsvps {\n      id\n      listType\n      joinTime\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



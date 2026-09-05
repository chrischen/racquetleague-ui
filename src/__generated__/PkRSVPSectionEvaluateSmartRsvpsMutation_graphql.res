/* @sourceLoc PkRSVPSection.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_evaluateSmartRsvps_errors = {
    message: string,
  }
  @live
  and response_evaluateSmartRsvps_rsvps = {
    @live id: string,
    joinTime: option<float>,
    listType: option<int>,
  }
  @live
  and response_evaluateSmartRsvps = {
    errors: option<array<response_evaluateSmartRsvps_errors>>,
    rsvps: option<array<response_evaluateSmartRsvps_rsvps>>,
  }
  @live
  type response = {
    evaluateSmartRsvps: response_evaluateSmartRsvps,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    algorithm?: RelaySchemaAssets_graphql.enum_SmartRsvpAlgorithm_input,
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
  @live
  external smartRsvpAlgorithm_toString: RelaySchemaAssets_graphql.enum_SmartRsvpAlgorithm => string = "%identity"
  @live
  external smartRsvpAlgorithm_input_toString: RelaySchemaAssets_graphql.enum_SmartRsvpAlgorithm_input => string = "%identity"
  @live
  let smartRsvpAlgorithm_decode = (enum: RelaySchemaAssets_graphql.enum_SmartRsvpAlgorithm): option<RelaySchemaAssets_graphql.enum_SmartRsvpAlgorithm_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let smartRsvpAlgorithm_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_SmartRsvpAlgorithm_input> => {
    smartRsvpAlgorithm_decode(Obj.magic(str))
  }
}

type relayOperationNode
type operationType = RescriptRelay.mutationNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "algorithm"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "eventId"
},
v2 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "algorithm",
        "variableName": "algorithm"
      },
      {
        "kind": "Variable",
        "name": "eventId",
        "variableName": "eventId"
      }
    ],
    "concreteType": "EvaluateSmartRsvpsResult",
    "kind": "LinkedField",
    "name": "evaluateSmartRsvps",
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
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "PkRSVPSectionEvaluateSmartRsvpsMutation",
    "selections": (v2/*: any*/),
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
    "name": "PkRSVPSectionEvaluateSmartRsvpsMutation",
    "selections": (v2/*: any*/)
  },
  "params": {
    "cacheID": "fc60e5acabb715e670ad073843f68e3a",
    "id": null,
    "metadata": {},
    "name": "PkRSVPSectionEvaluateSmartRsvpsMutation",
    "operationKind": "mutation",
    "text": "mutation PkRSVPSectionEvaluateSmartRsvpsMutation(\n  $eventId: ID!\n  $algorithm: SmartRsvpAlgorithm\n) {\n  evaluateSmartRsvps(eventId: $eventId, algorithm: $algorithm) {\n    rsvps {\n      id\n      listType\n      joinTime\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



/* @sourceLoc PkuruLayout.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type setAvailabilityDayInput = RelaySchemaAssets_graphql.input_SetAvailabilityDayInput
  @live type intervalInput = RelaySchemaAssets_graphql.input_IntervalInput
  @live type locationInput = RelaySchemaAssets_graphql.input_LocationInput
  @live
  type rec response_setAvailabilityDay_day_intervals = {
    endHour: int,
    startHour: int,
  }
  @live
  and response_setAvailabilityDay_day = {
    @live id: string,
    intervals: array<response_setAvailabilityDay_day_intervals>,
    localDate: string,
  }
  @live
  and response_setAvailabilityDay_errors = {
    message: string,
  }
  @live
  and response_setAvailabilityDay = {
    day: option<response_setAvailabilityDay_day>,
    errors: option<array<response_setAvailabilityDay_errors>>,
  }
  @live
  type response = {
    setAvailabilityDay: response_setAvailabilityDay,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: setAvailabilityDayInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"setAvailabilityDayInput":{"location":{"r":"locationInput"},"intervals":{"r":"intervalInput"}},"intervalInput":{},"locationInput":{},"__root":{"input":{"r":"setAvailabilityDayInput"}}}`
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
    "name": "input"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "input",
        "variableName": "input"
      }
    ],
    "concreteType": "SetAvailabilityDayResult",
    "kind": "LinkedField",
    "name": "setAvailabilityDay",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "AvailabilityDay",
        "kind": "LinkedField",
        "name": "day",
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
            "name": "localDate",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "AvailabilityInterval",
            "kind": "LinkedField",
            "name": "intervals",
            "plural": true,
            "selections": [
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "startHour",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "endHour",
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
    "name": "PkuruLayoutSetAvailabilityMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "PkuruLayoutSetAvailabilityMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "703a43a89e97a2fba9c0ef8e4a9094a7",
    "id": null,
    "metadata": {},
    "name": "PkuruLayoutSetAvailabilityMutation",
    "operationKind": "mutation",
    "text": "mutation PkuruLayoutSetAvailabilityMutation(\n  $input: SetAvailabilityDayInput!\n) {\n  setAvailabilityDay(input: $input) {\n    day {\n      id\n      localDate\n      intervals {\n        startHour\n        endHour\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



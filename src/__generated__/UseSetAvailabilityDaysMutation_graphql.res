/* @sourceLoc UseSetAvailabilityDay.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type setAvailabilityDaysInput = RelaySchemaAssets_graphql.input_SetAvailabilityDaysInput
  @live type availabilityDayInput = RelaySchemaAssets_graphql.input_AvailabilityDayInput
  @live type intervalInput = RelaySchemaAssets_graphql.input_IntervalInput
  @live type locationInput = RelaySchemaAssets_graphql.input_LocationInput
  @live type coordsInput = RelaySchemaAssets_graphql.input_CoordsInput
  @live
  type rec response_setAvailabilityDays_days_intervals = {
    endHour: int,
    startHour: int,
  }
  @live
  and response_setAvailabilityDays_days_user = {
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  @live
  and response_setAvailabilityDays_days = {
    @live id: string,
    intervals: array<response_setAvailabilityDays_days_intervals>,
    localDate: string,
    user: option<response_setAvailabilityDays_days_user>,
  }
  @live
  and response_setAvailabilityDays_errors = {
    message: string,
  }
  @live
  and response_setAvailabilityDays = {
    days: option<array<response_setAvailabilityDays_days>>,
    errors: option<array<response_setAvailabilityDays_errors>>,
  }
  @live
  type response = {
    setAvailabilityDays: response_setAvailabilityDays,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    input: setAvailabilityDaysInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"setAvailabilityDaysInput":{"location":{"r":"locationInput"},"days":{"r":"availabilityDayInput"}},"intervalInput":{},"availabilityDayInput":{"intervals":{"r":"intervalInput"}},"coordsInput":{},"locationInput":{"coords":{"r":"coordsInput"}},"__root":{"input":{"r":"setAvailabilityDaysInput"}}}`
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
  external region_toString: RelaySchemaAssets_graphql.enum_Region => string = "%identity"
  @live
  external region_input_toString: RelaySchemaAssets_graphql.enum_Region_input => string = "%identity"
  @live
  let region_decode = (enum: RelaySchemaAssets_graphql.enum_Region): option<RelaySchemaAssets_graphql.enum_Region_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let region_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_Region_input> => {
    region_decode(Obj.magic(str))
  }
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
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v2 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "input",
        "variableName": "input"
      }
    ],
    "concreteType": "SetAvailabilityDaysResult",
    "kind": "LinkedField",
    "name": "setAvailabilityDays",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "AvailabilityDay",
        "kind": "LinkedField",
        "name": "days",
        "plural": true,
        "selections": [
          (v1/*: any*/),
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
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "user",
            "plural": false,
            "selections": [
              (v1/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "picture",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "lineUsername",
                "storageKey": null
              }
            ],
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
    "name": "UseSetAvailabilityDaysMutation",
    "selections": (v2/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "UseSetAvailabilityDaysMutation",
    "selections": (v2/*: any*/)
  },
  "params": {
    "cacheID": "ced7368a82a9d35f7a285cd53df2b2ba",
    "id": null,
    "metadata": {},
    "name": "UseSetAvailabilityDaysMutation",
    "operationKind": "mutation",
    "text": "mutation UseSetAvailabilityDaysMutation(\n  $input: SetAvailabilityDaysInput!\n) {\n  setAvailabilityDays(input: $input) {\n    days {\n      id\n      localDate\n      user {\n        id\n        picture\n        lineUsername\n      }\n      intervals {\n        startHour\n        endHour\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n"
  }
};
})() `)



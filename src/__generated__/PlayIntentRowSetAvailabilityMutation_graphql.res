/* @sourceLoc PlayIntentRow.res */
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
  and response_setAvailabilityDay_day_user = {
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  @live
  and response_setAvailabilityDay_day = {
    @live id: string,
    intervals: array<response_setAvailabilityDay_day_intervals>,
    localDate: string,
    user: option<response_setAvailabilityDay_day_user>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PlayIntentRow_availabilityDay]>,
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
    json`{"__root":{"setAvailabilityDay_day":{"f":""}}}`
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
    json`{"__root":{"setAvailabilityDay_day":{"f":""}}}`
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
    "kind": "Variable",
    "name": "input",
    "variableName": "input"
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
  "name": "localDate",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "concreteType": "User",
  "kind": "LinkedField",
  "name": "user",
  "plural": false,
  "selections": [
    (v2/*: any*/),
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
v5 = {
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
    "name": "PlayIntentRowSetAvailabilityMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
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
                "args": null,
                "kind": "FragmentSpread",
                "name": "PlayIntentRow_availabilityDay"
              },
              (v2/*: any*/),
              (v3/*: any*/),
              (v4/*: any*/),
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
    "name": "PlayIntentRowSetAvailabilityMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
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
              (v2/*: any*/),
              (v3/*: any*/),
              (v5/*: any*/),
              (v4/*: any*/)
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
    "cacheID": "e3c23685620c6d6a6430782d43ab3ab4",
    "id": null,
    "metadata": {},
    "name": "PlayIntentRowSetAvailabilityMutation",
    "operationKind": "mutation",
    "text": "mutation PlayIntentRowSetAvailabilityMutation(\n  $input: SetAvailabilityDayInput!\n) {\n  setAvailabilityDay(input: $input) {\n    day {\n      ...PlayIntentRow_availabilityDay\n      id\n      localDate\n      user {\n        id\n        picture\n        lineUsername\n      }\n      intervals {\n        startHour\n        endHour\n      }\n    }\n    errors {\n      message\n    }\n  }\n}\n\nfragment PlayIntentRow_availabilityDay on AvailabilityDay {\n  id\n  localDate\n  intervals {\n    startHour\n    endHour\n  }\n}\n"
  }
};
})() `)



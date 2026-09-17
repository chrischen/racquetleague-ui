/* @sourceLoc PkEventsAvailabilityDay.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type locationInput = RelaySchemaAssets_graphql.input_LocationInput
  @live type coordsInput = RelaySchemaAssets_graphql.input_CoordsInput
  @live
  type response = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkEventsAvailabilityDay_query]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activityId?: string,
    byLocation?: bool,
    clubSlug?: string,
    fromDate: string,
    location?: locationInput,
    locationId?: string,
    toDate: string,
  }
  @live
  type refetchVariables = {
    activityId: option<option<string>>,
    byLocation: option<option<bool>>,
    clubSlug: option<option<string>>,
    fromDate: option<string>,
    location: option<option<locationInput>>,
    locationId: option<option<string>>,
    toDate: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activityId=?,
    ~byLocation=?,
    ~clubSlug=?,
    ~fromDate=?,
    ~location=?,
    ~locationId=?,
    ~toDate=?,
  ): refetchVariables => {
    activityId: activityId,
    byLocation: byLocation,
    clubSlug: clubSlug,
    fromDate: fromDate,
    location: location,
    locationId: locationId,
    toDate: toDate
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"coordsInput":{},"locationInput":{"coords":{"r":"coordsInput"}},"__root":{"location":{"r":"locationInput"}}}`
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
    json`{"__root":{"":{"f":""}}}`
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
    json`{"__root":{"":{"f":""}}}`
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
  type rawPreloadToken<'response> = {source: Js.Nullable.t<RescriptRelay.Observable.t<'response>>}
  external tokenToRaw: queryRef => rawPreloadToken<Types.response> = "%identity"
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
type operationType = RescriptRelay.queryNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61",
    "kind": "LocalArgument",
    "name": "activityId"
  },
  {
    "defaultValue": false,
    "kind": "LocalArgument",
    "name": "byLocation"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "clubSlug"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "fromDate"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "location"
  },
  {
    "defaultValue": "",
    "kind": "LocalArgument",
    "name": "locationId"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "toDate"
  }
],
v1 = {
  "kind": "Variable",
  "name": "activityId",
  "variableName": "activityId"
},
v2 = {
  "kind": "Variable",
  "name": "clubSlug",
  "variableName": "clubSlug"
},
v3 = {
  "kind": "Variable",
  "name": "fromDate",
  "variableName": "fromDate"
},
v4 = {
  "kind": "Variable",
  "name": "location",
  "variableName": "location"
},
v5 = {
  "kind": "Variable",
  "name": "locationId",
  "variableName": "locationId"
},
v6 = {
  "kind": "Variable",
  "name": "toDate",
  "variableName": "toDate"
},
v7 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "localDate",
  "storageKey": null
},
v9 = {
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
v10 = [
  (v7/*: any*/),
  (v8/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "link",
    "storageKey": null
  },
  {
    "alias": null,
    "args": null,
    "concreteType": "Location",
    "kind": "LinkedField",
    "name": "location",
    "plural": false,
    "selections": [
      (v7/*: any*/),
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "name",
        "storageKey": null
      }
    ],
    "storageKey": null
  },
  (v9/*: any*/),
  {
    "alias": null,
    "args": null,
    "concreteType": "AvailabilityHourStat",
    "kind": "LinkedField",
    "name": "hourly",
    "plural": true,
    "selections": [
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "hour",
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "indoorCount",
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "outdoorCount",
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "priceMin",
        "storageKey": null
      },
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "priceMax",
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
    "name": "PkEventsAvailabilityDayRefetchQuery",
    "selections": [
      {
        "args": [
          (v1/*: any*/),
          {
            "kind": "Variable",
            "name": "byLocation",
            "variableName": "byLocation"
          },
          (v2/*: any*/),
          (v3/*: any*/),
          (v4/*: any*/),
          (v5/*: any*/),
          (v6/*: any*/)
        ],
        "kind": "FragmentSpread",
        "name": "PkEventsAvailabilityDay_query"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "PkEventsAvailabilityDayRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Viewer",
        "kind": "LinkedField",
        "name": "viewer",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "user",
            "plural": false,
            "selections": [
              (v7/*: any*/)
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": [
              (v1/*: any*/),
              (v3/*: any*/),
              (v6/*: any*/)
            ],
            "concreteType": "AvailabilityDay",
            "kind": "LinkedField",
            "name": "availability",
            "plural": true,
            "selections": [
              (v7/*: any*/),
              (v8/*: any*/),
              (v9/*: any*/)
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": [
              {
                "kind": "Literal",
                "name": "_filters",
                "value": {
                  "viewer": true
                }
              },
              {
                "kind": "Literal",
                "name": "first",
                "value": 100
              }
            ],
            "concreteType": "EventConnection",
            "kind": "LinkedField",
            "name": "events",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "EventEdge",
                "kind": "LinkedField",
                "name": "edges",
                "plural": true,
                "selections": [
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "Event",
                    "kind": "LinkedField",
                    "name": "node",
                    "plural": false,
                    "selections": [
                      (v7/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "title",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "startDate",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "endDate",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "timezone",
                        "storageKey": null
                      }
                    ],
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": "events(_filters:{\"viewer\":true},first:100)"
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": [
          (v3/*: any*/),
          (v4/*: any*/),
          {
            "fields": [
              (v1/*: any*/),
              (v2/*: any*/)
            ],
            "kind": "ObjectValue",
            "name": "scope"
          },
          (v6/*: any*/)
        ],
        "concreteType": "AvailabilityDay",
        "kind": "LinkedField",
        "name": "availabilityUsersForDateRange",
        "plural": true,
        "selections": [
          (v7/*: any*/),
          (v8/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "user",
            "plural": false,
            "selections": [
              (v7/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "lineUsername",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "picture",
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v9/*: any*/)
        ],
        "storageKey": null
      },
      {
        "condition": "byLocation",
        "kind": "Condition",
        "passingValue": false,
        "selections": [
          {
            "alias": null,
            "args": [
              (v1/*: any*/),
              (v3/*: any*/),
              (v4/*: any*/),
              (v6/*: any*/)
            ],
            "concreteType": "LocationAvailabilityDay",
            "kind": "LinkedField",
            "name": "locationsAvailability",
            "plural": true,
            "selections": (v10/*: any*/),
            "storageKey": null
          }
        ]
      },
      {
        "condition": "byLocation",
        "kind": "Condition",
        "passingValue": true,
        "selections": [
          {
            "alias": null,
            "args": [
              (v1/*: any*/),
              (v3/*: any*/),
              (v5/*: any*/),
              (v6/*: any*/)
            ],
            "concreteType": "LocationAvailabilityDay",
            "kind": "LinkedField",
            "name": "locationAvailability",
            "plural": true,
            "selections": (v10/*: any*/),
            "storageKey": null
          }
        ]
      }
    ]
  },
  "params": {
    "cacheID": "45c585455c080a817b51bdd89bddbf06",
    "id": null,
    "metadata": {},
    "name": "PkEventsAvailabilityDayRefetchQuery",
    "operationKind": "query",
    "text": "query PkEventsAvailabilityDayRefetchQuery(\n  $activityId: ID = \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\"\n  $byLocation: Boolean = false\n  $clubSlug: String\n  $fromDate: String!\n  $location: LocationInput\n  $locationId: ID = \"\"\n  $toDate: String!\n) {\n  ...PkEventsAvailabilityDay_query_12mbdw\n}\n\nfragment PkEventsAvailabilityDay_query_12mbdw on Query {\n  viewer {\n    user {\n      id\n    }\n    availability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate) {\n      id\n      localDate\n      intervals {\n        startHour\n        endHour\n      }\n      ...PlayIntentRow_availabilityDay\n    }\n    events(first: 100, _filters: {viewer: true}) {\n      edges {\n        node {\n          id\n          title\n          startDate\n          endDate\n          timezone\n        }\n      }\n    }\n  }\n  availabilityUsersForDateRange(fromDate: $fromDate, toDate: $toDate, location: $location, scope: {activityId: $activityId, clubSlug: $clubSlug}) {\n    id\n    localDate\n    user {\n      id\n      lineUsername\n      picture\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n  locationsAvailability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate, location: $location) @skip(if: $byLocation) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n  }\n  locationAvailability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate, locationId: $locationId) @include(if: $byLocation) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n  }\n}\n\nfragment PlayIntentRow_availabilityDay on AvailabilityDay {\n  id\n  localDate\n  intervals {\n    startHour\n    endHour\n  }\n}\n"
  }
};
})() `)

let load: (
  ~environment: RescriptRelay.Environment.t,
  ~variables: Types.variables,
  ~fetchPolicy: RescriptRelay.fetchPolicy=?,
  ~fetchKey: string=?,
  ~networkCacheConfig: RescriptRelay.cacheConfig=?,
) => queryRef = (
  ~environment,
  ~variables,
  ~fetchPolicy=?,
  ~fetchKey=?,
  ~networkCacheConfig=?,
) =>
  RescriptRelay.loadQuery(
    environment,
    node,
    variables->Internal.convertVariables,
    {
      fetchKey,
      fetchPolicy,
      networkCacheConfig,
    },
  )
  
let queryRefToObservable = token => {
  let raw = token->Internal.tokenToRaw
  raw.source->Js.Nullable.toOption
}
  
let queryRefToPromise = token => {
  Js.Promise.make((~resolve, ~reject as _) => {
    switch token->queryRefToObservable {
    | None => resolve(Error())
    | Some(o) =>
      open RescriptRelay.Observable
      let _: subscription = o->subscribe(makeObserver(~complete=() => resolve(Ok())))
    }
  })
}

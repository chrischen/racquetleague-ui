/* @sourceLoc AvailabilityPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type locationInput = RelaySchemaAssets_graphql.input_LocationInput
  @live type coordsInput = RelaySchemaAssets_graphql.input_CoordsInput
  type rec response_availabilityUsersForDateRange_intervals = {
    endHour: int,
    startHour: int,
  }
  and response_availabilityUsersForDateRange_user = {
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and response_availabilityUsersForDateRange = {
    @live id: string,
    intervals: array<response_availabilityUsersForDateRange_intervals>,
    localDate: string,
    user: option<response_availabilityUsersForDateRange_user>,
  }
  and response_locationsAvailability_hourly = {
    hour: int,
    indoorCount: int,
    outdoorCount: int,
    priceMax: option<int>,
    priceMin: option<int>,
  }
  and response_locationsAvailability_intervals = {
    endHour: int,
    startHour: int,
  }
  and response_locationsAvailability_location = {
    @live id: string,
    name: option<string>,
  }
  and response_locationsAvailability = {
    hourly: array<response_locationsAvailability_hourly>,
    @live id: string,
    intervals: array<response_locationsAvailability_intervals>,
    link: option<string>,
    localDate: string,
    location: option<response_locationsAvailability_location>,
  }
  and response_resolvedLocation_coords = {
    lat: float,
    lng: float,
  }
  and response_resolvedLocation = {
    coords: response_resolvedLocation_coords,
    region: option<RelaySchemaAssets_graphql.enum_Region>,
  }
  and response_viewer_availability_intervals = {
    endHour: int,
    startHour: int,
  }
  and response_viewer_availability = {
    @live id: string,
    intervals: array<response_viewer_availability_intervals>,
    localDate: string,
  }
  and response_viewer_events_edges_node = {
    endDate: option<Util.Datetime.t>,
    @live id: string,
    startDate: option<Util.Datetime.t>,
    timezone: option<string>,
    title: option<string>,
  }
  and response_viewer_events_edges = {
    node: option<response_viewer_events_edges_node>,
  }
  and response_viewer_events = {
    edges: option<array<option<response_viewer_events_edges>>>,
  }
  and response_viewer_user = {
    @live id: string,
  }
  and response_viewer = {
    availability: array<response_viewer_availability>,
    events: response_viewer_events,
    user: option<response_viewer_user>,
  }
  type response = {
    availabilityUsersForDateRange: array<response_availabilityUsersForDateRange>,
    locationsAvailability: array<response_locationsAvailability>,
    resolvedLocation: response_resolvedLocation,
    viewer: option<response_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #UseProfileGate_query]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activityId: string,
    afterDate?: Util.Datetime.t,
    fromDate: string,
    location?: locationInput,
    toDate: string,
  }
  @live
  type refetchVariables = {
    activityId: option<string>,
    afterDate: option<option<Util.Datetime.t>>,
    fromDate: option<string>,
    location: option<option<locationInput>>,
    toDate: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activityId=?,
    ~afterDate=?,
    ~fromDate=?,
    ~location=?,
    ~toDate=?,
  ): refetchVariables => {
    activityId: activityId,
    afterDate: afterDate,
    fromDate: fromDate,
    location: location,
    toDate: toDate
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"coordsInput":{},"locationInput":{"coords":{"r":"coordsInput"}},"__root":{"location":{"r":"locationInput"},"afterDate":{"c":"Util.Datetime"}}}`
  )
  @live
  let variablesConverterMap = {
    "Util.Datetime": Util.Datetime.serialize,
  }
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
    json`{"__root":{"viewer_events_edges_node_startDate":{"c":"Util.Datetime"},"viewer_events_edges_node_endDate":{"c":"Util.Datetime"},"":{"f":""}}}`
  )
  @live
  let wrapResponseConverterMap = {
    "Util.Datetime": Util.Datetime.serialize,
  }
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
    json`{"__root":{"viewer_events_edges_node_startDate":{"c":"Util.Datetime"},"viewer_events_edges_node_endDate":{"c":"Util.Datetime"},"":{"f":""}}}`
  )
  @live
  let responseConverterMap = {
    "Util.Datetime": Util.Datetime.parse,
  }
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
var v0 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "activityId"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "afterDate"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "fromDate"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "location"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "toDate"
},
v5 = {
  "kind": "Variable",
  "name": "location",
  "variableName": "location"
},
v6 = {
  "alias": null,
  "args": [
    (v5/*: any*/)
  ],
  "concreteType": "ResolvedLocation",
  "kind": "LinkedField",
  "name": "resolvedLocation",
  "plural": false,
  "selections": [
    {
      "alias": null,
      "args": null,
      "concreteType": "Coords",
      "kind": "LinkedField",
      "name": "coords",
      "plural": false,
      "selections": [
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "lat",
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "lng",
          "storageKey": null
        }
      ],
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "region",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v7 = {
  "kind": "Variable",
  "name": "fromDate",
  "variableName": "fromDate"
},
v8 = {
  "kind": "Variable",
  "name": "toDate",
  "variableName": "toDate"
},
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "localDate",
  "storageKey": null
},
v11 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v12 = {
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
v13 = {
  "alias": null,
  "args": [
    (v7/*: any*/),
    (v5/*: any*/),
    {
      "kind": "Literal",
      "name": "scope",
      "value": {
        "activityId": "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"
      }
    },
    (v8/*: any*/)
  ],
  "concreteType": "AvailabilityDay",
  "kind": "LinkedField",
  "name": "availabilityUsersForDateRange",
  "plural": true,
  "selections": [
    (v9/*: any*/),
    (v10/*: any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "User",
      "kind": "LinkedField",
      "name": "user",
      "plural": false,
      "selections": [
        (v9/*: any*/),
        (v11/*: any*/),
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
    (v12/*: any*/)
  ],
  "storageKey": null
},
v14 = {
  "kind": "Variable",
  "name": "activityId",
  "variableName": "activityId"
},
v15 = {
  "alias": null,
  "args": [
    (v14/*: any*/),
    (v7/*: any*/),
    (v5/*: any*/),
    (v8/*: any*/)
  ],
  "concreteType": "LocationAvailabilityDay",
  "kind": "LinkedField",
  "name": "locationsAvailability",
  "plural": true,
  "selections": [
    (v9/*: any*/),
    (v10/*: any*/),
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
        (v9/*: any*/),
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
    (v12/*: any*/),
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
  ],
  "storageKey": null
},
v16 = [
  (v9/*: any*/)
],
v17 = {
  "alias": null,
  "args": null,
  "concreteType": "User",
  "kind": "LinkedField",
  "name": "user",
  "plural": false,
  "selections": (v16/*: any*/),
  "storageKey": null
},
v18 = {
  "alias": null,
  "args": [
    (v14/*: any*/),
    (v7/*: any*/),
    (v8/*: any*/)
  ],
  "concreteType": "AvailabilityDay",
  "kind": "LinkedField",
  "name": "availability",
  "plural": true,
  "selections": [
    (v9/*: any*/),
    (v10/*: any*/),
    (v12/*: any*/)
  ],
  "storageKey": null
},
v19 = {
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
      "kind": "Variable",
      "name": "afterDate",
      "variableName": "afterDate"
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
            (v9/*: any*/),
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
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "AvailabilityPageQuery",
    "selections": [
      {
        "args": null,
        "kind": "FragmentSpread",
        "name": "UseProfileGate_query"
      },
      (v6/*: any*/),
      (v13/*: any*/),
      (v15/*: any*/),
      {
        "alias": null,
        "args": null,
        "concreteType": "Viewer",
        "kind": "LinkedField",
        "name": "viewer",
        "plural": false,
        "selections": [
          (v17/*: any*/),
          (v18/*: any*/),
          (v19/*: any*/)
        ],
        "storageKey": null
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v2/*: any*/),
      (v4/*: any*/),
      (v1/*: any*/),
      (v3/*: any*/)
    ],
    "kind": "Operation",
    "name": "AvailabilityPageQuery",
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
            "name": "profile",
            "plural": false,
            "selections": [
              (v9/*: any*/),
              (v11/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "email",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "fullName",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "biography",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "gender",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "selfRating",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "DuprLink",
                "kind": "LinkedField",
                "name": "dupr",
                "plural": false,
                "selections": [
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "doubles",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "doublesReliable",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "doublesReliability",
                    "storageKey": null
                  }
                ],
                "storageKey": null
              },
              {
                "alias": null,
                "args": [
                  {
                    "kind": "Literal",
                    "name": "activitySlug",
                    "value": "pickleball"
                  }
                ],
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "rating",
                "plural": false,
                "selections": (v16/*: any*/),
                "storageKey": "rating(activitySlug:\"pickleball\")"
              }
            ],
            "storageKey": null
          },
          (v17/*: any*/),
          (v18/*: any*/),
          (v19/*: any*/)
        ],
        "storageKey": null
      },
      (v6/*: any*/),
      (v13/*: any*/),
      (v15/*: any*/)
    ]
  },
  "params": {
    "cacheID": "a150ab347f909b6ae91a7f2c3ea8cdcb",
    "id": null,
    "metadata": {},
    "name": "AvailabilityPageQuery",
    "operationKind": "query",
    "text": "query AvailabilityPageQuery(\n  $activityId: ID!\n  $fromDate: String!\n  $toDate: String!\n  $afterDate: Datetime\n  $location: LocationInput\n) {\n  ...UseProfileGate_query\n  resolvedLocation(location: $location) {\n    coords {\n      lat\n      lng\n    }\n    region\n  }\n  availabilityUsersForDateRange(fromDate: $fromDate, toDate: $toDate, location: $location, scope: {activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\"}) {\n    id\n    localDate\n    user {\n      id\n      lineUsername\n      picture\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n  locationsAvailability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate, location: $location) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n  }\n  viewer {\n    user {\n      id\n    }\n    availability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate) {\n      id\n      localDate\n      intervals {\n        startHour\n        endHour\n      }\n    }\n    events(first: 100, _filters: {viewer: true}, afterDate: $afterDate) {\n      edges {\n        node {\n          id\n          title\n          startDate\n          endDate\n          timezone\n        }\n      }\n    }\n  }\n}\n\nfragment ProfileModal_viewer on Query {\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      fullName\n      biography\n      gender\n      selfRating\n      dupr {\n        doubles\n        doublesReliable\n        doublesReliability\n      }\n    }\n  }\n}\n\nfragment UseProfileGate_query on Query {\n  ...ProfileModal_viewer\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      biography\n      selfRating\n      dupr {\n        doubles\n        doublesReliable\n        doublesReliability\n      }\n      rating(activitySlug: \"pickleball\") {\n        id\n      }\n    }\n  }\n}\n"
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

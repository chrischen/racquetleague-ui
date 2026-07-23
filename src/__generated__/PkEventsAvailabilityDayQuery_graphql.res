/* @sourceLoc PkEventsAvailabilityDay.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type locationInput = RelaySchemaAssets_graphql.input_LocationInput
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
  and response_locationAvailability_hourly = {
    hour: int,
    indoorCount: int,
    outdoorCount: int,
    priceMax: option<int>,
    priceMin: option<int>,
  }
  and response_locationAvailability_intervals = {
    endHour: int,
    startHour: int,
  }
  and response_locationAvailability_location = {
    @live id: string,
    name: option<string>,
  }
  and response_locationAvailability = {
    hourly: array<response_locationAvailability_hourly>,
    @live id: string,
    intervals: array<response_locationAvailability_intervals>,
    link: option<string>,
    localDate: string,
    location: option<response_locationAvailability_location>,
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
  and response_viewer_availability_intervals = {
    endHour: int,
    startHour: int,
  }
  and response_viewer_availability = {
    @live id: string,
    intervals: array<response_viewer_availability_intervals>,
    localDate: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PlayIntentRow_availabilityDay]>,
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
    locationAvailability: option<array<response_locationAvailability>>,
    locationsAvailability: option<array<response_locationsAvailability>>,
    viewer: option<response_viewer>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activityId: string,
    byLocation: bool,
    fromDate: string,
    location: locationInput,
    locationId: string,
    toDate: string,
  }
  @live
  type refetchVariables = {
    activityId: option<string>,
    byLocation: option<bool>,
    fromDate: option<string>,
    location: option<locationInput>,
    locationId: option<string>,
    toDate: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activityId=?,
    ~byLocation=?,
    ~fromDate=?,
    ~location=?,
    ~locationId=?,
    ~toDate=?,
  ): refetchVariables => {
    activityId: activityId,
    byLocation: byLocation,
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
    json`{"locationInput":{},"__root":{"location":{"r":"locationInput"}}}`
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
    json`{"__root":{"viewer_events_edges_node_startDate":{"c":"Util.Datetime"},"viewer_events_edges_node_endDate":{"c":"Util.Datetime"},"viewer_availability":{"f":""}}}`
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
    json`{"__root":{"viewer_events_edges_node_startDate":{"c":"Util.Datetime"},"viewer_events_edges_node_endDate":{"c":"Util.Datetime"},"viewer_availability":{"f":""}}}`
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
  "name": "byLocation"
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
  "name": "locationId"
},
v5 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "toDate"
},
v6 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "concreteType": "User",
  "kind": "LinkedField",
  "name": "user",
  "plural": false,
  "selections": [
    (v6/*: any*/)
  ],
  "storageKey": null
},
v8 = {
  "kind": "Variable",
  "name": "activityId",
  "variableName": "activityId"
},
v9 = {
  "kind": "Variable",
  "name": "fromDate",
  "variableName": "fromDate"
},
v10 = {
  "kind": "Variable",
  "name": "toDate",
  "variableName": "toDate"
},
v11 = [
  (v8/*: any*/),
  (v9/*: any*/),
  (v10/*: any*/)
],
v12 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "localDate",
  "storageKey": null
},
v13 = {
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
v14 = {
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
            (v6/*: any*/),
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
},
v15 = {
  "kind": "Variable",
  "name": "location",
  "variableName": "location"
},
v16 = {
  "alias": null,
  "args": [
    (v9/*: any*/),
    (v15/*: any*/),
    {
      "fields": [
        (v8/*: any*/)
      ],
      "kind": "ObjectValue",
      "name": "scope"
    },
    (v10/*: any*/)
  ],
  "concreteType": "AvailabilityDay",
  "kind": "LinkedField",
  "name": "availabilityUsersForDateRange",
  "plural": true,
  "selections": [
    (v6/*: any*/),
    (v12/*: any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "User",
      "kind": "LinkedField",
      "name": "user",
      "plural": false,
      "selections": [
        (v6/*: any*/),
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
    (v13/*: any*/)
  ],
  "storageKey": null
},
v17 = [
  (v6/*: any*/),
  (v12/*: any*/),
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
      (v6/*: any*/),
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
  (v13/*: any*/),
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
v18 = {
  "condition": "byLocation",
  "kind": "Condition",
  "passingValue": false,
  "selections": [
    {
      "alias": null,
      "args": [
        (v8/*: any*/),
        (v9/*: any*/),
        (v15/*: any*/),
        (v10/*: any*/)
      ],
      "concreteType": "LocationAvailabilityDay",
      "kind": "LinkedField",
      "name": "locationsAvailability",
      "plural": true,
      "selections": (v17/*: any*/),
      "storageKey": null
    }
  ]
},
v19 = {
  "condition": "byLocation",
  "kind": "Condition",
  "passingValue": true,
  "selections": [
    {
      "alias": null,
      "args": [
        (v8/*: any*/),
        (v9/*: any*/),
        {
          "kind": "Variable",
          "name": "locationId",
          "variableName": "locationId"
        },
        (v10/*: any*/)
      ],
      "concreteType": "LocationAvailabilityDay",
      "kind": "LinkedField",
      "name": "locationAvailability",
      "plural": true,
      "selections": (v17/*: any*/),
      "storageKey": null
    }
  ]
};
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/),
      (v5/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "PkEventsAvailabilityDayQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Viewer",
        "kind": "LinkedField",
        "name": "viewer",
        "plural": false,
        "selections": [
          (v7/*: any*/),
          {
            "alias": null,
            "args": (v11/*: any*/),
            "concreteType": "AvailabilityDay",
            "kind": "LinkedField",
            "name": "availability",
            "plural": true,
            "selections": [
              (v6/*: any*/),
              (v12/*: any*/),
              (v13/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PlayIntentRow_availabilityDay"
              }
            ],
            "storageKey": null
          },
          (v14/*: any*/)
        ],
        "storageKey": null
      },
      (v16/*: any*/),
      (v18/*: any*/),
      (v19/*: any*/)
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v2/*: any*/),
      (v5/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Operation",
    "name": "PkEventsAvailabilityDayQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Viewer",
        "kind": "LinkedField",
        "name": "viewer",
        "plural": false,
        "selections": [
          (v7/*: any*/),
          {
            "alias": null,
            "args": (v11/*: any*/),
            "concreteType": "AvailabilityDay",
            "kind": "LinkedField",
            "name": "availability",
            "plural": true,
            "selections": [
              (v6/*: any*/),
              (v12/*: any*/),
              (v13/*: any*/)
            ],
            "storageKey": null
          },
          (v14/*: any*/)
        ],
        "storageKey": null
      },
      (v16/*: any*/),
      (v18/*: any*/),
      (v19/*: any*/)
    ]
  },
  "params": {
    "cacheID": "88c4628e7a2c8084a175be3b96bb8239",
    "id": null,
    "metadata": {},
    "name": "PkEventsAvailabilityDayQuery",
    "operationKind": "query",
    "text": "query PkEventsAvailabilityDayQuery(\n  $activityId: ID!\n  $fromDate: String!\n  $toDate: String!\n  $location: LocationInput!\n  $locationId: ID!\n  $byLocation: Boolean!\n) {\n  viewer {\n    user {\n      id\n    }\n    availability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate) {\n      id\n      localDate\n      intervals {\n        startHour\n        endHour\n      }\n      ...PlayIntentRow_availabilityDay\n    }\n    events(first: 100, _filters: {viewer: true}) {\n      edges {\n        node {\n          id\n          title\n          startDate\n          endDate\n          timezone\n        }\n      }\n    }\n  }\n  availabilityUsersForDateRange(fromDate: $fromDate, toDate: $toDate, location: $location, scope: {activityId: $activityId}) {\n    id\n    localDate\n    user {\n      id\n      lineUsername\n      picture\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n  locationsAvailability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate, location: $location) @skip(if: $byLocation) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n  }\n  locationAvailability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate, locationId: $locationId) @include(if: $byLocation) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n  }\n}\n\nfragment PlayIntentRow_availabilityDay on AvailabilityDay {\n  id\n  localDate\n  intervals {\n    startHour\n    endHour\n  }\n}\n"
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

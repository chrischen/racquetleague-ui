/* @sourceLoc PkEventsAvailabilityDay.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_availabilityUsersForDateRange_intervals = {
    endHour: int,
    startHour: int,
  }
  and fragment_availabilityUsersForDateRange_user = {
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_availabilityUsersForDateRange = {
    @live id: string,
    intervals: array<fragment_availabilityUsersForDateRange_intervals>,
    localDate: string,
    user: option<fragment_availabilityUsersForDateRange_user>,
  }
  and fragment_locationAvailability_hourly = {
    hour: int,
    indoorCount: int,
    outdoorCount: int,
    priceMax: option<int>,
    priceMin: option<int>,
  }
  and fragment_locationAvailability_intervals = {
    endHour: int,
    startHour: int,
  }
  and fragment_locationAvailability_location = {
    @live id: string,
    name: option<string>,
  }
  and fragment_locationAvailability = {
    hourly: array<fragment_locationAvailability_hourly>,
    @live id: string,
    intervals: array<fragment_locationAvailability_intervals>,
    link: option<string>,
    localDate: string,
    location: option<fragment_locationAvailability_location>,
  }
  and fragment_locationsAvailability_hourly = {
    hour: int,
    indoorCount: int,
    outdoorCount: int,
    priceMax: option<int>,
    priceMin: option<int>,
  }
  and fragment_locationsAvailability_intervals = {
    endHour: int,
    startHour: int,
  }
  and fragment_locationsAvailability_location = {
    @live id: string,
    name: option<string>,
  }
  and fragment_locationsAvailability = {
    hourly: array<fragment_locationsAvailability_hourly>,
    @live id: string,
    intervals: array<fragment_locationsAvailability_intervals>,
    link: option<string>,
    localDate: string,
    location: option<fragment_locationsAvailability_location>,
  }
  and fragment_viewer_availability_intervals = {
    endHour: int,
    startHour: int,
  }
  and fragment_viewer_availability = {
    @live id: string,
    intervals: array<fragment_viewer_availability_intervals>,
    localDate: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PlayIntentRow_availabilityDay]>,
  }
  and fragment_viewer_events_edges_node = {
    endDate: option<Util.Datetime.t>,
    @live id: string,
    startDate: option<Util.Datetime.t>,
    timezone: option<string>,
    title: option<string>,
  }
  and fragment_viewer_events_edges = {
    node: option<fragment_viewer_events_edges_node>,
  }
  and fragment_viewer_events = {
    edges: option<array<option<fragment_viewer_events_edges>>>,
  }
  and fragment_viewer_user_coords = {
    lat: float,
    lng: float,
  }
  and fragment_viewer_user = {
    coords: option<fragment_viewer_user_coords>,
    @live id: string,
  }
  and fragment_viewer = {
    availability: array<fragment_viewer_availability>,
    events: fragment_viewer_events,
    user: option<fragment_viewer_user>,
  }
  type fragment = {
    availabilityUsersForDateRange: array<fragment_availabilityUsersForDateRange>,
    locationAvailability: option<array<fragment_locationAvailability>>,
    locationsAvailability: option<array<fragment_locationsAvailability>>,
    viewer: option<fragment_viewer>,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"viewer_events_edges_node_startDate":{"c":"Util.Datetime"},"viewer_events_edges_node_endDate":{"c":"Util.Datetime"},"viewer_availability":{"f":""}}}`
  )
  @live
  let fragmentConverterMap = {
    "Util.Datetime": Util.Datetime.parse,
  }
  @live
  let convertFragment = v => v->RescriptRelay.convertObj(
    fragmentConverter,
    fragmentConverterMap,
    Js.undefined
  )
}

type t
type fragmentRef
external getFragmentRef:
  RescriptRelay.fragmentRefs<[> | #PkEventsAvailabilityDay_query]> => fragmentRef = "%identity"

module Utils = {
  @@warning("-33")
  open Types
}

type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


%%private(let makeNode = (rescript_graphql_node_PkEventsAvailabilityDayRefetchQuery): operationType => {
  ignore(rescript_graphql_node_PkEventsAvailabilityDayRefetchQuery)
  %raw(json`(function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v1 = {
  "kind": "Variable",
  "name": "activityId",
  "variableName": "activityId"
},
v2 = {
  "kind": "Variable",
  "name": "fromDate",
  "variableName": "fromDate"
},
v3 = {
  "kind": "Variable",
  "name": "toDate",
  "variableName": "toDate"
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "localDate",
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
  "kind": "Variable",
  "name": "location",
  "variableName": "location"
},
v7 = [
  (v0/*: any*/),
  (v4/*: any*/),
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
      (v0/*: any*/),
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
  (v5/*: any*/),
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
  "argumentDefinitions": [
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
      "name": "fromDate"
    },
    {
      "defaultValue": {
        "lat": 35.658581,
        "lng": 139.745438
      },
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
  "kind": "Fragment",
  "metadata": {
    "refetch": {
      "connection": null,
      "fragmentPathInResult": [],
      "operation": rescript_graphql_node_PkEventsAvailabilityDayRefetchQuery
    }
  },
  "name": "PkEventsAvailabilityDay_query",
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
            (v0/*: any*/),
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
            }
          ],
          "storageKey": null
        },
        {
          "alias": null,
          "args": [
            (v1/*: any*/),
            (v2/*: any*/),
            (v3/*: any*/)
          ],
          "concreteType": "AvailabilityDay",
          "kind": "LinkedField",
          "name": "availability",
          "plural": true,
          "selections": [
            (v0/*: any*/),
            (v4/*: any*/),
            (v5/*: any*/),
            {
              "args": null,
              "kind": "FragmentSpread",
              "name": "PlayIntentRow_availabilityDay"
            }
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
                    (v0/*: any*/),
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
        (v2/*: any*/),
        (v6/*: any*/),
        {
          "fields": [
            (v1/*: any*/)
          ],
          "kind": "ObjectValue",
          "name": "scope"
        },
        (v3/*: any*/)
      ],
      "concreteType": "AvailabilityDay",
      "kind": "LinkedField",
      "name": "availabilityUsersForDateRange",
      "plural": true,
      "selections": [
        (v0/*: any*/),
        (v4/*: any*/),
        {
          "alias": null,
          "args": null,
          "concreteType": "User",
          "kind": "LinkedField",
          "name": "user",
          "plural": false,
          "selections": [
            (v0/*: any*/),
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
        (v5/*: any*/)
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
            (v2/*: any*/),
            (v6/*: any*/),
            (v3/*: any*/)
          ],
          "concreteType": "LocationAvailabilityDay",
          "kind": "LinkedField",
          "name": "locationsAvailability",
          "plural": true,
          "selections": (v7/*: any*/),
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
            (v2/*: any*/),
            {
              "kind": "Variable",
              "name": "locationId",
              "variableName": "locationId"
            },
            (v3/*: any*/)
          ],
          "concreteType": "LocationAvailabilityDay",
          "kind": "LinkedField",
          "name": "locationAvailability",
          "plural": true,
          "selections": (v7/*: any*/),
          "storageKey": null
        }
      ]
    }
  ],
  "type": "Query",
  "abstractKey": null
};
})()`)
})
let node: operationType = makeNode(PkEventsAvailabilityDayRefetchQuery_graphql.node)


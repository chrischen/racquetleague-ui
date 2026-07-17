/* @sourceLoc AvailabilityPage.res */
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
  and response_viewer = {
    availability: array<response_viewer_availability>,
    events: response_viewer_events,
  }
  type response = {
    availabilityUsersForDateRange: array<response_availabilityUsersForDateRange>,
    viewer: option<response_viewer>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activityId: string,
    afterDate?: Util.Datetime.t,
    fromDate: string,
    location: locationInput,
    toDate: string,
  }
  @live
  type refetchVariables = {
    activityId: option<string>,
    afterDate: option<option<Util.Datetime.t>>,
    fromDate: option<string>,
    location: option<locationInput>,
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
    json`{"locationInput":{},"__root":{"location":{"r":"locationInput"},"afterDate":{"c":"Util.Datetime"}}}`
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
    json`{"__root":{"viewer_events_edges_node_startDate":{"c":"Util.Datetime"},"viewer_events_edges_node_endDate":{"c":"Util.Datetime"}}}`
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
    json`{"__root":{"viewer_events_edges_node_startDate":{"c":"Util.Datetime"},"viewer_events_edges_node_endDate":{"c":"Util.Datetime"}}}`
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
  "name": "fromDate",
  "variableName": "fromDate"
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
  {
    "alias": null,
    "args": [
      (v5/*: any*/),
      {
        "kind": "Variable",
        "name": "location",
        "variableName": "location"
      },
      {
        "kind": "Literal",
        "name": "scope",
        "value": {
          "activityId": "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"
        }
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
    "alias": null,
    "args": null,
    "concreteType": "Viewer",
    "kind": "LinkedField",
    "name": "viewer",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": [
          {
            "kind": "Variable",
            "name": "activityId",
            "variableName": "activityId"
          },
          (v5/*: any*/),
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
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "AvailabilityPageQuery",
    "selections": (v10/*: any*/),
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
    "selections": (v10/*: any*/)
  },
  "params": {
    "cacheID": "8e131741c34fe0e6ea212bc6873a3c41",
    "id": null,
    "metadata": {},
    "name": "AvailabilityPageQuery",
    "operationKind": "query",
    "text": "query AvailabilityPageQuery(\n  $activityId: ID!\n  $fromDate: String!\n  $toDate: String!\n  $afterDate: Datetime\n  $location: LocationInput!\n) {\n  availabilityUsersForDateRange(fromDate: $fromDate, toDate: $toDate, location: $location, scope: {activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\"}) {\n    id\n    localDate\n    user {\n      id\n      lineUsername\n      picture\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n  viewer {\n    availability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate) {\n      id\n      localDate\n      intervals {\n        startHour\n        endHour\n      }\n    }\n    events(first: 100, _filters: {viewer: true}, afterDate: $afterDate) {\n      edges {\n        node {\n          id\n          title\n          startDate\n          endDate\n          timezone\n        }\n      }\n    }\n  }\n}\n"
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

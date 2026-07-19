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
  and response_locationsAvailability_intervals = {
    endHour: int,
    startHour: int,
  }
  and response_locationsAvailability_location = {
    @live id: string,
    name: option<string>,
  }
  and response_locationsAvailability = {
    @live id: string,
    intervals: array<response_locationsAvailability_intervals>,
    link: option<string>,
    localDate: string,
    location: option<response_locationsAvailability_location>,
  }
  and response_viewer_availability = {
    @live id: string,
    localDate: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PlayIntentRow_availabilityDay]>,
  }
  and response_viewer_user = {
    @live id: string,
  }
  and response_viewer = {
    availability: array<response_viewer_availability>,
    user: option<response_viewer_user>,
  }
  type response = {
    availabilityUsersForDateRange: array<response_availabilityUsersForDateRange>,
    locationsAvailability: array<response_locationsAvailability>,
    viewer: option<response_viewer>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activityId: string,
    fromDate: string,
    location: locationInput,
    toDate: string,
  }
  @live
  type refetchVariables = {
    activityId: option<string>,
    fromDate: option<string>,
    location: option<locationInput>,
    toDate: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activityId=?,
    ~fromDate=?,
    ~location=?,
    ~toDate=?,
  ): refetchVariables => {
    activityId: activityId,
    fromDate: fromDate,
    location: location,
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
    json`{"__root":{"viewer_availability":{"f":""}}}`
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
    json`{"__root":{"viewer_availability":{"f":""}}}`
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
  "name": "fromDate"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "location"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "toDate"
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v5 = {
  "alias": null,
  "args": null,
  "concreteType": "User",
  "kind": "LinkedField",
  "name": "user",
  "plural": false,
  "selections": [
    (v4/*: any*/)
  ],
  "storageKey": null
},
v6 = {
  "kind": "Variable",
  "name": "activityId",
  "variableName": "activityId"
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
v9 = [
  (v6/*: any*/),
  (v7/*: any*/),
  (v8/*: any*/)
],
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "localDate",
  "storageKey": null
},
v11 = {
  "kind": "Variable",
  "name": "location",
  "variableName": "location"
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
    (v11/*: any*/),
    {
      "fields": [
        (v6/*: any*/)
      ],
      "kind": "ObjectValue",
      "name": "scope"
    },
    (v8/*: any*/)
  ],
  "concreteType": "AvailabilityDay",
  "kind": "LinkedField",
  "name": "availabilityUsersForDateRange",
  "plural": true,
  "selections": [
    (v4/*: any*/),
    (v10/*: any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "User",
      "kind": "LinkedField",
      "name": "user",
      "plural": false,
      "selections": [
        (v4/*: any*/),
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
    (v12/*: any*/)
  ],
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": [
    (v6/*: any*/),
    (v7/*: any*/),
    (v11/*: any*/),
    (v8/*: any*/)
  ],
  "concreteType": "LocationAvailabilityDay",
  "kind": "LinkedField",
  "name": "locationsAvailability",
  "plural": true,
  "selections": [
    (v4/*: any*/),
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
        (v4/*: any*/),
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
    (v12/*: any*/)
  ],
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/)
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
          (v5/*: any*/),
          {
            "alias": null,
            "args": (v9/*: any*/),
            "concreteType": "AvailabilityDay",
            "kind": "LinkedField",
            "name": "availability",
            "plural": true,
            "selections": [
              (v4/*: any*/),
              (v10/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PlayIntentRow_availabilityDay"
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      (v13/*: any*/),
      (v14/*: any*/)
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v3/*: any*/),
      (v2/*: any*/)
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
          (v5/*: any*/),
          {
            "alias": null,
            "args": (v9/*: any*/),
            "concreteType": "AvailabilityDay",
            "kind": "LinkedField",
            "name": "availability",
            "plural": true,
            "selections": [
              (v4/*: any*/),
              (v10/*: any*/),
              (v12/*: any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      (v13/*: any*/),
      (v14/*: any*/)
    ]
  },
  "params": {
    "cacheID": "2b4139e289efaf985fcc81e04742c517",
    "id": null,
    "metadata": {},
    "name": "PkEventsAvailabilityDayQuery",
    "operationKind": "query",
    "text": "query PkEventsAvailabilityDayQuery(\n  $activityId: ID!\n  $fromDate: String!\n  $toDate: String!\n  $location: LocationInput!\n) {\n  viewer {\n    user {\n      id\n    }\n    availability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate) {\n      id\n      localDate\n      ...PlayIntentRow_availabilityDay\n    }\n  }\n  availabilityUsersForDateRange(fromDate: $fromDate, toDate: $toDate, location: $location, scope: {activityId: $activityId}) {\n    id\n    localDate\n    user {\n      id\n      lineUsername\n      picture\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n  locationsAvailability(activityId: $activityId, fromDate: $fromDate, toDate: $toDate, location: $location) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n}\n\nfragment PlayIntentRow_availabilityDay on AvailabilityDay {\n  id\n  localDate\n  intervals {\n    startHour\n    endHour\n  }\n}\n"
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

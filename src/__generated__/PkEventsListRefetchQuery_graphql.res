/* @sourceLoc PkEventsList.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type eventFilters = RelaySchemaAssets_graphql.input_EventFilters
  @live type locationInput = RelaySchemaAssets_graphql.input_LocationInput
  @live type coordsInput = RelaySchemaAssets_graphql.input_CoordsInput
  @live
  type response = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkEventsListFragment]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activitySlug?: string,
    after?: string,
    afterDate?: Util.Datetime.t,
    before?: string,
    filters?: eventFilters,
    first?: int,
    location?: locationInput,
  }
  @live
  type refetchVariables = {
    activitySlug: option<option<string>>,
    after: option<option<string>>,
    afterDate: option<option<Util.Datetime.t>>,
    before: option<option<string>>,
    filters: option<option<eventFilters>>,
    first: option<option<int>>,
    location: option<option<locationInput>>,
  }
  @live let makeRefetchVariables = (
    ~activitySlug=?,
    ~after=?,
    ~afterDate=?,
    ~before=?,
    ~filters=?,
    ~first=?,
    ~location=?,
  ): refetchVariables => {
    activitySlug: activitySlug,
    after: after,
    afterDate: afterDate,
    before: before,
    filters: filters,
    first: first,
    location: location
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"locationInput":{"coords":{"r":"coordsInput"}},"coordsInput":{},"eventFilters":{},"__root":{"location":{"r":"locationInput"},"filters":{"r":"eventFilters"},"afterDate":{"c":"Util.Datetime"}}}`
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
    "defaultValue": "pickleball",
    "kind": "LocalArgument",
    "name": "activitySlug"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "after"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "afterDate"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "before"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "filters"
  },
  {
    "defaultValue": 20,
    "kind": "LocalArgument",
    "name": "first"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "location"
  }
],
v1 = {
  "kind": "Variable",
  "name": "activitySlug",
  "variableName": "activitySlug"
},
v2 = {
  "kind": "Variable",
  "name": "after",
  "variableName": "after"
},
v3 = {
  "kind": "Variable",
  "name": "afterDate",
  "variableName": "afterDate"
},
v4 = {
  "kind": "Variable",
  "name": "before",
  "variableName": "before"
},
v5 = {
  "kind": "Variable",
  "name": "filters",
  "variableName": "filters"
},
v6 = {
  "kind": "Variable",
  "name": "first",
  "variableName": "first"
},
v7 = {
  "kind": "Variable",
  "name": "location",
  "variableName": "location"
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "email",
  "storageKey": null
},
v11 = [
  (v8/*: any*/)
],
v12 = [
  {
    "kind": "Literal",
    "name": "first",
    "value": 100
  }
],
v13 = [
  (v2/*: any*/),
  (v3/*: any*/),
  (v4/*: any*/),
  (v5/*: any*/),
  (v6/*: any*/)
],
v14 = [
  (v8/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "name",
    "storageKey": null
  }
],
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v16 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cursor",
  "storageKey": null
},
v17 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endCursor",
  "storageKey": null
},
v18 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "hasNextPage",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "PkEventsListRefetchQuery",
    "selections": [
      {
        "args": [
          (v1/*: any*/),
          (v2/*: any*/),
          (v3/*: any*/),
          (v4/*: any*/),
          (v5/*: any*/),
          (v6/*: any*/),
          (v7/*: any*/)
        ],
        "kind": "FragmentSpread",
        "name": "PkEventsListFragment"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "PkEventsListRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": [
          (v7/*: any*/)
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
              (v8/*: any*/),
              (v9/*: any*/),
              (v10/*: any*/),
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
                  (v1/*: any*/)
                ],
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "rating",
                "plural": false,
                "selections": (v11/*: any*/),
                "storageKey": null
              }
            ],
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
              (v8/*: any*/),
              (v9/*: any*/),
              (v10/*: any*/)
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": (v12/*: any*/),
            "concreteType": "ClubConnection",
            "kind": "LinkedField",
            "name": "clubs",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "ClubEdge",
                "kind": "LinkedField",
                "name": "edges",
                "plural": true,
                "selections": [
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "Club",
                    "kind": "LinkedField",
                    "name": "node",
                    "plural": false,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": "clubs(first:100)"
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v13/*: any*/),
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
                  (v8/*: any*/),
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
                    "name": "timezone",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "Location",
                    "kind": "LinkedField",
                    "name": "location",
                    "plural": false,
                    "selections": (v14/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "shadow",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "listed",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "deleted",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "Club",
                    "kind": "LinkedField",
                    "name": "club",
                    "plural": false,
                    "selections": (v14/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "maxRsvps",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": (v12/*: any*/),
                    "concreteType": "EventRsvpConnection",
                    "kind": "LinkedField",
                    "name": "rsvps",
                    "plural": false,
                    "selections": [
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "EventRsvpEdge",
                        "kind": "LinkedField",
                        "name": "edges",
                        "plural": true,
                        "selections": [
                          {
                            "alias": null,
                            "args": null,
                            "concreteType": "Rsvp",
                            "kind": "LinkedField",
                            "name": "node",
                            "plural": false,
                            "selections": [
                              (v8/*: any*/),
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
                                "concreteType": "User",
                                "kind": "LinkedField",
                                "name": "user",
                                "plural": false,
                                "selections": (v11/*: any*/),
                                "storageKey": null
                              },
                              {
                                "alias": null,
                                "args": null,
                                "concreteType": "Rating",
                                "kind": "LinkedField",
                                "name": "rating",
                                "plural": false,
                                "selections": [
                                  {
                                    "alias": null,
                                    "args": null,
                                    "kind": "ScalarField",
                                    "name": "mu",
                                    "storageKey": null
                                  },
                                  (v8/*: any*/)
                                ],
                                "storageKey": null
                              },
                              (v15/*: any*/)
                            ],
                            "storageKey": null
                          },
                          (v16/*: any*/)
                        ],
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "PageInfo",
                        "kind": "LinkedField",
                        "name": "pageInfo",
                        "plural": false,
                        "selections": [
                          (v17/*: any*/),
                          (v18/*: any*/)
                        ],
                        "storageKey": null
                      }
                    ],
                    "storageKey": "rsvps(first:100)"
                  },
                  {
                    "alias": null,
                    "args": (v12/*: any*/),
                    "filters": null,
                    "handle": "connection",
                    "key": "PkEventRow_event_rsvps",
                    "kind": "LinkedHandle",
                    "name": "rsvps"
                  },
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
                    "name": "endDate",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "tags",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "cancelDeadline",
                    "storageKey": null
                  },
                  {
                    "kind": "ClientExtension",
                    "selections": [
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "__id",
                        "storageKey": null
                      }
                    ]
                  },
                  (v15/*: any*/)
                ],
                "storageKey": null
              },
              (v16/*: any*/)
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "PageInfo",
            "kind": "LinkedField",
            "name": "pageInfo",
            "plural": false,
            "selections": [
              (v18/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "hasPreviousPage",
                "storageKey": null
              },
              (v17/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "startCursor",
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
        "args": (v13/*: any*/),
        "filters": [
          "filters",
          "afterDate"
        ],
        "handle": "connection",
        "key": "PkEventsListFragment_events",
        "kind": "LinkedHandle",
        "name": "events"
      }
    ]
  },
  "params": {
    "cacheID": "5643c6e499220d41f28d47c7af3eeb75",
    "id": null,
    "metadata": {},
    "name": "PkEventsListRefetchQuery",
    "operationKind": "query",
    "text": "query PkEventsListRefetchQuery(\n  $activitySlug: String = \"pickleball\"\n  $after: String\n  $afterDate: Datetime\n  $before: String\n  $filters: EventFilters\n  $first: Int = 20\n  $location: LocationInput\n) {\n  ...PkEventsListFragment_3RKaCC\n}\n\nfragment PkEventRow_event on Event {\n  id\n  title\n  location {\n    id\n    name\n  }\n  club {\n    name\n    id\n  }\n  maxRsvps\n  rsvps(first: 100) {\n    edges {\n      node {\n        id\n        user {\n          id\n        }\n        listType\n        rating {\n          mu\n          id\n        }\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n  startDate\n  endDate\n  timezone\n  shadow\n  listed\n  deleted\n  tags\n  cancelDeadline\n}\n\nfragment PkEventRow_user on User {\n  id\n  lineUsername\n  email\n}\n\nfragment PkEventsListFragment_3RKaCC on Query {\n  resolvedLocation(location: $location) {\n    coords {\n      lat\n      lng\n    }\n    region\n  }\n  ...UseProfileGate_query_36AXNO\n  viewer {\n    user {\n      id\n      ...PkEventRow_user\n    }\n    clubs(first: 100) {\n      edges {\n        node {\n          id\n        }\n      }\n    }\n  }\n  events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate) {\n    edges {\n      node {\n        id\n        startDate\n        timezone\n        location {\n          id\n        }\n        shadow\n        listed\n        deleted\n        club {\n          id\n        }\n        maxRsvps\n        rsvps(first: 100) {\n          edges {\n            node {\n              id\n              listType\n            }\n          }\n        }\n        ...PkEventRow_event\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment ProfileModal_viewer on Query {\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      fullName\n      biography\n      gender\n      selfRating\n      dupr {\n        doubles\n        doublesReliable\n        doublesReliability\n      }\n    }\n  }\n}\n\nfragment UseProfileGate_query_36AXNO on Query {\n  ...ProfileModal_viewer\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      biography\n      selfRating\n      dupr {\n        doubles\n        doublesReliable\n        doublesReliability\n      }\n      rating(activitySlug: $activitySlug) {\n        id\n      }\n    }\n  }\n}\n"
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

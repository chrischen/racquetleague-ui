/* @sourceLoc Events.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type eventFilters = RelaySchemaAssets_graphql.input_EventFilters
  @live type locationInput = RelaySchemaAssets_graphql.input_LocationInput
  @live type coordsInput = RelaySchemaAssets_graphql.input_CoordsInput
  type response = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkEventsAvailabilityDay_query | #PkEventsListFragment]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activitySlug: string,
    after?: string,
    afterDate?: Util.Datetime.t,
    availabilityFromDate: string,
    availabilityToDate: string,
    before?: string,
    filters?: eventFilters,
    first?: int,
    location?: locationInput,
  }
  @live
  type refetchVariables = {
    activitySlug: option<string>,
    after: option<option<string>>,
    afterDate: option<option<Util.Datetime.t>>,
    availabilityFromDate: option<string>,
    availabilityToDate: option<string>,
    before: option<option<string>>,
    filters: option<option<eventFilters>>,
    first: option<option<int>>,
    location: option<option<locationInput>>,
  }
  @live let makeRefetchVariables = (
    ~activitySlug=?,
    ~after=?,
    ~afterDate=?,
    ~availabilityFromDate=?,
    ~availabilityToDate=?,
    ~before=?,
    ~filters=?,
    ~first=?,
    ~location=?,
  ): refetchVariables => {
    activitySlug: activitySlug,
    after: after,
    afterDate: afterDate,
    availabilityFromDate: availabilityFromDate,
    availabilityToDate: availabilityToDate,
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
var v0 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "activitySlug"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "after"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "afterDate"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "availabilityFromDate"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "availabilityToDate"
},
v5 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "before"
},
v6 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "filters"
},
v7 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "first"
},
v8 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "location"
},
v9 = {
  "kind": "Variable",
  "name": "activitySlug",
  "variableName": "activitySlug"
},
v10 = {
  "kind": "Variable",
  "name": "after",
  "variableName": "after"
},
v11 = {
  "kind": "Variable",
  "name": "afterDate",
  "variableName": "afterDate"
},
v12 = {
  "kind": "Variable",
  "name": "before",
  "variableName": "before"
},
v13 = {
  "kind": "Variable",
  "name": "filters",
  "variableName": "filters"
},
v14 = {
  "kind": "Variable",
  "name": "first",
  "variableName": "first"
},
v15 = {
  "kind": "Variable",
  "name": "location",
  "variableName": "location"
},
v16 = {
  "kind": "Variable",
  "name": "fromDate",
  "variableName": "availabilityFromDate"
},
v17 = {
  "kind": "Variable",
  "name": "toDate",
  "variableName": "availabilityToDate"
},
v18 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v19 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v20 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "email",
  "storageKey": null
},
v21 = [
  (v18/*: any*/)
],
v22 = {
  "kind": "Literal",
  "name": "first",
  "value": 100
},
v23 = [
  (v22/*: any*/)
],
v24 = {
  "kind": "Literal",
  "name": "activityId",
  "value": "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"
},
v25 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "localDate",
  "storageKey": null
},
v26 = {
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
v27 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "title",
  "storageKey": null
},
v28 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "startDate",
  "storageKey": null
},
v29 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endDate",
  "storageKey": null
},
v30 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "timezone",
  "storageKey": null
},
v31 = [
  (v10/*: any*/),
  (v11/*: any*/),
  (v12/*: any*/),
  (v13/*: any*/),
  (v14/*: any*/)
],
v32 = [
  (v18/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "name",
    "storageKey": null
  }
],
v33 = {
  "alias": null,
  "args": null,
  "concreteType": "Location",
  "kind": "LinkedField",
  "name": "location",
  "plural": false,
  "selections": (v32/*: any*/),
  "storageKey": null
},
v34 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v35 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cursor",
  "storageKey": null
},
v36 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endCursor",
  "storageKey": null
},
v37 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "hasNextPage",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/),
      (v5/*: any*/),
      (v6/*: any*/),
      (v7/*: any*/),
      (v8/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "EventsQuery",
    "selections": [
      {
        "args": [
          (v9/*: any*/),
          (v10/*: any*/),
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/)
        ],
        "kind": "FragmentSpread",
        "name": "PkEventsListFragment"
      },
      {
        "args": [
          (v16/*: any*/),
          (v15/*: any*/),
          (v17/*: any*/)
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
    "argumentDefinitions": [
      (v1/*: any*/),
      (v7/*: any*/),
      (v5/*: any*/),
      (v2/*: any*/),
      (v6/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/),
      (v8/*: any*/),
      (v0/*: any*/)
    ],
    "kind": "Operation",
    "name": "EventsQuery",
    "selections": [
      {
        "alias": null,
        "args": [
          (v15/*: any*/)
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
              (v18/*: any*/),
              (v19/*: any*/),
              (v20/*: any*/),
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
                "args": [
                  (v9/*: any*/)
                ],
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "rating",
                "plural": false,
                "selections": (v21/*: any*/),
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
              (v18/*: any*/),
              (v19/*: any*/),
              (v20/*: any*/)
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": (v23/*: any*/),
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
                    "selections": (v21/*: any*/),
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": "clubs(first:100)"
          },
          {
            "alias": null,
            "args": [
              (v24/*: any*/),
              (v16/*: any*/),
              (v17/*: any*/)
            ],
            "concreteType": "AvailabilityDay",
            "kind": "LinkedField",
            "name": "availability",
            "plural": true,
            "selections": [
              (v18/*: any*/),
              (v25/*: any*/),
              (v26/*: any*/)
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
              (v22/*: any*/)
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
                      (v18/*: any*/),
                      (v27/*: any*/),
                      (v28/*: any*/),
                      (v29/*: any*/),
                      (v30/*: any*/)
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
        "args": (v31/*: any*/),
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
                  (v18/*: any*/),
                  (v28/*: any*/),
                  (v30/*: any*/),
                  (v33/*: any*/),
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
                    "selections": (v32/*: any*/),
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
                    "args": (v23/*: any*/),
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
                              (v18/*: any*/),
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
                                "selections": (v21/*: any*/),
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
                                  (v18/*: any*/)
                                ],
                                "storageKey": null
                              },
                              (v34/*: any*/)
                            ],
                            "storageKey": null
                          },
                          (v35/*: any*/)
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
                          (v36/*: any*/),
                          (v37/*: any*/)
                        ],
                        "storageKey": null
                      }
                    ],
                    "storageKey": "rsvps(first:100)"
                  },
                  {
                    "alias": null,
                    "args": (v23/*: any*/),
                    "filters": null,
                    "handle": "connection",
                    "key": "PkEventRow_event_rsvps",
                    "kind": "LinkedHandle",
                    "name": "rsvps"
                  },
                  (v27/*: any*/),
                  (v29/*: any*/),
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
                  (v34/*: any*/)
                ],
                "storageKey": null
              },
              (v35/*: any*/)
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
              (v37/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "hasPreviousPage",
                "storageKey": null
              },
              (v36/*: any*/),
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
        "args": (v31/*: any*/),
        "filters": [
          "filters",
          "afterDate"
        ],
        "handle": "connection",
        "key": "PkEventsListFragment_events",
        "kind": "LinkedHandle",
        "name": "events"
      },
      {
        "alias": null,
        "args": [
          (v16/*: any*/),
          (v15/*: any*/),
          {
            "fields": [
              (v24/*: any*/),
              {
                "kind": "Literal",
                "name": "clubSlug",
                "value": null
              }
            ],
            "kind": "ObjectValue",
            "name": "scope"
          },
          (v17/*: any*/)
        ],
        "concreteType": "AvailabilityDay",
        "kind": "LinkedField",
        "name": "availabilityUsersForDateRange",
        "plural": true,
        "selections": [
          (v18/*: any*/),
          (v25/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "user",
            "plural": false,
            "selections": [
              (v18/*: any*/),
              (v19/*: any*/),
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
          (v26/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": [
          (v24/*: any*/),
          (v16/*: any*/),
          (v15/*: any*/),
          (v17/*: any*/)
        ],
        "concreteType": "LocationAvailabilityDay",
        "kind": "LinkedField",
        "name": "locationsAvailability",
        "plural": true,
        "selections": [
          (v18/*: any*/),
          (v25/*: any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "link",
            "storageKey": null
          },
          (v33/*: any*/),
          (v26/*: any*/),
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
      }
    ]
  },
  "params": {
    "cacheID": "595c8508edf52f8930f727c8b2b4370a",
    "id": null,
    "metadata": {},
    "name": "EventsQuery",
    "operationKind": "query",
    "text": "query EventsQuery(\n  $after: String\n  $first: Int\n  $before: String\n  $afterDate: Datetime\n  $filters: EventFilters\n  $availabilityFromDate: String!\n  $availabilityToDate: String!\n  $location: LocationInput\n  $activitySlug: String!\n) {\n  ...PkEventsListFragment_3RKaCC\n  ...PkEventsAvailabilityDay_query_1xKjTa\n}\n\nfragment PkEventRow_event on Event {\n  id\n  title\n  location {\n    id\n    name\n  }\n  club {\n    name\n    id\n  }\n  maxRsvps\n  rsvps(first: 100) {\n    edges {\n      node {\n        id\n        user {\n          id\n        }\n        listType\n        rating {\n          mu\n          id\n        }\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n  startDate\n  endDate\n  timezone\n  shadow\n  listed\n  deleted\n  tags\n  cancelDeadline\n}\n\nfragment PkEventRow_user on User {\n  id\n  lineUsername\n  email\n}\n\nfragment PkEventsAvailabilityDay_query_1xKjTa on Query {\n  viewer {\n    user {\n      id\n    }\n    availability(activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\", fromDate: $availabilityFromDate, toDate: $availabilityToDate) {\n      id\n      localDate\n      intervals {\n        startHour\n        endHour\n      }\n      ...PlayIntentRow_availabilityDay\n    }\n    events(first: 100, _filters: {viewer: true}) {\n      edges {\n        node {\n          id\n          title\n          startDate\n          endDate\n          timezone\n        }\n      }\n    }\n  }\n  availabilityUsersForDateRange(fromDate: $availabilityFromDate, toDate: $availabilityToDate, location: $location, scope: {activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\"}) {\n    id\n    localDate\n    user {\n      id\n      lineUsername\n      picture\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n  locationsAvailability(activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\", fromDate: $availabilityFromDate, toDate: $availabilityToDate, location: $location) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n  }\n}\n\nfragment PkEventsListFragment_3RKaCC on Query {\n  resolvedLocation(location: $location) {\n    coords {\n      lat\n      lng\n    }\n    region\n  }\n  ...UseProfileGate_query_36AXNO\n  viewer {\n    user {\n      id\n      ...PkEventRow_user\n    }\n    clubs(first: 100) {\n      edges {\n        node {\n          id\n        }\n      }\n    }\n  }\n  events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate) {\n    edges {\n      node {\n        id\n        startDate\n        timezone\n        location {\n          id\n        }\n        shadow\n        listed\n        deleted\n        club {\n          id\n        }\n        maxRsvps\n        rsvps(first: 100) {\n          edges {\n            node {\n              id\n              listType\n            }\n          }\n        }\n        ...PkEventRow_event\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment PlayIntentRow_availabilityDay on AvailabilityDay {\n  id\n  localDate\n  intervals {\n    startHour\n    endHour\n  }\n}\n\nfragment ProfileModal_viewer on Query {\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      fullName\n      biography\n      gender\n      selfRating\n    }\n  }\n}\n\nfragment UseProfileGate_query_36AXNO on Query {\n  ...ProfileModal_viewer\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      biography\n      selfRating\n      rating(activitySlug: $activitySlug) {\n        id\n      }\n    }\n  }\n}\n"
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

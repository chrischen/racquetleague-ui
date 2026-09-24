/* @sourceLoc ClubEventsListPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_club = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ClubEventsListFragment]>,
  }
  and response_viewer_clubs_edges_node = {
    @live id: string,
  }
  and response_viewer_clubs_edges = {
    node: option<response_viewer_clubs_edges_node>,
  }
  and response_viewer_clubs = {
    edges: option<array<option<response_viewer_clubs_edges>>>,
  }
  and response_viewer_user = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkEventRow_user]>,
  }
  and response_viewer = {
    clubs: response_viewer_clubs,
    user: option<response_viewer_user>,
  }
  type response = {
    club: option<response_club>,
    viewer: option<response_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkEventsAvailabilityDay_query | #UseProfileGate_query]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    after?: string,
    afterDate?: Util.Datetime.t,
    availabilityByLocation: bool,
    availabilityFromDate: string,
    availabilityLocationId: string,
    availabilityToDate: string,
    before?: string,
    first?: int,
    level?: float,
    slug: string,
    token?: string,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    afterDate: option<option<Util.Datetime.t>>,
    availabilityByLocation: option<bool>,
    availabilityFromDate: option<string>,
    availabilityLocationId: option<string>,
    availabilityToDate: option<string>,
    before: option<option<string>>,
    first: option<option<int>>,
    level: option<option<float>>,
    slug: option<string>,
    token: option<option<string>>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~afterDate=?,
    ~availabilityByLocation=?,
    ~availabilityFromDate=?,
    ~availabilityLocationId=?,
    ~availabilityToDate=?,
    ~before=?,
    ~first=?,
    ~level=?,
    ~slug=?,
    ~token=?,
  ): refetchVariables => {
    after: after,
    afterDate: afterDate,
    availabilityByLocation: availabilityByLocation,
    availabilityFromDate: availabilityFromDate,
    availabilityLocationId: availabilityLocationId,
    availabilityToDate: availabilityToDate,
    before: before,
    first: first,
    level: level,
    slug: slug,
    token: token
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"afterDate":{"c":"Util.Datetime"}}}`
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
    json`{"__root":{"viewer_user":{"f":""},"club":{"f":""},"":{"f":""}}}`
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
    json`{"__root":{"viewer_user":{"f":""},"club":{"f":""},"":{"f":""}}}`
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
  "name": "after"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "afterDate"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "availabilityByLocation"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "availabilityFromDate"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "availabilityLocationId"
},
v5 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "availabilityToDate"
},
v6 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "before"
},
v7 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "first"
},
v8 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "level"
},
v9 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "slug"
},
v10 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "token"
},
v11 = {
  "kind": "Variable",
  "name": "clubSlug",
  "variableName": "slug"
},
v12 = {
  "kind": "Variable",
  "name": "fromDate",
  "variableName": "availabilityFromDate"
},
v13 = {
  "kind": "Variable",
  "name": "locationId",
  "variableName": "availabilityLocationId"
},
v14 = {
  "kind": "Variable",
  "name": "toDate",
  "variableName": "availabilityToDate"
},
v15 = [
  {
    "kind": "Variable",
    "name": "slug",
    "variableName": "slug"
  }
],
v16 = {
  "kind": "Variable",
  "name": "after",
  "variableName": "after"
},
v17 = {
  "kind": "Variable",
  "name": "afterDate",
  "variableName": "afterDate"
},
v18 = {
  "kind": "Variable",
  "name": "before",
  "variableName": "before"
},
v19 = {
  "kind": "Variable",
  "name": "first",
  "variableName": "first"
},
v20 = {
  "kind": "Variable",
  "name": "level",
  "variableName": "level"
},
v21 = {
  "kind": "Variable",
  "name": "token",
  "variableName": "token"
},
v22 = {
  "kind": "Literal",
  "name": "first",
  "value": 100
},
v23 = [
  (v22/*: any*/)
],
v24 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v25 = [
  (v24/*: any*/)
],
v26 = {
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
          "selections": (v25/*: any*/),
          "storageKey": null
        }
      ],
      "storageKey": null
    }
  ],
  "storageKey": "clubs(first:100)"
},
v27 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v28 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "email",
  "storageKey": null
},
v29 = {
  "kind": "Literal",
  "name": "activityId",
  "value": "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"
},
v30 = [
  (v29/*: any*/),
  (v12/*: any*/),
  (v14/*: any*/)
],
v31 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "localDate",
  "storageKey": null
},
v32 = {
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
v33 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "title",
  "storageKey": null
},
v34 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "startDate",
  "storageKey": null
},
v35 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endDate",
  "storageKey": null
},
v36 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "timezone",
  "storageKey": null
},
v37 = [
  (v24/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "name",
    "storageKey": null
  }
],
v38 = {
  "alias": null,
  "args": null,
  "concreteType": "Location",
  "kind": "LinkedField",
  "name": "location",
  "plural": false,
  "selections": (v37/*: any*/),
  "storageKey": null
},
v39 = [
  (v24/*: any*/),
  (v31/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "link",
    "storageKey": null
  },
  (v38/*: any*/),
  (v32/*: any*/),
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
v40 = [
  (v16/*: any*/),
  (v17/*: any*/),
  (v18/*: any*/),
  {
    "fields": [
      (v20/*: any*/)
    ],
    "kind": "ObjectValue",
    "name": "filters"
  },
  (v19/*: any*/),
  (v21/*: any*/)
],
v41 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v42 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cursor",
  "storageKey": null
},
v43 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endCursor",
  "storageKey": null
},
v44 = {
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
      (v8/*: any*/),
      (v9/*: any*/),
      (v10/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "ClubEventsListPageQuery",
    "selections": [
      {
        "args": null,
        "kind": "FragmentSpread",
        "name": "UseProfileGate_query"
      },
      {
        "args": [
          {
            "kind": "Variable",
            "name": "byLocation",
            "variableName": "availabilityByLocation"
          },
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/)
        ],
        "kind": "FragmentSpread",
        "name": "PkEventsAvailabilityDay_query"
      },
      {
        "alias": null,
        "args": (v15/*: any*/),
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
        "plural": false,
        "selections": [
          {
            "args": [
              (v16/*: any*/),
              (v17/*: any*/),
              (v18/*: any*/),
              (v19/*: any*/),
              (v20/*: any*/),
              (v21/*: any*/)
            ],
            "kind": "FragmentSpread",
            "name": "ClubEventsListFragment"
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
            "name": "user",
            "plural": false,
            "selections": [
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "PkEventRow_user"
              }
            ],
            "storageKey": null
          },
          (v26/*: any*/)
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
      (v9/*: any*/),
      (v0/*: any*/),
      (v7/*: any*/),
      (v6/*: any*/),
      (v1/*: any*/),
      (v10/*: any*/),
      (v8/*: any*/),
      (v3/*: any*/),
      (v5/*: any*/),
      (v4/*: any*/),
      (v2/*: any*/)
    ],
    "kind": "Operation",
    "name": "ClubEventsListPageQuery",
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
              (v24/*: any*/),
              (v27/*: any*/),
              (v28/*: any*/),
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
                "selections": (v25/*: any*/),
                "storageKey": "rating(activitySlug:\"pickleball\")"
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
              (v24/*: any*/),
              (v27/*: any*/),
              (v28/*: any*/)
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": (v30/*: any*/),
            "concreteType": "AvailabilityDay",
            "kind": "LinkedField",
            "name": "availability",
            "plural": true,
            "selections": [
              (v24/*: any*/),
              (v31/*: any*/),
              (v32/*: any*/)
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
                      (v24/*: any*/),
                      (v33/*: any*/),
                      (v34/*: any*/),
                      (v35/*: any*/),
                      (v36/*: any*/)
                    ],
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": "events(_filters:{\"viewer\":true},first:100)"
          },
          (v26/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": [
          (v12/*: any*/),
          {
            "fields": [
              (v29/*: any*/),
              (v11/*: any*/)
            ],
            "kind": "ObjectValue",
            "name": "scope"
          },
          (v14/*: any*/)
        ],
        "concreteType": "AvailabilityDay",
        "kind": "LinkedField",
        "name": "availabilityUsersForDateRange",
        "plural": true,
        "selections": [
          (v24/*: any*/),
          (v31/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "user",
            "plural": false,
            "selections": [
              (v24/*: any*/),
              (v27/*: any*/),
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
          (v32/*: any*/)
        ],
        "storageKey": null
      },
      {
        "condition": "availabilityByLocation",
        "kind": "Condition",
        "passingValue": false,
        "selections": [
          {
            "alias": null,
            "args": (v30/*: any*/),
            "concreteType": "LocationAvailabilityDay",
            "kind": "LinkedField",
            "name": "locationsAvailability",
            "plural": true,
            "selections": (v39/*: any*/),
            "storageKey": null
          }
        ]
      },
      {
        "condition": "availabilityByLocation",
        "kind": "Condition",
        "passingValue": true,
        "selections": [
          {
            "alias": null,
            "args": [
              (v29/*: any*/),
              (v12/*: any*/),
              (v13/*: any*/),
              (v14/*: any*/)
            ],
            "concreteType": "LocationAvailabilityDay",
            "kind": "LinkedField",
            "name": "locationAvailability",
            "plural": true,
            "selections": (v39/*: any*/),
            "storageKey": null
          }
        ]
      },
      {
        "alias": null,
        "args": (v15/*: any*/),
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
        "plural": false,
        "selections": [
          (v24/*: any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "slug",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "defaultActivity",
            "plural": false,
            "selections": (v25/*: any*/),
            "storageKey": null
          },
          {
            "alias": null,
            "args": (v40/*: any*/),
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
                      (v24/*: any*/),
                      (v34/*: any*/),
                      (v36/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "maxRsvps",
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
                        "name": "shadow",
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
                        "selections": (v37/*: any*/),
                        "storageKey": null
                      },
                      (v38/*: any*/),
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
                                  (v24/*: any*/),
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
                                    "selections": (v25/*: any*/),
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
                                      (v24/*: any*/)
                                    ],
                                    "storageKey": null
                                  },
                                  (v41/*: any*/)
                                ],
                                "storageKey": null
                              },
                              (v42/*: any*/)
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
                              (v43/*: any*/),
                              (v44/*: any*/)
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
                      (v33/*: any*/),
                      (v35/*: any*/),
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
                      (v41/*: any*/)
                    ],
                    "storageKey": null
                  },
                  (v42/*: any*/)
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
                  (v44/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "hasPreviousPage",
                    "storageKey": null
                  },
                  (v43/*: any*/),
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
            "args": (v40/*: any*/),
            "filters": [
              "afterDate",
              "token",
              "filters"
            ],
            "handle": "connection",
            "key": "ClubEventsListFragment_events",
            "kind": "LinkedHandle",
            "name": "events"
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "815159340025bd1ca49f1a997590e087",
    "id": null,
    "metadata": {},
    "name": "ClubEventsListPageQuery",
    "operationKind": "query",
    "text": "query ClubEventsListPageQuery(\n  $slug: String!\n  $after: String\n  $first: Int\n  $before: String\n  $afterDate: Datetime\n  $token: String\n  $level: Float\n  $availabilityFromDate: String!\n  $availabilityToDate: String!\n  $availabilityLocationId: ID!\n  $availabilityByLocation: Boolean!\n) {\n  ...UseProfileGate_query\n  ...PkEventsAvailabilityDay_query_1mWdlh\n  club(slug: $slug) {\n    ...ClubEventsListFragment_22cWgY\n    id\n  }\n  viewer {\n    user {\n      ...PkEventRow_user\n      id\n    }\n    clubs(first: 100) {\n      edges {\n        node {\n          id\n        }\n      }\n    }\n  }\n}\n\nfragment ClubEventsListFragment_22cWgY on Club {\n  id\n  slug\n  defaultActivity {\n    id\n  }\n  events(after: $after, first: $first, before: $before, afterDate: $afterDate, token: $token, filters: {level: $level}) {\n    edges {\n      node {\n        id\n        startDate\n        timezone\n        maxRsvps\n        listed\n        shadow\n        deleted\n        club {\n          id\n        }\n        location {\n          id\n        }\n        rsvps(first: 100) {\n          edges {\n            node {\n              id\n              listType\n            }\n          }\n        }\n        ...PkEventRow_event\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment PkEventRow_event on Event {\n  id\n  title\n  location {\n    id\n    name\n  }\n  club {\n    name\n    id\n  }\n  maxRsvps\n  rsvps(first: 100) {\n    edges {\n      node {\n        id\n        user {\n          id\n        }\n        listType\n        rating {\n          mu\n          id\n        }\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n  startDate\n  endDate\n  timezone\n  shadow\n  listed\n  deleted\n  tags\n  cancelDeadline\n}\n\nfragment PkEventRow_user on User {\n  id\n  lineUsername\n  email\n}\n\nfragment PkEventsAvailabilityDay_query_1mWdlh on Query {\n  viewer {\n    user {\n      id\n    }\n    availability(activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\", fromDate: $availabilityFromDate, toDate: $availabilityToDate) {\n      id\n      localDate\n      intervals {\n        startHour\n        endHour\n      }\n      ...PlayIntentRow_availabilityDay\n    }\n    events(first: 100, _filters: {viewer: true}) {\n      edges {\n        node {\n          id\n          title\n          startDate\n          endDate\n          timezone\n        }\n      }\n    }\n  }\n  availabilityUsersForDateRange(fromDate: $availabilityFromDate, toDate: $availabilityToDate, scope: {activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\", clubSlug: $slug}) {\n    id\n    localDate\n    user {\n      id\n      lineUsername\n      picture\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n  locationsAvailability(activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\", fromDate: $availabilityFromDate, toDate: $availabilityToDate) @skip(if: $availabilityByLocation) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n  }\n  locationAvailability(activityId: \"Activity_414afb54-03e9-11ef-bcea-2b738de6ea61\", fromDate: $availabilityFromDate, toDate: $availabilityToDate, locationId: $availabilityLocationId) @include(if: $availabilityByLocation) {\n    id\n    localDate\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n  }\n}\n\nfragment PlayIntentRow_availabilityDay on AvailabilityDay {\n  id\n  localDate\n  intervals {\n    startHour\n    endHour\n  }\n}\n\nfragment ProfileModal_viewer on Query {\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      fullName\n      biography\n      gender\n      selfRating\n      dupr {\n        doubles\n        doublesReliable\n        doublesReliability\n      }\n    }\n  }\n}\n\nfragment UseProfileGate_query on Query {\n  ...ProfileModal_viewer\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      biography\n      selfRating\n      dupr {\n        doubles\n        doublesReliable\n        doublesReliability\n      }\n      rating(activitySlug: \"pickleball\") {\n        id\n      }\n    }\n  }\n}\n"
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

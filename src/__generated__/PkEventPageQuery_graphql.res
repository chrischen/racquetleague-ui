/* @sourceLoc PkEventPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_event_activity = {
    name: option<string>,
    slug: option<string>,
  }
  and response_event_club = {
    name: option<string>,
    slug: option<string>,
  }
  and response_event_location_coords = {
    lat: float,
    lng: float,
  }
  and response_event_location = {
    address: option<string>,
    coords: option<response_event_location_coords>,
    details: option<string>,
    @live id: string,
    links: option<array<string>>,
    name: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #GMap_location]>,
  }
  and response_event_owner = {
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and response_event_rsvps_edges_node_user = {
    @live id: string,
  }
  and response_event_rsvps_edges_node = {
    @live id: string,
    listType: option<int>,
    user: option<response_event_rsvps_edges_node_user>,
  }
  and response_event_rsvps_edges = {
    node: option<response_event_rsvps_edges_node>,
  }
  and response_event_rsvps = {
    edges: option<array<option<response_event_rsvps_edges>>>,
  }
  and response_event = {
    @live __id: RescriptRelay.dataId,
    activity: option<response_event_activity>,
    club: option<response_event_club>,
    deleted: option<Util.Datetime.t>,
    details: option<string>,
    endDate: option<Util.Datetime.t>,
    @live id: string,
    listed: option<bool>,
    location: option<response_event_location>,
    maxRsvps: option<int>,
    owner: option<response_event_owner>,
    price: option<int>,
    rsvps: option<response_event_rsvps>,
    shadow: option<bool>,
    startDate: option<Util.Datetime.t>,
    tags: option<array<string>>,
    timezone: option<string>,
    title: option<string>,
    viewerHasRsvp: option<bool>,
    viewerIsAdmin: bool,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkRSVPSection_event]>,
  }
  and response_viewer_user = {
    email: option<string>,
    @live id: string,
    lineUsername: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkRSVPSection_user]>,
  }
  and response_viewer = {
    user: option<response_viewer_user>,
  }
  type response = {
    event: option<response_event>,
    viewer: option<response_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkEventMessages_query | #ProfileModal_viewer]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    after?: string,
    before?: string,
    eventId: string,
    first?: int,
    topic: string,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    before: option<option<string>>,
    eventId: option<string>,
    first: option<option<int>>,
    topic: option<string>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~before=?,
    ~eventId=?,
    ~first=?,
    ~topic=?,
  ): refetchVariables => {
    after: after,
    before: before,
    eventId: eventId,
    first: first,
    topic: topic
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{}`
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_location":{"f":""},"event_endDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event":{"f":""},"":{"f":""}}}`
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_location":{"f":""},"event_endDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event":{"f":""},"":{"f":""}}}`
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
  "name": "after"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "before"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "eventId"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "first"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "topic"
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v6 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "email",
  "storageKey": null
},
v8 = [
  {
    "kind": "Variable",
    "name": "eventId",
    "variableName": "eventId"
  }
],
v9 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "eventId"
  }
],
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "title",
  "storageKey": null
},
v11 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "startDate",
  "storageKey": null
},
v12 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endDate",
  "storageKey": null
},
v13 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "timezone",
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "tags",
  "storageKey": null
},
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "listed",
  "storageKey": null
},
v16 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "viewerIsAdmin",
  "storageKey": null
},
v17 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "viewerHasRsvp",
  "storageKey": null
},
v18 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "deleted",
  "storageKey": null
},
v19 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "shadow",
  "storageKey": null
},
v20 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "details",
  "storageKey": null
},
v21 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "maxRsvps",
  "storageKey": null
},
v22 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "price",
  "storageKey": null
},
v23 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v24 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "slug",
  "storageKey": null
},
v25 = [
  (v23/*: any*/),
  (v24/*: any*/)
],
v26 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "address",
  "storageKey": null
},
v27 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "links",
  "storageKey": null
},
v28 = {
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
v29 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "picture",
  "storageKey": null
},
v30 = {
  "alias": null,
  "args": null,
  "concreteType": "User",
  "kind": "LinkedField",
  "name": "owner",
  "plural": false,
  "selections": [
    (v5/*: any*/),
    (v6/*: any*/),
    (v29/*: any*/)
  ],
  "storageKey": null
},
v31 = [
  {
    "kind": "Literal",
    "name": "first",
    "value": 100
  }
],
v32 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "listType",
  "storageKey": null
},
v33 = {
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
v34 = [
  {
    "kind": "Variable",
    "name": "after",
    "variableName": "after"
  },
  {
    "kind": "Variable",
    "name": "before",
    "variableName": "before"
  },
  {
    "kind": "Variable",
    "name": "first",
    "variableName": "first"
  },
  {
    "kind": "Variable",
    "name": "topic",
    "variableName": "topic"
  }
],
v35 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "gender",
  "storageKey": null
},
v36 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "ordinal",
  "storageKey": null
},
v37 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "mu",
  "storageKey": null
},
v38 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "sigma",
  "storageKey": null
},
v39 = [
  (v23/*: any*/),
  (v24/*: any*/),
  (v5/*: any*/)
],
v40 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v41 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cursor",
  "storageKey": null
},
v42 = {
  "alias": null,
  "args": null,
  "concreteType": "PageInfo",
  "kind": "LinkedField",
  "name": "pageInfo",
  "plural": false,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "endCursor",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "hasNextPage",
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
    "name": "PkEventPageQuery",
    "selections": [
      {
        "args": null,
        "kind": "FragmentSpread",
        "name": "ProfileModal_viewer"
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
              (v5/*: any*/),
              (v6/*: any*/),
              (v7/*: any*/),
              {
                "args": (v8/*: any*/),
                "kind": "FragmentSpread",
                "name": "PkRSVPSection_user"
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v9/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          (v10/*: any*/),
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/),
          (v16/*: any*/),
          (v17/*: any*/),
          (v18/*: any*/),
          (v19/*: any*/),
          (v20/*: any*/),
          (v21/*: any*/),
          (v22/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "activity",
            "plural": false,
            "selections": (v25/*: any*/),
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "Club",
            "kind": "LinkedField",
            "name": "club",
            "plural": false,
            "selections": (v25/*: any*/),
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
              (v5/*: any*/),
              (v23/*: any*/),
              (v20/*: any*/),
              (v26/*: any*/),
              (v27/*: any*/),
              (v28/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "GMap_location"
              }
            ],
            "storageKey": null
          },
          (v30/*: any*/),
          {
            "alias": null,
            "args": (v31/*: any*/),
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
                      (v5/*: any*/),
                      (v32/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "User",
                        "kind": "LinkedField",
                        "name": "user",
                        "plural": false,
                        "selections": [
                          (v5/*: any*/)
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
            "storageKey": "rsvps(first:100)"
          },
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "PkRSVPSection_event"
          },
          (v33/*: any*/)
        ],
        "storageKey": null
      },
      {
        "args": (v34/*: any*/),
        "kind": "FragmentSpread",
        "name": "PkEventMessages_query"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v2/*: any*/),
      (v4/*: any*/),
      (v0/*: any*/),
      (v3/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Operation",
    "name": "PkEventPageQuery",
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
              (v5/*: any*/),
              (v6/*: any*/),
              (v7/*: any*/),
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
              (v35/*: any*/)
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
              (v5/*: any*/),
              (v6/*: any*/),
              (v7/*: any*/),
              {
                "alias": null,
                "args": (v8/*: any*/),
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "eventRating",
                "plural": false,
                "selections": [
                  (v5/*: any*/),
                  (v36/*: any*/),
                  (v37/*: any*/),
                  (v38/*: any*/)
                ],
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
        "args": (v9/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          (v10/*: any*/),
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/),
          (v16/*: any*/),
          (v17/*: any*/),
          (v18/*: any*/),
          (v19/*: any*/),
          (v20/*: any*/),
          (v21/*: any*/),
          (v22/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "activity",
            "plural": false,
            "selections": (v39/*: any*/),
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "Club",
            "kind": "LinkedField",
            "name": "club",
            "plural": false,
            "selections": (v39/*: any*/),
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
              (v5/*: any*/),
              (v23/*: any*/),
              (v20/*: any*/),
              (v26/*: any*/),
              (v27/*: any*/),
              (v28/*: any*/)
            ],
            "storageKey": null
          },
          (v30/*: any*/),
          {
            "alias": null,
            "args": (v31/*: any*/),
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
                      (v5/*: any*/),
                      (v32/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "User",
                        "kind": "LinkedField",
                        "name": "user",
                        "plural": false,
                        "selections": [
                          (v5/*: any*/),
                          (v29/*: any*/),
                          (v6/*: any*/),
                          (v35/*: any*/)
                        ],
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
                          (v36/*: any*/),
                          (v37/*: any*/),
                          (v38/*: any*/),
                          (v5/*: any*/)
                        ],
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "message",
                        "storageKey": null
                      },
                      (v40/*: any*/)
                    ],
                    "storageKey": null
                  },
                  (v41/*: any*/)
                ],
                "storageKey": null
              },
              (v42/*: any*/)
            ],
            "storageKey": "rsvps(first:100)"
          },
          {
            "alias": null,
            "args": (v31/*: any*/),
            "filters": null,
            "handle": "connection",
            "key": "PkRSVPSection_event_rsvps",
            "kind": "LinkedHandle",
            "name": "rsvps"
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "minRating",
            "storageKey": null
          },
          (v33/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v34/*: any*/),
        "concreteType": "EventMessageConnection",
        "kind": "LinkedField",
        "name": "messagesByTopic",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "EventMessageEdge",
            "kind": "LinkedField",
            "name": "edges",
            "plural": true,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "Message",
                "kind": "LinkedField",
                "name": "node",
                "plural": false,
                "selections": [
                  (v5/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "createdAt",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "payload",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "topic",
                    "storageKey": null
                  },
                  (v40/*: any*/)
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
        "args": (v34/*: any*/),
        "filters": [
          "topic"
        ],
        "handle": "connection",
        "key": "PkEventMessages_messagesByTopic",
        "kind": "LinkedHandle",
        "name": "messagesByTopic"
      },
      (v33/*: any*/)
    ]
  },
  "params": {
    "cacheID": "51a5f904b3828f8481d004d5b9957e72",
    "id": null,
    "metadata": {},
    "name": "PkEventPageQuery",
    "operationKind": "query",
    "text": "query PkEventPageQuery(\n  $eventId: ID!\n  $topic: String!\n  $after: String\n  $first: Int\n  $before: String\n) {\n  ...ProfileModal_viewer\n  viewer {\n    user {\n      id\n      lineUsername\n      email\n      ...PkRSVPSection_user_32qNee\n    }\n  }\n  event(id: $eventId) {\n    id\n    title\n    startDate\n    endDate\n    timezone\n    tags\n    listed\n    viewerIsAdmin\n    viewerHasRsvp\n    deleted\n    shadow\n    details\n    maxRsvps\n    price\n    activity {\n      name\n      slug\n      id\n    }\n    club {\n      name\n      slug\n      id\n    }\n    location {\n      id\n      name\n      details\n      address\n      links\n      coords {\n        lat\n        lng\n      }\n      ...GMap_location\n    }\n    owner {\n      id\n      lineUsername\n      picture\n    }\n    rsvps(first: 100) {\n      edges {\n        node {\n          id\n          listType\n          user {\n            id\n          }\n        }\n      }\n    }\n    ...PkRSVPSection_event\n  }\n  ...PkEventMessages_query_VpiI6\n}\n\nfragment GMap_location on Location {\n  id\n  coords {\n    lng\n    lat\n  }\n  address\n}\n\nfragment MiniEventRsvp_rsvp on Rsvp {\n  user {\n    id\n    picture\n    lineUsername\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment PkEventMessages_query_VpiI6 on Query {\n  messagesByTopic(topic: $topic, after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        createdAt\n        payload\n        topic\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment PkEventRsvp_rsvp on Rsvp {\n  user {\n    id\n    picture\n    lineUsername\n    gender\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n  message\n  ...RsvpOptions_rsvp\n}\n\nfragment PkRSVPSection_event on Event {\n  id\n  maxRsvps\n  price\n  minRating\n  viewerIsAdmin\n  club {\n    id\n  }\n  activity {\n    slug\n    id\n  }\n  owner {\n    lineUsername\n    id\n  }\n  rsvps(first: 100) {\n    edges {\n      node {\n        id\n        listType\n        ...PkEventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          lineUsername\n          gender\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment PkRSVPSection_user_32qNee on User {\n  id\n  eventRating(eventId: $eventId) {\n    id\n    ordinal\n    mu\n    sigma\n  }\n}\n\nfragment ProfileModal_viewer on Query {\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      fullName\n      biography\n      gender\n    }\n  }\n}\n\nfragment RsvpOptions_rsvp on Rsvp {\n  id\n  listType\n  user {\n    id\n  }\n}\n"
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

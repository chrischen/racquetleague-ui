/* @sourceLoc Event.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_event_activity = {
    @live id: string,
    name: option<string>,
    slug: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #SubscribeActivity_activity]>,
  }
  and response_event_club = {
    name: option<string>,
    slug: option<string>,
  }
  and response_event_location = {
    details: option<string>,
    @live id: string,
    name: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventLocation_location | #MediaList_location]>,
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
    shadow: option<bool>,
    startDate: option<Util.Datetime.t>,
    tags: option<array<string>>,
    timezone: option<string>,
    title: option<string>,
    viewerHasRsvp: option<bool>,
    viewerIsAdmin: bool,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventFullNames_event | #RSVPSection_event]>,
  }
  and response_viewer_user = {
    @live id: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #RSVPSection_user]>,
  }
  and response_viewer = {
    user: option<response_viewer_user>,
  }
  type response = {
    event: option<response_event>,
    viewer: option<response_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventMessages_query]>,
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_location":{"f":""},"event_endDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event_activity":{"f":""},"event":{"f":""},"":{"f":""}}}`
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_location":{"f":""},"event_endDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event_activity":{"f":""},"event":{"f":""},"":{"f":""}}}`
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
v6 = [
  {
    "kind": "Variable",
    "name": "eventId",
    "variableName": "eventId"
  }
],
v7 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "eventId"
  }
],
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "title",
  "storageKey": null
},
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "details",
  "storageKey": null
},
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v11 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "slug",
  "storageKey": null
},
v12 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "viewerIsAdmin",
  "storageKey": null
},
v13 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "viewerHasRsvp",
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "startDate",
  "storageKey": null
},
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endDate",
  "storageKey": null
},
v16 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "timezone",
  "storageKey": null
},
v17 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "shadow",
  "storageKey": null
},
v18 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "listed",
  "storageKey": null
},
v19 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "tags",
  "storageKey": null
},
v20 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "deleted",
  "storageKey": null
},
v21 = [
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
  }
],
v22 = {
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
v23 = {
  "kind": "Variable",
  "name": "topic",
  "variableName": "topic"
},
v24 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v25 = [
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "ordinal",
    "storageKey": null
  },
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "mu",
    "storageKey": null
  },
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "sigma",
    "storageKey": null
  },
  (v5/*: any*/)
],
v26 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v27 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cursor",
  "storageKey": null
},
v28 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "hasNextPage",
  "storageKey": null
},
v29 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endCursor",
  "storageKey": null
},
v30 = [
  {
    "kind": "Literal",
    "name": "first",
    "value": 80
  },
  (v23/*: any*/)
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
    "name": "EventQuery",
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
              (v5/*: any*/),
              {
                "args": (v6/*: any*/),
                "kind": "FragmentSpread",
                "name": "RSVPSection_user"
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v7/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          (v8/*: any*/),
          (v9/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "activity",
            "plural": false,
            "selections": [
              (v5/*: any*/),
              (v10/*: any*/),
              (v11/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "SubscribeActivity_activity"
              }
            ],
            "storageKey": null
          },
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/),
          (v16/*: any*/),
          (v17/*: any*/),
          (v18/*: any*/),
          (v19/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Location",
            "kind": "LinkedField",
            "name": "location",
            "plural": false,
            "selections": [
              (v5/*: any*/),
              (v10/*: any*/),
              (v9/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "MediaList_location"
              },
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "EventLocation_location"
              }
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "Club",
            "kind": "LinkedField",
            "name": "club",
            "plural": false,
            "selections": [
              (v10/*: any*/),
              (v11/*: any*/)
            ],
            "storageKey": null
          },
          (v20/*: any*/),
          {
            "args": (v21/*: any*/),
            "kind": "FragmentSpread",
            "name": "RSVPSection_event"
          },
          {
            "args": (v21/*: any*/),
            "kind": "FragmentSpread",
            "name": "EventFullNames_event"
          },
          (v22/*: any*/)
        ],
        "storageKey": null
      },
      {
        "args": [
          (v23/*: any*/)
        ],
        "kind": "FragmentSpread",
        "name": "EventMessages_query"
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
    "name": "EventQuery",
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
              (v5/*: any*/),
              (v24/*: any*/),
              {
                "alias": null,
                "args": (v6/*: any*/),
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "eventRating",
                "plural": false,
                "selections": (v25/*: any*/),
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
        "args": (v7/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          (v8/*: any*/),
          (v9/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "activity",
            "plural": false,
            "selections": [
              (v5/*: any*/),
              (v10/*: any*/),
              (v11/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "Subscription",
                "kind": "LinkedField",
                "name": "sub",
                "plural": false,
                "selections": [
                  (v5/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/),
          (v16/*: any*/),
          (v17/*: any*/),
          (v18/*: any*/),
          (v19/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Location",
            "kind": "LinkedField",
            "name": "location",
            "plural": false,
            "selections": [
              (v5/*: any*/),
              (v10/*: any*/),
              (v9/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "Media",
                "kind": "LinkedField",
                "name": "media",
                "plural": true,
                "selections": [
                  (v5/*: any*/),
                  (v8/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "url",
                    "storageKey": null
                  }
                ],
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "address",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "links",
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "Club",
            "kind": "LinkedField",
            "name": "club",
            "plural": false,
            "selections": [
              (v10/*: any*/),
              (v11/*: any*/),
              (v5/*: any*/)
            ],
            "storageKey": null
          },
          (v20/*: any*/),
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
            "name": "minRating",
            "storageKey": null
          },
          {
            "alias": null,
            "args": (v21/*: any*/),
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
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "User",
                        "kind": "LinkedField",
                        "name": "user",
                        "plural": false,
                        "selections": [
                          (v5/*: any*/),
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "picture",
                            "storageKey": null
                          },
                          (v24/*: any*/),
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "fullName",
                            "storageKey": null
                          }
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
                        "selections": (v25/*: any*/),
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "message",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "listType",
                        "storageKey": null
                      },
                      (v26/*: any*/)
                    ],
                    "storageKey": null
                  },
                  (v27/*: any*/)
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
                  (v28/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "hasPreviousPage",
                    "storageKey": null
                  },
                  (v29/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": (v21/*: any*/),
            "filters": null,
            "handle": "connection",
            "key": "RSVPSection_event_rsvps",
            "kind": "LinkedHandle",
            "name": "rsvps"
          },
          {
            "alias": null,
            "args": (v21/*: any*/),
            "filters": null,
            "handle": "connection",
            "key": "EventFullNames_event_rsvps",
            "kind": "LinkedHandle",
            "name": "rsvps"
          },
          (v22/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v30/*: any*/),
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
                  (v26/*: any*/)
                ],
                "storageKey": null
              },
              (v27/*: any*/)
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
              (v29/*: any*/),
              (v28/*: any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v30/*: any*/),
        "filters": [
          "topic"
        ],
        "handle": "connection",
        "key": "EventMessages_messagesByTopic",
        "kind": "LinkedHandle",
        "name": "messagesByTopic"
      },
      (v22/*: any*/)
    ]
  },
  "params": {
    "cacheID": "ee366937435ad9c1784716f53091e250",
    "id": null,
    "metadata": {},
    "name": "EventQuery",
    "operationKind": "query",
    "text": "query EventQuery(\n  $eventId: ID!\n  $topic: String!\n  $after: String\n  $first: Int\n  $before: String\n) {\n  viewer {\n    user {\n      id\n      ...RSVPSection_user_32qNee\n    }\n  }\n  event(id: $eventId) {\n    id\n    title\n    details\n    activity {\n      id\n      name\n      slug\n      ...SubscribeActivity_activity\n    }\n    viewerIsAdmin\n    viewerHasRsvp\n    startDate\n    endDate\n    timezone\n    shadow\n    listed\n    tags\n    location {\n      id\n      name\n      details\n      ...MediaList_location\n      ...EventLocation_location\n    }\n    club {\n      name\n      slug\n      id\n    }\n    deleted\n    ...RSVPSection_event_4uAqg1\n    ...EventFullNames_event_4uAqg1\n  }\n  ...EventMessages_query_1rPy9O\n}\n\nfragment EventFullNames_event_4uAqg1 on Event {\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        ...EventRsvp_rsvp\n        user {\n          id\n          fullName\n        }\n        id\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n  id\n}\n\nfragment EventLocation_location on Location {\n  name\n  details\n  address\n  links\n}\n\nfragment EventMessages_query_1rPy9O on Query {\n  messagesByTopic(topic: $topic, first: 80) {\n    edges {\n      node {\n        id\n        createdAt\n        payload\n        topic\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment EventRsvpUser_user on User {\n  picture\n  lineUsername\n  ...RsvpOptions_user\n}\n\nfragment EventRsvp_rsvp on Rsvp {\n  user {\n    id\n    ...EventRsvpUser_user\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n  message\n}\n\nfragment GoingRsvps_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment MediaList_location on Location {\n  media {\n    id\n    title\n    url\n  }\n}\n\nfragment MiniEventRsvp_rsvp on Rsvp {\n  user {\n    id\n    picture\n    lineUsername\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment PendingRsvps_event_4uAqg1 on Event {\n  id\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment RSVPSection_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  minRating\n  viewerIsAdmin\n  activity {\n    slug\n    id\n  }\n  ...RsvpWaitlist_event_4uAqg1\n  ...GoingRsvps_event_4uAqg1\n  ...PendingRsvps_event_4uAqg1\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment RSVPSection_user_32qNee on User {\n  id\n  lineUsername\n  eventRating(eventId: $eventId) {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment RsvpOptions_user on User {\n  id\n}\n\nfragment RsvpWaitlist_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment SubscribeActivity_activity on Activity {\n  id\n  name\n  sub {\n    id\n  }\n}\n"
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

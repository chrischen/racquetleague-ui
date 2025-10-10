/* @sourceLoc EventPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_event_activity = {
    @live id: string,
    name: option<string>,
    slug: option<string>,
  }
  and response_event_club = {
    name: option<string>,
  }
  and response_event_location = {
    details: option<string>,
    @live id: string,
    name: option<string>,
  }
  and response_event = {
    @live __id: RescriptRelay.dataId,
    activity: option<response_event_activity>,
    club: option<response_event_club>,
    deleted: option<Util.Datetime.t>,
    details: option<string>,
    @live id: string,
    location: option<response_event_location>,
    startDate: option<Util.Datetime.t>,
    title: option<string>,
    viewerHasRsvp: option<bool>,
    viewerIsAdmin: bool,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventDetails_event | #EventHeader_event | #RSVPSection_event]>,
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event":{"f":""},"":{"f":""}}}`
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event":{"f":""},"":{"f":""}}}`
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
  "name": "startDate",
  "storageKey": null
},
v11 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "viewerIsAdmin",
  "storageKey": null
},
v12 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "viewerHasRsvp",
  "storageKey": null
},
v13 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "deleted",
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "slug",
  "storageKey": null
},
v16 = {
  "alias": null,
  "args": null,
  "concreteType": "Activity",
  "kind": "LinkedField",
  "name": "activity",
  "plural": false,
  "selections": [
    (v5/*: any*/),
    (v14/*: any*/),
    (v15/*: any*/)
  ],
  "storageKey": null
},
v17 = {
  "kind": "Variable",
  "name": "after",
  "variableName": "after"
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
v20 = [
  (v17/*: any*/),
  (v18/*: any*/),
  (v19/*: any*/)
],
v21 = {
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
v22 = [
  (v17/*: any*/),
  (v18/*: any*/),
  (v19/*: any*/),
  {
    "kind": "Variable",
    "name": "topic",
    "variableName": "topic"
  }
],
v23 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v24 = [
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
v25 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v26 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cursor",
  "storageKey": null
},
v27 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "hasNextPage",
  "storageKey": null
},
v28 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endCursor",
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
    "name": "EventPageQuery",
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
          (v10/*: any*/),
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v16/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Location",
            "kind": "LinkedField",
            "name": "location",
            "plural": false,
            "selections": [
              (v14/*: any*/),
              (v9/*: any*/),
              (v5/*: any*/)
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
              (v14/*: any*/)
            ],
            "storageKey": null
          },
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "EventDetails_event"
          },
          {
            "args": (v20/*: any*/),
            "kind": "FragmentSpread",
            "name": "RSVPSection_event"
          },
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "EventHeader_event"
          },
          (v21/*: any*/)
        ],
        "storageKey": null
      },
      {
        "args": (v22/*: any*/),
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
    "name": "EventPageQuery",
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
              (v23/*: any*/),
              {
                "alias": null,
                "args": (v6/*: any*/),
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "eventRating",
                "plural": false,
                "selections": (v24/*: any*/),
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
          (v10/*: any*/),
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v16/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Location",
            "kind": "LinkedField",
            "name": "location",
            "plural": false,
            "selections": [
              (v14/*: any*/),
              (v9/*: any*/),
              (v5/*: any*/),
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
              (v14/*: any*/),
              (v5/*: any*/),
              (v15/*: any*/)
            ],
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
            "args": null,
            "kind": "ScalarField",
            "name": "minRating",
            "storageKey": null
          },
          {
            "alias": null,
            "args": (v20/*: any*/),
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
                          (v23/*: any*/)
                        ],
                        "storageKey": null
                      },
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
                        "concreteType": "Rating",
                        "kind": "LinkedField",
                        "name": "rating",
                        "plural": false,
                        "selections": (v24/*: any*/),
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "message",
                        "storageKey": null
                      },
                      (v25/*: any*/)
                    ],
                    "storageKey": null
                  },
                  (v26/*: any*/)
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
                  (v27/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "hasPreviousPage",
                    "storageKey": null
                  },
                  (v28/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": (v20/*: any*/),
            "filters": null,
            "handle": "connection",
            "key": "RSVPSection_event_rsvps",
            "kind": "LinkedHandle",
            "name": "rsvps"
          },
          (v21/*: any*/),
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
            "name": "listed",
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v22/*: any*/),
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
                  (v25/*: any*/)
                ],
                "storageKey": null
              },
              (v26/*: any*/)
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
              (v27/*: any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v22/*: any*/),
        "filters": [
          "topic"
        ],
        "handle": "connection",
        "key": "EventMessages_messagesByTopic",
        "kind": "LinkedHandle",
        "name": "messagesByTopic"
      },
      (v21/*: any*/)
    ]
  },
  "params": {
    "cacheID": "ee814776ccf6ecd9c25a75b324814e72",
    "id": null,
    "metadata": {},
    "name": "EventPageQuery",
    "operationKind": "query",
    "text": "query EventPageQuery(\n  $eventId: ID!\n  $topic: String!\n  $after: String\n  $first: Int\n  $before: String\n) {\n  viewer {\n    user {\n      id\n      ...RSVPSection_user_32qNee\n    }\n  }\n  event(id: $eventId) {\n    id\n    title\n    details\n    startDate\n    viewerIsAdmin\n    viewerHasRsvp\n    deleted\n    activity {\n      id\n      name\n      slug\n    }\n    location {\n      name\n      details\n      id\n    }\n    club {\n      name\n      id\n    }\n    ...EventDetails_event\n    ...RSVPSection_event_4uAqg1\n    ...EventHeader_event\n  }\n  ...EventMessages_query_VpiI6\n}\n\nfragment EventDetails_event on Event {\n  details\n  location {\n    id\n    name\n    details\n    ...MediaList_location\n    ...EventLocation_location\n  }\n}\n\nfragment EventHeader_event on Event {\n  title\n  startDate\n  endDate\n  timezone\n  tags\n  listed\n  deleted\n  activity {\n    name\n    slug\n    id\n  }\n  club {\n    name\n    slug\n    id\n  }\n  location {\n    id\n    name\n  }\n}\n\nfragment EventLocation_location on Location {\n  name\n  details\n  address\n  links\n}\n\nfragment EventMessages_query_VpiI6 on Query {\n  messagesByTopic(topic: $topic, after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        createdAt\n        payload\n        topic\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment EventRsvpUser_user on User {\n  picture\n  lineUsername\n}\n\nfragment EventRsvp_rsvp on Rsvp {\n  user {\n    id\n    ...EventRsvpUser_user\n  }\n  ...RsvpOptions_rsvp\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n  message\n}\n\nfragment GoingRsvps_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment MediaList_location on Location {\n  media {\n    id\n    title\n    url\n  }\n}\n\nfragment MiniEventRsvp_rsvp on Rsvp {\n  user {\n    id\n    picture\n    lineUsername\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment PendingRsvps_event_4uAqg1 on Event {\n  id\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment RSVPSection_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  minRating\n  viewerIsAdmin\n  activity {\n    slug\n    id\n  }\n  ...RsvpWaitlist_event_4uAqg1\n  ...GoingRsvps_event_4uAqg1\n  ...PendingRsvps_event_4uAqg1\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment RSVPSection_user_32qNee on User {\n  id\n  lineUsername\n  eventRating(eventId: $eventId) {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment RsvpOptions_rsvp on Rsvp {\n  id\n  listType\n  user {\n    id\n  }\n}\n\nfragment RsvpWaitlist_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n"
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

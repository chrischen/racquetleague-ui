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
    location: option<response_event_location>,
    shadow: option<bool>,
    startDate: option<Util.Datetime.t>,
    title: option<string>,
    viewerHasRsvp: option<bool>,
    viewerIsAdmin: bool,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventFullNames_event | #EventRsvps_event]>,
  }
  and response_viewer_user = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventRsvps_user]>,
  }
  and response_viewer = {
    user: option<response_viewer_user>,
  }
  type response = {
    event: option<response_event>,
    viewer: option<response_viewer>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    after?: string,
    before?: string,
    eventId: string,
    first?: int,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    before: option<option<string>>,
    eventId: option<string>,
    first: option<option<int>>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~before=?,
    ~eventId=?,
    ~first=?,
  ): refetchVariables => {
    after: after,
    before: before,
    eventId: eventId,
    first: first
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_location":{"f":""},"event_endDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event_activity":{"f":""},"event":{"f":""}}}`
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_location":{"f":""},"event_endDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event_activity":{"f":""},"event":{"f":""}}}`
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
v4 = [
  {
    "kind": "Variable",
    "name": "eventId",
    "variableName": "eventId"
  }
],
v5 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "eventId"
  }
],
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
  "kind": "ScalarField",
  "name": "title",
  "storageKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "details",
  "storageKey": null
},
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "slug",
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
  "name": "startDate",
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endDate",
  "storageKey": null
},
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "shadow",
  "storageKey": null
},
v16 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "deleted",
  "storageKey": null
},
v17 = [
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
v18 = {
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
v19 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v20 = [
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
  (v6/*: any*/)
];
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
              {
                "args": (v4/*: any*/),
                "kind": "FragmentSpread",
                "name": "EventRsvps_user"
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v5/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v6/*: any*/),
          (v7/*: any*/),
          (v8/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "activity",
            "plural": false,
            "selections": [
              (v6/*: any*/),
              (v9/*: any*/),
              (v10/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "SubscribeActivity_activity"
              }
            ],
            "storageKey": null
          },
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Location",
            "kind": "LinkedField",
            "name": "location",
            "plural": false,
            "selections": [
              (v6/*: any*/),
              (v9/*: any*/),
              (v8/*: any*/),
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
              (v9/*: any*/),
              (v10/*: any*/)
            ],
            "storageKey": null
          },
          (v16/*: any*/),
          {
            "args": (v17/*: any*/),
            "kind": "FragmentSpread",
            "name": "EventRsvps_event"
          },
          {
            "args": (v17/*: any*/),
            "kind": "FragmentSpread",
            "name": "EventFullNames_event"
          },
          (v18/*: any*/)
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
      (v2/*: any*/),
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
              (v6/*: any*/),
              (v19/*: any*/),
              {
                "alias": null,
                "args": (v4/*: any*/),
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "eventRating",
                "plural": false,
                "selections": (v20/*: any*/),
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
        "args": (v5/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v6/*: any*/),
          (v7/*: any*/),
          (v8/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "activity",
            "plural": false,
            "selections": [
              (v6/*: any*/),
              (v9/*: any*/),
              (v10/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "Subscription",
                "kind": "LinkedField",
                "name": "sub",
                "plural": false,
                "selections": [
                  (v6/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Location",
            "kind": "LinkedField",
            "name": "location",
            "plural": false,
            "selections": [
              (v6/*: any*/),
              (v9/*: any*/),
              (v8/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "Media",
                "kind": "LinkedField",
                "name": "media",
                "plural": true,
                "selections": [
                  (v6/*: any*/),
                  (v7/*: any*/),
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
              (v9/*: any*/),
              (v10/*: any*/),
              (v6/*: any*/)
            ],
            "storageKey": null
          },
          (v16/*: any*/),
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
            "args": (v17/*: any*/),
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
                            "name": "picture",
                            "storageKey": null
                          },
                          (v19/*: any*/),
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
                        "selections": (v20/*: any*/),
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "listType",
                        "storageKey": null
                      },
                      (v6/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "__typename",
                        "storageKey": null
                      }
                    ],
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "cursor",
                    "storageKey": null
                  }
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
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "hasNextPage",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "hasPreviousPage",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "endCursor",
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
            "args": (v17/*: any*/),
            "filters": null,
            "handle": "connection",
            "key": "EventRsvps_event_rsvps",
            "kind": "LinkedHandle",
            "name": "rsvps"
          },
          {
            "alias": null,
            "args": (v17/*: any*/),
            "filters": null,
            "handle": "connection",
            "key": "EventFullNames_event_rsvps",
            "kind": "LinkedHandle",
            "name": "rsvps"
          },
          (v18/*: any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "d74a4f1daf0cad9b3d266933bf03fe6c",
    "id": null,
    "metadata": {},
    "name": "EventQuery",
    "operationKind": "query",
    "text": "query EventQuery(\n  $eventId: ID!\n  $after: String\n  $first: Int\n  $before: String\n) {\n  viewer {\n    user {\n      ...EventRsvps_user_32qNee\n      id\n    }\n  }\n  event(id: $eventId) {\n    id\n    title\n    details\n    activity {\n      id\n      name\n      slug\n      ...SubscribeActivity_activity\n    }\n    viewerIsAdmin\n    viewerHasRsvp\n    startDate\n    endDate\n    shadow\n    location {\n      id\n      name\n      details\n      ...MediaList_location\n      ...EventLocation_location\n    }\n    club {\n      name\n      slug\n      id\n    }\n    deleted\n    ...EventRsvps_event_4uAqg1\n    ...EventFullNames_event_4uAqg1\n  }\n}\n\nfragment EventFullNames_event_4uAqg1 on Event {\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        ...EventRsvps_rsvp\n        user {\n          id\n          fullName\n        }\n        id\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n  id\n}\n\nfragment EventLocation_location on Location {\n  name\n  details\n  address\n  links\n}\n\nfragment EventRsvpUser_user on User {\n  picture\n  lineUsername\n}\n\nfragment EventRsvps_event_4uAqg1 on Event {\n  maxRsvps\n  minRating\n  activity {\n    slug\n    id\n  }\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        ...EventRsvps_rsvp\n        user {\n          id\n        }\n        rating {\n          ordinal\n          mu\n          id\n        }\n        listType\n        id\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n  id\n}\n\nfragment EventRsvps_rsvp on Rsvp {\n  user {\n    id\n    ...EventRsvpUser_user\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment EventRsvps_user_32qNee on User {\n  id\n  lineUsername\n  eventRating(eventId: $eventId) {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment MediaList_location on Location {\n  media {\n    id\n    title\n    url\n  }\n}\n\nfragment SubscribeActivity_activity on Activity {\n  id\n  name\n  sub {\n    id\n  }\n}\n"
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

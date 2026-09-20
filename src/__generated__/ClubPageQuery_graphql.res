/* @sourceLoc ClubPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_club_events_edges_node_location = {
    @live id: string,
    name: option<string>,
  }
  and response_club_events_edges_node_rsvps_edges_node = {
    @live id: string,
    listType: option<int>,
  }
  and response_club_events_edges_node_rsvps_edges = {
    node: option<response_club_events_edges_node_rsvps_edges_node>,
  }
  and response_club_events_edges_node_rsvps = {
    edges: option<array<option<response_club_events_edges_node_rsvps_edges>>>,
  }
  and response_club_events_edges_node = {
    deleted: option<Util.Datetime.t>,
    endDate: option<Util.Datetime.t>,
    @live id: string,
    location: option<response_club_events_edges_node_location>,
    maxRsvps: option<int>,
    minRating: option<float>,
    price: option<int>,
    rsvps: option<response_club_events_edges_node_rsvps>,
    startDate: option<Util.Datetime.t>,
    timezone: option<string>,
    title: option<string>,
  }
  and response_club_events_edges = {
    node: option<response_club_events_edges_node>,
  }
  and response_club_events = {
    edges: option<array<option<response_club_events_edges>>>,
  }
  and response_club_stats = {
    activeParticipants: int,
    retentionRate: option<float>,
    topPlayersMedianSkill: option<float>,
    totalMembers: int,
  }
  and response_club_viewerMembership = {
    isAdmin: option<bool>,
    isOwner: option<bool>,
    status: option<RelaySchemaAssets_graphql.enum_T>,
  }
  and response_club = {
    chargesEnabled: bool,
    description: option<string>,
    events: response_club_events,
    exemptMembersFromPayment: bool,
    @live id: string,
    name: option<string>,
    shareLink: option<string>,
    slug: option<string>,
    stats: option<response_club_stats>,
    viewerMembership: option<response_club_viewerMembership>,
  }
  and response_viewer_user = {
    @live id: string,
  }
  and response_viewer = {
    user: option<response_viewer_user>,
  }
  type response = {
    club: option<response_club>,
    viewer: option<response_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ClubPage_leaderboard]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    slug: string,
  }
  @live
  type refetchVariables = {
    slug: option<string>,
  }
  @live let makeRefetchVariables = (
    ~slug=?,
  ): refetchVariables => {
    slug: slug
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
    json`{"__root":{"club_events_edges_node_startDate":{"c":"Util.Datetime"},"club_events_edges_node_endDate":{"c":"Util.Datetime"},"club_events_edges_node_deleted":{"c":"Util.Datetime"},"":{"f":""}}}`
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
    json`{"__root":{"club_events_edges_node_startDate":{"c":"Util.Datetime"},"club_events_edges_node_endDate":{"c":"Util.Datetime"},"club_events_edges_node_deleted":{"c":"Util.Datetime"},"":{"f":""}}}`
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
  @live
  external t_toString: RelaySchemaAssets_graphql.enum_T => string = "%identity"
  @live
  external t_input_toString: RelaySchemaAssets_graphql.enum_T_input => string = "%identity"
  @live
  let t_decode = (enum: RelaySchemaAssets_graphql.enum_T): option<RelaySchemaAssets_graphql.enum_T_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let t_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_T_input> => {
    t_decode(Obj.magic(str))
  }
}

type relayOperationNode
type operationType = RescriptRelay.queryNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "slug"
  }
],
v1 = [
  {
    "kind": "Literal",
    "name": "activitySlug",
    "value": "pickleball"
  },
  {
    "kind": "Variable",
    "name": "clubSlug",
    "variableName": "slug"
  },
  {
    "kind": "Literal",
    "name": "first",
    "value": 5
  },
  {
    "kind": "Literal",
    "name": "namespace",
    "value": "doubles:comp"
  }
],
v2 = [
  {
    "kind": "Variable",
    "name": "slug",
    "variableName": "slug"
  }
],
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "slug",
  "storageKey": null
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v6 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "description",
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "shareLink",
  "storageKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "chargesEnabled",
  "storageKey": null
},
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "exemptMembersFromPayment",
  "storageKey": null
},
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "status",
  "storageKey": null
},
v11 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "isAdmin",
  "storageKey": null
},
v12 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "isOwner",
  "storageKey": null
},
v13 = {
  "alias": null,
  "args": null,
  "concreteType": "LeagueClubStat",
  "kind": "LinkedField",
  "name": "stats",
  "plural": false,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "totalMembers",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "activeParticipants",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "topPlayersMedianSkill",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "retentionRate",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": [
    {
      "kind": "Literal",
      "name": "first",
      "value": 3
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
            (v3/*: any*/),
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
              "kind": "ScalarField",
              "name": "price",
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
              "args": null,
              "concreteType": "Location",
              "kind": "LinkedField",
              "name": "location",
              "plural": false,
              "selections": [
                (v3/*: any*/),
                (v5/*: any*/)
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
              "args": [
                {
                  "kind": "Literal",
                  "name": "first",
                  "value": 100
                }
              ],
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
                        (v3/*: any*/),
                        {
                          "alias": null,
                          "args": null,
                          "kind": "ScalarField",
                          "name": "listType",
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
            }
          ],
          "storageKey": null
        }
      ],
      "storageKey": null
    }
  ],
  "storageKey": "events(first:3)"
},
v15 = {
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
        (v3/*: any*/)
      ],
      "storageKey": null
    }
  ],
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "ClubPageQuery",
    "selections": [
      {
        "args": (v1/*: any*/),
        "kind": "FragmentSpread",
        "name": "ClubPage_leaderboard"
      },
      {
        "alias": null,
        "args": (v2/*: any*/),
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
        "plural": false,
        "selections": [
          (v3/*: any*/),
          (v4/*: any*/),
          (v5/*: any*/),
          (v6/*: any*/),
          (v7/*: any*/),
          (v8/*: any*/),
          (v9/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Membership",
            "kind": "LinkedField",
            "name": "viewerMembership",
            "plural": false,
            "selections": [
              (v10/*: any*/),
              (v11/*: any*/),
              (v12/*: any*/)
            ],
            "storageKey": null
          },
          (v13/*: any*/),
          (v14/*: any*/)
        ],
        "storageKey": null
      },
      (v15/*: any*/)
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "ClubPageQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "RatingConnection",
        "kind": "LinkedField",
        "name": "ratings",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "RatingEdge",
            "kind": "LinkedField",
            "name": "edges",
            "plural": true,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "node",
                "plural": false,
                "selections": [
                  (v3/*: any*/),
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
                    "concreteType": "User",
                    "kind": "LinkedField",
                    "name": "user",
                    "plural": false,
                    "selections": [
                      (v3/*: any*/),
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
                  }
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
        "args": (v2/*: any*/),
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
        "plural": false,
        "selections": [
          (v3/*: any*/),
          (v4/*: any*/),
          (v5/*: any*/),
          (v6/*: any*/),
          (v7/*: any*/),
          (v8/*: any*/),
          (v9/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Membership",
            "kind": "LinkedField",
            "name": "viewerMembership",
            "plural": false,
            "selections": [
              (v10/*: any*/),
              (v11/*: any*/),
              (v12/*: any*/),
              (v3/*: any*/)
            ],
            "storageKey": null
          },
          (v13/*: any*/),
          (v14/*: any*/)
        ],
        "storageKey": null
      },
      (v15/*: any*/)
    ]
  },
  "params": {
    "cacheID": "bbc2eb5f8d5025ddbb96e9973f15d7ac",
    "id": null,
    "metadata": {},
    "name": "ClubPageQuery",
    "operationKind": "query",
    "text": "query ClubPageQuery(\n  $slug: String!\n) {\n  ...ClubPage_leaderboard_1i3p82\n  club(slug: $slug) {\n    id\n    slug\n    name\n    description\n    shareLink\n    chargesEnabled\n    exemptMembersFromPayment\n    viewerMembership {\n      status\n      isAdmin\n      isOwner\n      id\n    }\n    stats {\n      totalMembers\n      activeParticipants\n      topPlayersMedianSkill\n      retentionRate\n    }\n    events(first: 3) {\n      edges {\n        node {\n          id\n          title\n          startDate\n          endDate\n          timezone\n          deleted\n          price\n          minRating\n          location {\n            id\n            name\n          }\n          maxRsvps\n          rsvps(first: 100) {\n            edges {\n              node {\n                id\n                listType\n              }\n            }\n          }\n        }\n      }\n    }\n  }\n  viewer {\n    user {\n      id\n    }\n  }\n}\n\nfragment ClubPage_leaderboard_1i3p82 on Query {\n  ratings(activitySlug: \"pickleball\", namespace: \"doubles:comp\", clubSlug: $slug, first: 5) {\n    edges {\n      node {\n        id\n        ordinal\n        mu\n        user {\n          id\n          fullName\n          lineUsername\n          picture\n        }\n      }\n    }\n  }\n}\n"
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

/* @sourceLoc LeaguePlayerPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #LeaguePlayerPage_userStats | #MatchHistoryListUser_user]>,
  }
  and response_viewer_clubs_edges_node = {
    @live id: string,
    name: option<string>,
    slug: option<string>,
  }
  and response_viewer_clubs_edges = {
    node: option<response_viewer_clubs_edges_node>,
  }
  and response_viewer_clubs = {
    edges: option<array<option<response_viewer_clubs_edges>>>,
  }
  and response_viewer = {
    clubs: response_viewer_clubs,
  }
  type response = {
    user: option<response_user>,
    viewer: option<response_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #MatchHistoryListFragment | #RatingGraphWrapperFragment]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activitySlug: string,
    after?: string,
    before?: string,
    clubSlug?: string,
    first?: int,
    namespace?: string,
    userId: string,
  }
  @live
  type refetchVariables = {
    activitySlug: option<string>,
    after: option<option<string>>,
    before: option<option<string>>,
    clubSlug: option<option<string>>,
    first: option<option<int>>,
    namespace: option<option<string>>,
    userId: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activitySlug=?,
    ~after=?,
    ~before=?,
    ~clubSlug=?,
    ~first=?,
    ~namespace=?,
    ~userId=?,
  ): refetchVariables => {
    activitySlug: activitySlug,
    after: after,
    before: before,
    clubSlug: clubSlug,
    first: first,
    namespace: namespace,
    userId: userId
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
    json`{"__root":{"user":{"f":""},"":{"f":""}}}`
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
    json`{"__root":{"user":{"f":""},"":{"f":""}}}`
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
  external gender_toString: RelaySchemaAssets_graphql.enum_Gender => string = "%identity"
  @live
  external gender_input_toString: RelaySchemaAssets_graphql.enum_Gender_input => string = "%identity"
  @live
  let gender_decode = (enum: RelaySchemaAssets_graphql.enum_Gender): option<RelaySchemaAssets_graphql.enum_Gender_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let gender_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_Gender_input> => {
    gender_decode(Obj.magic(str))
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
  "name": "before"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "clubSlug"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "first"
},
v5 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "namespace"
},
v6 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "userId"
},
v7 = {
  "kind": "Variable",
  "name": "activitySlug",
  "variableName": "activitySlug"
},
v8 = [
  (v7/*: any*/),
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
    "name": "userId",
    "variableName": "userId"
  }
],
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v10 = {
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
          "kind": "Literal",
          "name": "first",
          "value": 100
        }
      ],
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
              "selections": [
                (v9/*: any*/),
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "name",
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "slug",
                  "storageKey": null
                }
              ],
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
v11 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "userId"
  }
],
v12 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "picture",
  "storageKey": null
},
v13 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "gender",
  "storageKey": null
},
v15 = {
  "kind": "Variable",
  "name": "clubSlug",
  "variableName": "clubSlug"
},
v16 = [
  (v7/*: any*/),
  (v15/*: any*/),
  {
    "kind": "Variable",
    "name": "namespace",
    "variableName": "namespace"
  }
],
v17 = [
  (v9/*: any*/),
  (v13/*: any*/),
  (v12/*: any*/),
  (v14/*: any*/)
],
v18 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "score",
  "storageKey": null
},
v19 = {
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
v20 = [
  "activitySlug",
  "userId"
],
v21 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "mu",
  "storageKey": null
},
v22 = [
  (v21/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "sigma",
    "storageKey": null
  }
],
v23 = [
  (v18/*: any*/),
  {
    "alias": null,
    "args": null,
    "concreteType": "User",
    "kind": "LinkedField",
    "name": "user",
    "plural": false,
    "selections": (v17/*: any*/),
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
      (v4/*: any*/),
      (v5/*: any*/),
      (v6/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "LeaguePlayerPageQuery",
    "selections": [
      {
        "args": (v8/*: any*/),
        "kind": "FragmentSpread",
        "name": "MatchHistoryListFragment"
      },
      {
        "args": (v8/*: any*/),
        "kind": "FragmentSpread",
        "name": "RatingGraphWrapperFragment"
      },
      (v10/*: any*/),
      {
        "alias": null,
        "args": (v11/*: any*/),
        "concreteType": "User",
        "kind": "LinkedField",
        "name": "user",
        "plural": false,
        "selections": [
          (v9/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          {
            "args": (v16/*: any*/),
            "kind": "FragmentSpread",
            "name": "LeaguePlayerPage_userStats"
          },
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "MatchHistoryListUser_user"
          }
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
      (v1/*: any*/),
      (v4/*: any*/),
      (v2/*: any*/),
      (v0/*: any*/),
      (v5/*: any*/),
      (v6/*: any*/),
      (v3/*: any*/)
    ],
    "kind": "Operation",
    "name": "LeaguePlayerPageQuery",
    "selections": [
      {
        "alias": null,
        "args": (v8/*: any*/),
        "concreteType": "MatchConnection",
        "kind": "LinkedField",
        "name": "matches",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "MatchEdge",
            "kind": "LinkedField",
            "name": "edges",
            "plural": true,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "Match",
                "kind": "LinkedField",
                "name": "node",
                "plural": false,
                "selections": [
                  (v9/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "User",
                    "kind": "LinkedField",
                    "name": "winners",
                    "plural": true,
                    "selections": (v17/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "User",
                    "kind": "LinkedField",
                    "name": "losers",
                    "plural": true,
                    "selections": (v17/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "namespace",
                    "storageKey": null
                  },
                  (v18/*: any*/),
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
                    "name": "playerMetadata",
                    "storageKey": null
                  },
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
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "startCursor",
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v19/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v8/*: any*/),
        "filters": (v20/*: any*/),
        "handle": "connection",
        "key": "MatchHistoryListFragment_matches",
        "kind": "LinkedHandle",
        "name": "matches"
      },
      {
        "alias": null,
        "args": (v8/*: any*/),
        "filters": (v20/*: any*/),
        "handle": "connection",
        "key": "RatingGraphWrapperFragment_matches",
        "kind": "LinkedHandle",
        "name": "matches"
      },
      (v19/*: any*/),
      (v10/*: any*/),
      {
        "alias": null,
        "args": (v11/*: any*/),
        "concreteType": "User",
        "kind": "LinkedField",
        "name": "user",
        "plural": false,
        "selections": [
          (v9/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          {
            "alias": null,
            "args": (v16/*: any*/),
            "concreteType": "Rating",
            "kind": "LinkedField",
            "name": "rating",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "ordinal",
                "storageKey": null
              },
              (v21/*: any*/),
              (v9/*: any*/)
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": [
              {
                "kind": "Variable",
                "name": "activity",
                "variableName": "activitySlug"
              },
              (v15/*: any*/),
              {
                "kind": "Literal",
                "name": "namespace",
                "value": "doubles:comp"
              }
            ],
            "concreteType": "LeagueUserStat",
            "kind": "LinkedField",
            "name": "leagueUserStats",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "DisciplineRating",
                "kind": "LinkedField",
                "name": "mdRating",
                "plural": false,
                "selections": (v22/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "mdZScore",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "DisciplineRating",
                "kind": "LinkedField",
                "name": "wdRating",
                "plural": false,
                "selections": (v22/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "wdZScore",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "DisciplineRating",
                "kind": "LinkedField",
                "name": "xdRating",
                "plural": false,
                "selections": (v22/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "xdZScore",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "bestPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "worstPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "bestOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "worstOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "mdBestPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "mdWorstPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "mdBestOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "mdWorstOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "wdBestPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "wdWorstPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "wdBestOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "wdWorstOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "xdBestPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "xdWorstPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "xdBestOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "xdWorstOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "mfBestPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "mfWorstPartners",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "mfBestOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "LeagueUserStatEntry",
                "kind": "LinkedField",
                "name": "mfWorstOpponents",
                "plural": true,
                "selections": (v23/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "mfPartnerTendency",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "DisciplineRating",
                "kind": "LinkedField",
                "name": "hardcourtRating",
                "plural": false,
                "selections": (v22/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "hardcourtZScore",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "DisciplineRating",
                "kind": "LinkedField",
                "name": "indoorIndoorBallRating",
                "plural": false,
                "selections": (v22/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "indoorIndoorBallZScore",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "DisciplineRating",
                "kind": "LinkedField",
                "name": "indoorOutdoorBallRating",
                "plural": false,
                "selections": (v22/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "indoorOutdoorBallZScore",
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
    "cacheID": "db5c63e69f7e6e04dc6816ff236d83e7",
    "id": null,
    "metadata": {},
    "name": "LeaguePlayerPageQuery",
    "operationKind": "query",
    "text": "query LeaguePlayerPageQuery(\n  $after: String\n  $first: Int\n  $before: String\n  $activitySlug: String!\n  $namespace: String\n  $userId: ID!\n  $clubSlug: String\n) {\n  ...MatchHistoryListFragment_32wNNd\n  ...RatingGraphWrapperFragment_32wNNd\n  viewer {\n    clubs(first: 100) {\n      edges {\n        node {\n          id\n          name\n          slug\n        }\n      }\n    }\n  }\n  user(id: $userId) {\n    id\n    picture\n    lineUsername\n    gender\n    ...LeaguePlayerPage_userStats_1bIgST\n    ...MatchHistoryListUser_user\n  }\n}\n\nfragment LeaguePlayerPage_userStats_1bIgST on User {\n  rating(activitySlug: $activitySlug, namespace: $namespace, clubSlug: $clubSlug) {\n    ordinal\n    mu\n    id\n  }\n  leagueUserStats(activity: $activitySlug, namespace: \"doubles:comp\", clubSlug: $clubSlug) {\n    mdRating {\n      mu\n      sigma\n    }\n    mdZScore\n    wdRating {\n      mu\n      sigma\n    }\n    wdZScore\n    xdRating {\n      mu\n      sigma\n    }\n    xdZScore\n    bestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    worstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    bestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    worstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mdBestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mdWorstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mdBestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mdWorstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    wdBestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    wdWorstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    wdBestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    wdWorstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    xdBestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    xdWorstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    xdBestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    xdWorstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfBestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfWorstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfBestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfWorstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfPartnerTendency\n    hardcourtRating {\n      mu\n      sigma\n    }\n    hardcourtZScore\n    indoorIndoorBallRating {\n      mu\n      sigma\n    }\n    indoorIndoorBallZScore\n    indoorOutdoorBallRating {\n      mu\n      sigma\n    }\n    indoorOutdoorBallZScore\n  }\n  id\n}\n\nfragment MatchHistoryListFragment_32wNNd on Query {\n  matches(after: $after, first: $first, before: $before, activitySlug: $activitySlug, userId: $userId) {\n    edges {\n      node {\n        id\n        ...MatchHistoryList_match\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment MatchHistoryListTeam_user on User {\n  id\n  lineUsername\n  picture\n  gender\n}\n\nfragment MatchHistoryListUser_user on User {\n  id\n}\n\nfragment MatchHistoryList_match on Match {\n  id\n  winners {\n    id\n    ...MatchHistoryListTeam_user\n  }\n  losers {\n    id\n    ...MatchHistoryListTeam_user\n  }\n  namespace\n  score\n  createdAt\n  playerMetadata\n}\n\nfragment RatingGraphWrapperFragment_32wNNd on Query {\n  matches(after: $after, first: $first, before: $before, activitySlug: $activitySlug, userId: $userId) {\n    edges {\n      node {\n        id\n        createdAt\n        playerMetadata\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n"
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

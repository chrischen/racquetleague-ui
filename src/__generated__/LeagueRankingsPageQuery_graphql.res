/* @sourceLoc LeagueRankingsPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_club = {
    name: option<string>,
    slug: option<string>,
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
  and response_viewer_user_leagueUserStats = {
    daysNumberOne: float,
  }
  and response_viewer_user_rating = {
    mu: option<float>,
    ordinal: option<float>,
  }
  and response_viewer_user = {
    @live id: string,
    leagueUserStats: option<response_viewer_user_leagueUserStats>,
    lineUsername: option<string>,
    picture: option<string>,
    rating: option<response_viewer_user_rating>,
  }
  and response_viewer = {
    clubs: response_viewer_clubs,
    user: option<response_viewer_user>,
  }
  type response = {
    club: option<response_club>,
    viewer: option<response_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #RatingListFragment]>,
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
    namespace: string,
  }
  @live
  type refetchVariables = {
    activitySlug: option<string>,
    after: option<option<string>>,
    before: option<option<string>>,
    clubSlug: option<option<string>>,
    first: option<option<int>>,
    namespace: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activitySlug=?,
    ~after=?,
    ~before=?,
    ~clubSlug=?,
    ~first=?,
    ~namespace=?,
  ): refetchVariables => {
    activitySlug: activitySlug,
    after: after,
    before: before,
    clubSlug: clubSlug,
    first: first,
    namespace: namespace
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
  "name": "lineUsername",
  "storageKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "picture",
  "storageKey": null
},
v9 = {
  "alias": null,
  "args": [
    {
      "kind": "Variable",
      "name": "activity",
      "variableName": "activitySlug"
    },
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
      "kind": "ScalarField",
      "name": "daysNumberOne",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v10 = {
  "kind": "Variable",
  "name": "activitySlug",
  "variableName": "activitySlug"
},
v11 = {
  "kind": "Variable",
  "name": "clubSlug",
  "variableName": "clubSlug"
},
v12 = {
  "kind": "Variable",
  "name": "namespace",
  "variableName": "namespace"
},
v13 = [
  (v10/*: any*/),
  (v11/*: any*/),
  (v12/*: any*/)
],
v14 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "ordinal",
  "storageKey": null
},
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "mu",
  "storageKey": null
},
v16 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v17 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "slug",
  "storageKey": null
},
v18 = {
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
            (v6/*: any*/),
            (v16/*: any*/),
            (v17/*: any*/)
          ],
          "storageKey": null
        }
      ],
      "storageKey": null
    }
  ],
  "storageKey": "clubs(first:100)"
},
v19 = [
  {
    "kind": "Variable",
    "name": "slug",
    "variableName": "clubSlug"
  }
],
v20 = [
  (v10/*: any*/),
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
  (v11/*: any*/),
  {
    "kind": "Variable",
    "name": "first",
    "variableName": "first"
  },
  (v12/*: any*/)
];
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/),
      (v5/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "LeagueRankingsPageQuery",
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
              (v7/*: any*/),
              (v8/*: any*/),
              (v9/*: any*/),
              {
                "alias": null,
                "args": (v13/*: any*/),
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "rating",
                "plural": false,
                "selections": [
                  (v14/*: any*/),
                  (v15/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v18/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v19/*: any*/),
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
        "plural": false,
        "selections": [
          (v16/*: any*/),
          (v17/*: any*/)
        ],
        "storageKey": null
      },
      {
        "args": (v20/*: any*/),
        "kind": "FragmentSpread",
        "name": "RatingListFragment"
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
      (v3/*: any*/)
    ],
    "kind": "Operation",
    "name": "LeagueRankingsPageQuery",
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
              (v7/*: any*/),
              (v8/*: any*/),
              (v9/*: any*/),
              {
                "alias": null,
                "args": (v13/*: any*/),
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "rating",
                "plural": false,
                "selections": [
                  (v14/*: any*/),
                  (v15/*: any*/),
                  (v6/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v18/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v19/*: any*/),
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
        "plural": false,
        "selections": [
          (v16/*: any*/),
          (v17/*: any*/),
          (v6/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v20/*: any*/),
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
                  (v6/*: any*/),
                  (v14/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "User",
                    "kind": "LinkedField",
                    "name": "user",
                    "plural": false,
                    "selections": [
                      (v6/*: any*/),
                      (v7/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "gender",
                        "storageKey": null
                      },
                      (v8/*: any*/),
                      (v9/*: any*/)
                    ],
                    "storageKey": null
                  },
                  (v15/*: any*/),
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
          }
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v20/*: any*/),
        "filters": [
          "activitySlug",
          "namespace",
          "clubSlug"
        ],
        "handle": "connection",
        "key": "RatingListFragment_ratings",
        "kind": "LinkedHandle",
        "name": "ratings"
      }
    ]
  },
  "params": {
    "cacheID": "bd5eab0a98444bbffe556e285d8a7973",
    "id": null,
    "metadata": {},
    "name": "LeagueRankingsPageQuery",
    "operationKind": "query",
    "text": "query LeagueRankingsPageQuery(\n  $after: String\n  $first: Int\n  $before: String\n  $activitySlug: String!\n  $namespace: String!\n  $clubSlug: String\n) {\n  viewer {\n    user {\n      id\n      lineUsername\n      picture\n      leagueUserStats(activity: $activitySlug, namespace: \"doubles:comp\") {\n        daysNumberOne\n      }\n      rating(activitySlug: $activitySlug, namespace: $namespace, clubSlug: $clubSlug) {\n        ordinal\n        mu\n        id\n      }\n    }\n    clubs(first: 100) {\n      edges {\n        node {\n          id\n          name\n          slug\n        }\n      }\n    }\n  }\n  club(slug: $clubSlug) {\n    name\n    slug\n    id\n  }\n  ...RatingListFragment_3A4j3C\n}\n\nfragment RatingListFragment_3A4j3C on Query {\n  ratings(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace, clubSlug: $clubSlug) {\n    edges {\n      node {\n        id\n        ordinal\n        user {\n          id\n          lineUsername\n          gender\n        }\n        ...RatingList_rating_36AXNO\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment RatingList_rating_36AXNO on Rating {\n  id\n  ordinal\n  mu\n  user {\n    id\n    lineUsername\n    picture\n    gender\n    leagueUserStats(activity: $activitySlug, namespace: \"doubles:comp\") {\n      daysNumberOne\n    }\n  }\n}\n"
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

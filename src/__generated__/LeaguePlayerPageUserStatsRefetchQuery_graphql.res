/* @sourceLoc LeaguePlayerPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_node = {
    @live __typename: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #LeaguePlayerPage_userStats]>,
  }
  @live
  type response = {
    node: option<response_node>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activitySlug: string,
    clubSlug?: string,
    @live id: string,
    namespace?: string,
  }
  @live
  type refetchVariables = {
    activitySlug: option<string>,
    clubSlug: option<option<string>>,
    @live id: option<string>,
    namespace: option<option<string>>,
  }
  @live let makeRefetchVariables = (
    ~activitySlug=?,
    ~clubSlug=?,
    ~id=?,
    ~namespace=?,
  ): refetchVariables => {
    activitySlug: activitySlug,
    clubSlug: clubSlug,
    id: id,
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
    json`{"__root":{"node":{"f":""}}}`
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
    json`{"__root":{"node":{"f":""}}}`
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
  "name": "clubSlug"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "id"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "namespace"
},
v4 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "id"
  }
],
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v6 = {
  "kind": "Variable",
  "name": "clubSlug",
  "variableName": "clubSlug"
},
v7 = [
  {
    "kind": "Variable",
    "name": "activitySlug",
    "variableName": "activitySlug"
  },
  (v6/*: any*/),
  {
    "kind": "Variable",
    "name": "namespace",
    "variableName": "namespace"
  }
],
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
  "name": "mu",
  "storageKey": null
},
v10 = [
  (v9/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "sigma",
    "storageKey": null
  }
],
v11 = [
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "score",
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
      },
      {
        "alias": null,
        "args": null,
        "kind": "ScalarField",
        "name": "gender",
        "storageKey": null
      }
    ],
    "storageKey": null
  }
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
    "name": "LeaguePlayerPageUserStatsRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": (v4/*: any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          {
            "args": (v7/*: any*/),
            "kind": "FragmentSpread",
            "name": "LeaguePlayerPage_userStats"
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
      (v0/*: any*/),
      (v1/*: any*/),
      (v3/*: any*/),
      (v2/*: any*/)
    ],
    "kind": "Operation",
    "name": "LeaguePlayerPageUserStatsRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": (v4/*: any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          (v8/*: any*/),
          {
            "kind": "InlineFragment",
            "selections": [
              {
                "alias": null,
                "args": (v7/*: any*/),
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
                  (v9/*: any*/),
                  (v8/*: any*/)
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
                  (v6/*: any*/),
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
                    "selections": (v10/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "DisciplineRating",
                    "kind": "LinkedField",
                    "name": "wdRating",
                    "plural": false,
                    "selections": (v10/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "DisciplineRating",
                    "kind": "LinkedField",
                    "name": "xdRating",
                    "plural": false,
                    "selections": (v10/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "bestPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "worstPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "bestOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "worstOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "mdBestPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "mdWorstPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "mdBestOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "mdWorstOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "wdBestPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "wdWorstPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "wdBestOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "wdWorstOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "xdBestPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "xdWorstPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "xdBestOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "xdWorstOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "mfBestPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "mfWorstPartners",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "mfBestOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "concreteType": "LeagueUserStatEntry",
                    "kind": "LinkedField",
                    "name": "mfWorstOpponents",
                    "plural": true,
                    "selections": (v11/*: any*/),
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "mfPartnerTendency",
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "type": "User",
            "abstractKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "c16c5685833d5e7942d29809fee36a51",
    "id": null,
    "metadata": {},
    "name": "LeaguePlayerPageUserStatsRefetchQuery",
    "operationKind": "query",
    "text": "query LeaguePlayerPageUserStatsRefetchQuery(\n  $activitySlug: String!\n  $clubSlug: String\n  $namespace: String\n  $id: ID!\n) {\n  node(id: $id) {\n    __typename\n    ...LeaguePlayerPage_userStats_1bIgST\n    id\n  }\n}\n\nfragment LeaguePlayerPage_userStats_1bIgST on User {\n  rating(activitySlug: $activitySlug, namespace: $namespace, clubSlug: $clubSlug) {\n    ordinal\n    mu\n    id\n  }\n  leagueUserStats(activity: $activitySlug, namespace: \"doubles:comp\", clubSlug: $clubSlug) {\n    mdRating {\n      mu\n      sigma\n    }\n    wdRating {\n      mu\n      sigma\n    }\n    xdRating {\n      mu\n      sigma\n    }\n    bestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    worstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    bestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    worstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mdBestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mdWorstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mdBestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mdWorstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    wdBestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    wdWorstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    wdBestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    wdWorstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    xdBestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    xdWorstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    xdBestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    xdWorstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfBestPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfWorstPartners {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfBestOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfWorstOpponents {\n      score\n      user {\n        id\n        lineUsername\n        picture\n        gender\n      }\n    }\n    mfPartnerTendency\n  }\n  id\n}\n"
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

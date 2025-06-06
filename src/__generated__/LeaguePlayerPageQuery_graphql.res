/* @sourceLoc LeaguePlayerPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_user_rating = {
    mu: option<float>,
    ordinal: option<float>,
  }
  and response_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
    rating: option<response_user_rating>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #MatchListUser_user]>,
  }
  type response = {
    user: option<response_user>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #MatchListFragment]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activitySlug: string,
    after?: string,
    before?: string,
    first?: int,
    namespace: string,
    userId: string,
  }
  @live
  type refetchVariables = {
    activitySlug: option<string>,
    after: option<option<string>>,
    before: option<option<string>>,
    first: option<option<int>>,
    namespace: option<string>,
    userId: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activitySlug=?,
    ~after=?,
    ~before=?,
    ~first=?,
    ~namespace=?,
    ~userId=?,
  ): refetchVariables => {
    activitySlug: activitySlug,
    after: after,
    before: before,
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
  "name": "first"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "namespace"
},
v5 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "userId"
},
v6 = {
  "kind": "Variable",
  "name": "activitySlug",
  "variableName": "activitySlug"
},
v7 = {
  "kind": "Variable",
  "name": "namespace",
  "variableName": "namespace"
},
v8 = [
  (v6/*: any*/),
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
  (v7/*: any*/),
  {
    "kind": "Variable",
    "name": "userId",
    "variableName": "userId"
  }
],
v9 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "userId"
  }
],
v10 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v11 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "picture",
  "storageKey": null
},
v12 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v13 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "gender",
  "storageKey": null
},
v14 = [
  (v6/*: any*/),
  (v7/*: any*/)
],
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "ordinal",
  "storageKey": null
},
v16 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "mu",
  "storageKey": null
},
v17 = [
  (v10/*: any*/),
  (v12/*: any*/),
  (v11/*: any*/),
  (v13/*: any*/)
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
};
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
    "name": "LeaguePlayerPageQuery",
    "selections": [
      {
        "args": (v8/*: any*/),
        "kind": "FragmentSpread",
        "name": "MatchListFragment"
      },
      {
        "alias": null,
        "args": (v9/*: any*/),
        "concreteType": "User",
        "kind": "LinkedField",
        "name": "user",
        "plural": false,
        "selections": [
          (v10/*: any*/),
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          {
            "alias": null,
            "args": (v14/*: any*/),
            "concreteType": "Rating",
            "kind": "LinkedField",
            "name": "rating",
            "plural": false,
            "selections": [
              (v15/*: any*/),
              (v16/*: any*/)
            ],
            "storageKey": null
          },
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "MatchListUser_user"
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
      (v3/*: any*/),
      (v2/*: any*/),
      (v0/*: any*/),
      (v4/*: any*/),
      (v5/*: any*/)
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
                  (v10/*: any*/),
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
                    "name": "score",
                    "storageKey": null
                  },
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
          (v18/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v8/*: any*/),
        "filters": [
          "activitySlug",
          "namespace",
          "userId"
        ],
        "handle": "connection",
        "key": "MatchListFragment_matches",
        "kind": "LinkedHandle",
        "name": "matches"
      },
      (v18/*: any*/),
      {
        "alias": null,
        "args": (v9/*: any*/),
        "concreteType": "User",
        "kind": "LinkedField",
        "name": "user",
        "plural": false,
        "selections": [
          (v10/*: any*/),
          (v11/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          {
            "alias": null,
            "args": (v14/*: any*/),
            "concreteType": "Rating",
            "kind": "LinkedField",
            "name": "rating",
            "plural": false,
            "selections": [
              (v15/*: any*/),
              (v16/*: any*/),
              (v10/*: any*/)
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "e393578a97327ab224eaa28204eab523",
    "id": null,
    "metadata": {},
    "name": "LeaguePlayerPageQuery",
    "operationKind": "query",
    "text": "query LeaguePlayerPageQuery(\n  $after: String\n  $first: Int\n  $before: String\n  $activitySlug: String!\n  $namespace: String!\n  $userId: ID!\n) {\n  ...MatchListFragment_2KkbcH\n  user(id: $userId) {\n    id\n    picture\n    lineUsername\n    gender\n    rating(activitySlug: $activitySlug, namespace: $namespace) {\n      ordinal\n      mu\n      id\n    }\n    ...MatchListUser_user\n  }\n}\n\nfragment MatchListFragment_2KkbcH on Query {\n  matches(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace, userId: $userId) {\n    edges {\n      node {\n        id\n        ...MatchList_match\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment MatchListTeam_user on User {\n  id\n  lineUsername\n  picture\n  gender\n}\n\nfragment MatchListUser_user on User {\n  id\n}\n\nfragment MatchList_match on Match {\n  id\n  winners {\n    id\n    ...MatchListTeam_user\n  }\n  losers {\n    ...MatchListTeam_user\n    id\n  }\n  score\n  createdAt\n}\n"
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

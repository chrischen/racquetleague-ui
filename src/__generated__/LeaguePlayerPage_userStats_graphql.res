/* @sourceLoc LeaguePlayerPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_leagueUserStats_bestOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_bestOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_bestOpponents_user>,
  }
  and fragment_leagueUserStats_bestPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_bestPartners = {
    score: float,
    user: option<fragment_leagueUserStats_bestPartners_user>,
  }
  and fragment_leagueUserStats_hardcourtRating = {
    mu: float,
    sigma: float,
  }
  and fragment_leagueUserStats_indoorIndoorBallRating = {
    mu: float,
    sigma: float,
  }
  and fragment_leagueUserStats_indoorOutdoorBallRating = {
    mu: float,
    sigma: float,
  }
  and fragment_leagueUserStats_mdBestOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_mdBestOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_mdBestOpponents_user>,
  }
  and fragment_leagueUserStats_mdBestPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_mdBestPartners = {
    score: float,
    user: option<fragment_leagueUserStats_mdBestPartners_user>,
  }
  and fragment_leagueUserStats_mdRating = {
    mu: float,
    sigma: float,
  }
  and fragment_leagueUserStats_mdWorstOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_mdWorstOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_mdWorstOpponents_user>,
  }
  and fragment_leagueUserStats_mdWorstPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_mdWorstPartners = {
    score: float,
    user: option<fragment_leagueUserStats_mdWorstPartners_user>,
  }
  and fragment_leagueUserStats_mfBestOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_mfBestOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_mfBestOpponents_user>,
  }
  and fragment_leagueUserStats_mfBestPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_mfBestPartners = {
    score: float,
    user: option<fragment_leagueUserStats_mfBestPartners_user>,
  }
  and fragment_leagueUserStats_mfWorstOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_mfWorstOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_mfWorstOpponents_user>,
  }
  and fragment_leagueUserStats_mfWorstPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_mfWorstPartners = {
    score: float,
    user: option<fragment_leagueUserStats_mfWorstPartners_user>,
  }
  and fragment_leagueUserStats_wdBestOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_wdBestOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_wdBestOpponents_user>,
  }
  and fragment_leagueUserStats_wdBestPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_wdBestPartners = {
    score: float,
    user: option<fragment_leagueUserStats_wdBestPartners_user>,
  }
  and fragment_leagueUserStats_wdRating = {
    mu: float,
    sigma: float,
  }
  and fragment_leagueUserStats_wdWorstOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_wdWorstOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_wdWorstOpponents_user>,
  }
  and fragment_leagueUserStats_wdWorstPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_wdWorstPartners = {
    score: float,
    user: option<fragment_leagueUserStats_wdWorstPartners_user>,
  }
  and fragment_leagueUserStats_worstOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_worstOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_worstOpponents_user>,
  }
  and fragment_leagueUserStats_worstPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_worstPartners = {
    score: float,
    user: option<fragment_leagueUserStats_worstPartners_user>,
  }
  and fragment_leagueUserStats_xdBestOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_xdBestOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_xdBestOpponents_user>,
  }
  and fragment_leagueUserStats_xdBestPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_xdBestPartners = {
    score: float,
    user: option<fragment_leagueUserStats_xdBestPartners_user>,
  }
  and fragment_leagueUserStats_xdRating = {
    mu: float,
    sigma: float,
  }
  and fragment_leagueUserStats_xdWorstOpponents_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_xdWorstOpponents = {
    score: float,
    user: option<fragment_leagueUserStats_xdWorstOpponents_user>,
  }
  and fragment_leagueUserStats_xdWorstPartners_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and fragment_leagueUserStats_xdWorstPartners = {
    score: float,
    user: option<fragment_leagueUserStats_xdWorstPartners_user>,
  }
  and fragment_leagueUserStats = {
    bestOpponents: array<fragment_leagueUserStats_bestOpponents>,
    bestPartners: array<fragment_leagueUserStats_bestPartners>,
    hardcourtRating: option<fragment_leagueUserStats_hardcourtRating>,
    hardcourtZScore: option<float>,
    indoorIndoorBallRating: option<fragment_leagueUserStats_indoorIndoorBallRating>,
    indoorIndoorBallZScore: option<float>,
    indoorOutdoorBallRating: option<fragment_leagueUserStats_indoorOutdoorBallRating>,
    indoorOutdoorBallZScore: option<float>,
    mdBestOpponents: array<fragment_leagueUserStats_mdBestOpponents>,
    mdBestPartners: array<fragment_leagueUserStats_mdBestPartners>,
    mdRating: option<fragment_leagueUserStats_mdRating>,
    mdWorstOpponents: array<fragment_leagueUserStats_mdWorstOpponents>,
    mdWorstPartners: array<fragment_leagueUserStats_mdWorstPartners>,
    mdZScore: option<float>,
    mfBestOpponents: array<fragment_leagueUserStats_mfBestOpponents>,
    mfBestPartners: array<fragment_leagueUserStats_mfBestPartners>,
    mfPartnerTendency: option<float>,
    mfWorstOpponents: array<fragment_leagueUserStats_mfWorstOpponents>,
    mfWorstPartners: array<fragment_leagueUserStats_mfWorstPartners>,
    wdBestOpponents: array<fragment_leagueUserStats_wdBestOpponents>,
    wdBestPartners: array<fragment_leagueUserStats_wdBestPartners>,
    wdRating: option<fragment_leagueUserStats_wdRating>,
    wdWorstOpponents: array<fragment_leagueUserStats_wdWorstOpponents>,
    wdWorstPartners: array<fragment_leagueUserStats_wdWorstPartners>,
    wdZScore: option<float>,
    worstOpponents: array<fragment_leagueUserStats_worstOpponents>,
    worstPartners: array<fragment_leagueUserStats_worstPartners>,
    xdBestOpponents: array<fragment_leagueUserStats_xdBestOpponents>,
    xdBestPartners: array<fragment_leagueUserStats_xdBestPartners>,
    xdRating: option<fragment_leagueUserStats_xdRating>,
    xdWorstOpponents: array<fragment_leagueUserStats_xdWorstOpponents>,
    xdWorstPartners: array<fragment_leagueUserStats_xdWorstPartners>,
    xdZScore: option<float>,
  }
  and fragment_rating = {
    mu: option<float>,
    ordinal: option<float>,
  }
  type fragment = {
    @live id: string,
    leagueUserStats: option<fragment_leagueUserStats>,
    rating: option<fragment_rating>,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{}`
  )
  @live
  let fragmentConverterMap = ()
  @live
  let convertFragment = v => v->RescriptRelay.convertObj(
    fragmentConverter,
    fragmentConverterMap,
    Js.undefined
  )
}

type t
type fragmentRef
external getFragmentRef:
  RescriptRelay.fragmentRefs<[> | #LeaguePlayerPage_userStats]> => fragmentRef = "%identity"

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
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


%%private(let makeNode = (rescript_graphql_node_LeaguePlayerPageUserStatsRefetchQuery): operationType => {
  ignore(rescript_graphql_node_LeaguePlayerPageUserStatsRefetchQuery)
  %raw(json`(function(){
var v0 = {
  "kind": "Variable",
  "name": "clubSlug",
  "variableName": "clubSlug"
},
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "mu",
  "storageKey": null
},
v2 = [
  (v1/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "sigma",
    "storageKey": null
  }
],
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v4 = [
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
      (v3/*: any*/),
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
  "argumentDefinitions": [
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "activitySlug"
    },
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "clubSlug"
    },
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "namespace"
    }
  ],
  "kind": "Fragment",
  "metadata": {
    "refetch": {
      "connection": null,
      "fragmentPathInResult": [
        "node"
      ],
      "operation": rescript_graphql_node_LeaguePlayerPageUserStatsRefetchQuery,
      "identifierInfo": {
        "identifierField": "id",
        "identifierQueryVariableName": "id"
      }
    }
  },
  "name": "LeaguePlayerPage_userStats",
  "selections": [
    {
      "alias": null,
      "args": [
        {
          "kind": "Variable",
          "name": "activitySlug",
          "variableName": "activitySlug"
        },
        (v0/*: any*/),
        {
          "kind": "Variable",
          "name": "namespace",
          "variableName": "namespace"
        }
      ],
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
        (v1/*: any*/)
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
        (v0/*: any*/),
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
          "selections": (v2/*: any*/),
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
          "selections": (v2/*: any*/),
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
          "selections": (v2/*: any*/),
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
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "worstPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "bestOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "worstOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "mdBestPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "mdWorstPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "mdBestOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "mdWorstOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "wdBestPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "wdWorstPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "wdBestOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "wdWorstOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "xdBestPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "xdWorstPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "xdBestOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "xdWorstOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "mfBestPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "mfWorstPartners",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "mfBestOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "LeagueUserStatEntry",
          "kind": "LinkedField",
          "name": "mfWorstOpponents",
          "plural": true,
          "selections": (v4/*: any*/),
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
          "selections": (v2/*: any*/),
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
          "selections": (v2/*: any*/),
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
          "selections": (v2/*: any*/),
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
    },
    (v3/*: any*/)
  ],
  "type": "User",
  "abstractKey": null
};
})()`)
})
let node: operationType = makeNode(LeaguePlayerPageUserStatsRefetchQuery_graphql.node)


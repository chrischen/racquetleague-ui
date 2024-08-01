/* @sourceLoc SubmitMatch.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type leagueMatchInput = RelaySchemaAssets_graphql.input_LeagueMatchInput
  @live type doublesMatchInput = RelaySchemaAssets_graphql.input_DoublesMatchInput
  @live
  type rec response_createMatch_match_losers = {
    lineUsername: option<string>,
  }
  @live
  and response_createMatch_match_winners = {
    lineUsername: option<string>,
  }
  @live
  and response_createMatch_match = {
    createdAt: option<Util.Datetime.t>,
    @live id: string,
    losers: option<array<response_createMatch_match_losers>>,
    score: option<array<float>>,
    winners: option<array<response_createMatch_match_winners>>,
  }
  @live
  and response_createMatch_ratings = {
    @live id: string,
    mu: option<float>,
    ordinal: option<float>,
    sigma: option<float>,
  }
  @live
  and response_createMatch = {
    match: option<response_createMatch_match>,
    ratings: option<array<response_createMatch_ratings>>,
  }
  @live
  type response = {
    createMatch: response_createMatch,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    connections: array<RescriptRelay.dataId>,
    matchInput: leagueMatchInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"leagueMatchInput":{"doublesMatch":{"r":"doublesMatchInput"}},"doublesMatchInput":{"createdAt":{"c":"Util.Datetime"}},"__root":{"matchInput":{"r":"leagueMatchInput"}}}`
  )
  @live
  let variablesConverterMap = {
    "Util.Datetime": Util.Datetime.serialize,
  }
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
    json`{"__root":{"createMatch_match_createdAt":{"c":"Util.Datetime"}}}`
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
    json`{"__root":{"createMatch_match_createdAt":{"c":"Util.Datetime"}}}`
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
}
module Utils = {
  @@warning("-33")
  open Types
}

type relayOperationNode
type operationType = RescriptRelay.mutationNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "connections"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "matchInput"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "match",
    "variableName": "matchInput"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v4 = [
  (v3/*: any*/)
],
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "score",
  "storageKey": null
},
v6 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "createdAt",
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "concreteType": "Rating",
  "kind": "LinkedField",
  "name": "ratings",
  "plural": true,
  "selections": [
    (v2/*: any*/),
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
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "ordinal",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v8 = [
  (v3/*: any*/),
  (v2/*: any*/)
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "SubmitMatchMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "CreateMatchResponse",
        "kind": "LinkedField",
        "name": "createMatch",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "Match",
            "kind": "LinkedField",
            "name": "match",
            "plural": false,
            "selections": [
              (v2/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "User",
                "kind": "LinkedField",
                "name": "winners",
                "plural": true,
                "selections": (v4/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "User",
                "kind": "LinkedField",
                "name": "losers",
                "plural": true,
                "selections": (v4/*: any*/),
                "storageKey": null
              },
              (v5/*: any*/),
              (v6/*: any*/)
            ],
            "storageKey": null
          },
          (v7/*: any*/)
        ],
        "storageKey": null
      }
    ],
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "SubmitMatchMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "CreateMatchResponse",
        "kind": "LinkedField",
        "name": "createMatch",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "Match",
            "kind": "LinkedField",
            "name": "match",
            "plural": false,
            "selections": [
              (v2/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "User",
                "kind": "LinkedField",
                "name": "winners",
                "plural": true,
                "selections": (v8/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "User",
                "kind": "LinkedField",
                "name": "losers",
                "plural": true,
                "selections": (v8/*: any*/),
                "storageKey": null
              },
              (v5/*: any*/),
              (v6/*: any*/)
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "filters": null,
            "handle": "prependNode",
            "key": "",
            "kind": "LinkedHandle",
            "name": "match",
            "handleArgs": [
              {
                "kind": "Variable",
                "name": "connections",
                "variableName": "connections"
              },
              {
                "kind": "Literal",
                "name": "edgeTypeName",
                "value": "MatchEdge"
              }
            ]
          },
          (v7/*: any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "ff147a952f8da2ac1f1524ea3b0b6af5",
    "id": null,
    "metadata": {},
    "name": "SubmitMatchMutation",
    "operationKind": "mutation",
    "text": "mutation SubmitMatchMutation(\n  $matchInput: LeagueMatchInput!\n) {\n  createMatch(match: $matchInput) {\n    match {\n      id\n      winners {\n        lineUsername\n        id\n      }\n      losers {\n        lineUsername\n        id\n      }\n      score\n      createdAt\n    }\n    ratings {\n      id\n      mu\n      sigma\n      ordinal\n    }\n  }\n}\n"
  }
};
})() `)



/* @sourceLoc RatingGraphWrapper.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_matches_edges_node = {
    createdAt: option<Util.Datetime.t>,
    @live id: string,
    playerMetadata: option<string>,
  }
  and fragment_matches_edges = {
    node: option<fragment_matches_edges_node>,
  }
  and fragment_matches_pageInfo = {
    endCursor: option<string>,
    hasNextPage: bool,
    hasPreviousPage: bool,
    startCursor: option<string>,
  }
  and fragment_matches = {
    @live __id: RescriptRelay.dataId,
    edges: option<array<option<fragment_matches_edges>>>,
    pageInfo: fragment_matches_pageInfo,
  }
  type fragment = {
    @live __id: RescriptRelay.dataId,
    matches: fragment_matches,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"matches_edges_node_createdAt":{"c":"Util.Datetime"}}}`
  )
  @live
  let fragmentConverterMap = {
    "Util.Datetime": Util.Datetime.parse,
  }
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
  RescriptRelay.fragmentRefs<[> | #RatingGraphWrapperFragment]> => fragmentRef = "%identity"

@live
@inline
let connectionKey = "RatingGraphWrapperFragment_matches"

%%private(
  @live @module("relay-runtime") @scope("ConnectionHandler")
  external internal_makeConnectionId: (RescriptRelay.dataId, @as("RatingGraphWrapperFragment_matches") _, 'arguments) => RescriptRelay.dataId = "getConnectionID"
)

@live
let makeConnectionId = (connectionParentDataId: RescriptRelay.dataId, ~activitySlug: string, ~userId: option<string>=?) => {
  let activitySlug = Some(activitySlug)
  let args = {"activitySlug": activitySlug, "userId": userId}
  internal_makeConnectionId(connectionParentDataId, args)
}
module Utils = {
  @@warning("-33")
  open Types

  @live
  let getConnectionNodes: Types.fragment_matches => array<Types.fragment_matches_edges_node> = connection => 
    switch connection.edges {
      | None => []
      | Some(edges) => edges
        ->Belt.Array.keepMap(edge => switch edge {
          | None => None
          | Some(edge) => edge.node
        })
    }


}

type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


%%private(let makeNode = (rescript_graphql_node_RatingGraphWrapperRefetchQuery): operationType => {
  ignore(rescript_graphql_node_RatingGraphWrapperRefetchQuery)
  %raw(json`(function(){
var v0 = [
  "matches"
],
v1 = {
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
  "argumentDefinitions": [
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "activitySlug"
    },
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "after"
    },
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "before"
    },
    {
      "defaultValue": 100,
      "kind": "LocalArgument",
      "name": "first"
    },
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "userId"
    }
  ],
  "kind": "Fragment",
  "metadata": {
    "connection": [
      {
        "count": "first",
        "cursor": "after",
        "direction": "forward",
        "path": (v0/*: any*/)
      }
    ],
    "refetch": {
      "connection": {
        "forward": {
          "count": "first",
          "cursor": "after"
        },
        "backward": null,
        "path": (v0/*: any*/)
      },
      "fragmentPathInResult": [],
      "operation": rescript_graphql_node_RatingGraphWrapperRefetchQuery
    }
  },
  "name": "RatingGraphWrapperFragment",
  "selections": [
    {
      "alias": "matches",
      "args": [
        {
          "kind": "Variable",
          "name": "activitySlug",
          "variableName": "activitySlug"
        },
        {
          "kind": "Variable",
          "name": "userId",
          "variableName": "userId"
        }
      ],
      "concreteType": "MatchConnection",
      "kind": "LinkedField",
      "name": "__RatingGraphWrapperFragment_matches_connection",
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
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "id",
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
        (v1/*: any*/)
      ],
      "storageKey": null
    },
    (v1/*: any*/)
  ],
  "type": "Query",
  "abstractKey": null
};
})()`)
})
let node: operationType = makeNode(RatingGraphWrapperRefetchQuery_graphql.node)


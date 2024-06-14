// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";
import * as RelayRuntime from "relay-runtime";
import * as MatchListRefetchQuery_graphql from "./MatchListRefetchQuery_graphql.re.mjs";

var Types = {};

var fragmentConverter = {"__root":{"matches_edges_node":{"f":""}}};

function convertFragment(v) {
  return RescriptRelay.convertObj(v, fragmentConverter, undefined, undefined);
}

var Internal = {
  fragmentConverter: fragmentConverter,
  fragmentConverterMap: undefined,
  convertFragment: convertFragment
};

function makeConnectionId(connectionParentDataId, activitySlug, namespace, userId) {
  var activitySlug$1 = activitySlug;
  var namespace$1 = namespace;
  var args = {
    activitySlug: activitySlug$1,
    namespace: namespace$1,
    userId: userId
  };
  return RelayRuntime.ConnectionHandler.getConnectionID(connectionParentDataId, "MatchListFragment_matches", args);
}

function getConnectionNodes(connection) {
  var edges = connection.edges;
  if (edges !== undefined) {
    return Belt_Array.keepMap(edges, (function (edge) {
                  if (edge !== undefined) {
                    return edge.node;
                  }
                  
                }));
  } else {
    return [];
  }
}

var Utils = {
  getConnectionNodes: getConnectionNodes
};

function makeNode(rescript_graphql_node_MatchListRefetchQuery) {
  return ((function(){
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
      "defaultValue": 20,
      "kind": "LocalArgument",
      "name": "first"
    },
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "namespace"
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
      "operation": rescript_graphql_node_MatchListRefetchQuery
    }
  },
  "name": "MatchListFragment",
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
          "name": "namespace",
          "variableName": "namespace"
        },
        {
          "kind": "Variable",
          "name": "userId",
          "variableName": "userId"
        }
      ],
      "concreteType": "MatchConnection",
      "kind": "LinkedField",
      "name": "__MatchListFragment_matches_connection",
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
                  "args": null,
                  "kind": "FragmentSpread",
                  "name": "MatchList_match"
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
})());
}

var node = makeNode(MatchListRefetchQuery_graphql.node);

export {
  Types ,
  Internal ,
  makeConnectionId ,
  Utils ,
  node ,
}
/* node Not a pure module */
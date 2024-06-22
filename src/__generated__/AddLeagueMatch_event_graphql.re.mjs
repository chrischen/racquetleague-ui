// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";
import * as RelayRuntime from "relay-runtime";
import * as LeagueEventRsvpsRefetchQuery_graphql from "./LeagueEventRsvpsRefetchQuery_graphql.re.mjs";

var Types = {};

var fragmentConverter = {"__root":{"rsvps_edges_node_user":{"f":""}}};

function convertFragment(v) {
  return RescriptRelay.convertObj(v, fragmentConverter, undefined, undefined);
}

var Internal = {
  fragmentConverter: fragmentConverter,
  fragmentConverterMap: undefined,
  convertFragment: convertFragment
};

function makeConnectionId(connectionParentDataId) {
  return RelayRuntime.ConnectionHandler.getConnectionID(connectionParentDataId, "LeagueEventRsvps_event_rsvps", undefined);
}

function getConnectionNodes(connection) {
  if (connection === undefined) {
    return [];
  }
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

function makeNode(rescript_graphql_node_LeagueEventRsvpsRefetchQuery) {
  return ((function(){
var v0 = [
  "rsvps"
],
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "argumentDefinitions": [
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
      "defaultValue": 50,
      "kind": "LocalArgument",
      "name": "first"
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
      "fragmentPathInResult": [
        "node"
      ],
      "operation": rescript_graphql_node_LeagueEventRsvpsRefetchQuery,
      "identifierInfo": {
        "identifierField": "id",
        "identifierQueryVariableName": "id"
      }
    }
  },
  "name": "AddLeagueMatch_event",
  "selections": [
    {
      "alias": null,
      "args": null,
      "concreteType": "Activity",
      "kind": "LinkedField",
      "name": "activity",
      "plural": false,
      "selections": [
        (v1/*: any*/),
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "slug",
          "storageKey": null
        }
      ],
      "storageKey": null
    },
    {
      "alias": "rsvps",
      "args": null,
      "concreteType": "EventRsvpConnection",
      "kind": "LinkedField",
      "name": "__LeagueEventRsvps_event_rsvps_connection",
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
                    (v1/*: any*/),
                    {
                      "args": null,
                      "kind": "FragmentSpread",
                      "name": "EventRsvpUser_user"
                    }
                  ],
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "rating",
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
            }
          ],
          "storageKey": null
        }
      ],
      "storageKey": null
    },
    (v1/*: any*/),
    {
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
    }
  ],
  "type": "Event",
  "abstractKey": null
};
})());
}

var node = makeNode(LeagueEventRsvpsRefetchQuery_graphql.node);

export {
  Types ,
  Internal ,
  makeConnectionId ,
  Utils ,
  node ,
}
/* node Not a pure module */

// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.mjs";
import * as RelayRuntime from "relay-runtime";
import * as EventsListRefetchQuery_graphql from "./EventsListRefetchQuery_graphql.mjs";

var Types = {};

var fragmentConverter = {"__root":{"events_edges_node":{"f":""}}};

function convertFragment(v) {
  return RescriptRelay.convertObj(v, fragmentConverter, undefined, undefined);
}

var Internal = {
  fragmentConverter: fragmentConverter,
  fragmentConverterMap: undefined,
  convertFragment: convertFragment
};

function makeConnectionId(connectionParentDataId) {
  return RelayRuntime.ConnectionHandler.getConnectionID(connectionParentDataId, "EventsListFragment_events", undefined);
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

function makeNode(rescript_graphql_node_EventsListRefetchQuery) {
  return ((function(){
var v0 = [
  "events"
];
return {
  "argumentDefinitions": [
    {
      "defaultValue": 10,
      "kind": "LocalArgument",
      "name": "count"
    },
    {
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "cursor"
    }
  ],
  "kind": "Fragment",
  "metadata": {
    "connection": [
      {
        "count": "count",
        "cursor": "cursor",
        "direction": "forward",
        "path": (v0/*: any*/)
      }
    ],
    "refetch": {
      "connection": {
        "forward": {
          "count": "count",
          "cursor": "cursor"
        },
        "backward": null,
        "path": (v0/*: any*/)
      },
      "fragmentPathInResult": [],
      "operation": rescript_graphql_node_EventsListRefetchQuery
    }
  },
  "name": "EventsListFragment",
  "selections": [
    {
      "alias": "events",
      "args": null,
      "concreteType": "EventConnection",
      "kind": "LinkedField",
      "name": "__EventsListFragment_events_connection",
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
                  "name": "EventsList_event"
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
              "name": "startCursor",
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
    }
  ],
  "type": "Query",
  "abstractKey": null
};
})());
}

var node = makeNode(EventsListRefetchQuery_graphql.node);

export {
  Types ,
  Internal ,
  makeConnectionId ,
  Utils ,
  node ,
}
/* node Not a pure module */

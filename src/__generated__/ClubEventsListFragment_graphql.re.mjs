// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as Util from "../components/shared/Util.re.mjs";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";
import * as RelayRuntime from "relay-runtime";
import * as ClubEventsListRefetchQuery_graphql from "./ClubEventsListRefetchQuery_graphql.re.mjs";

var Types = {};

var fragmentConverter = {"__root":{"events_edges_node_startDate":{"c":"Util.Datetime"},"events_edges_node":{"f":""},"events":{"f":""}}};

var fragmentConverterMap = {
  "Util.Datetime": Util.Datetime.parse
};

function convertFragment(v) {
  return RescriptRelay.convertObj(v, fragmentConverter, fragmentConverterMap, undefined);
}

var Internal = {
  fragmentConverter: fragmentConverter,
  fragmentConverterMap: fragmentConverterMap,
  convertFragment: convertFragment
};

function makeConnectionId(connectionParentDataId, afterDate, token) {
  var afterDate$1 = afterDate !== undefined ? Util.Datetime.serialize(Caml_option.valFromOption(afterDate)) : undefined;
  var args = {
    afterDate: afterDate$1,
    token: token
  };
  return RelayRuntime.ConnectionHandler.getConnectionID(connectionParentDataId, "EventsListFragment_events", args);
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

function makeNode(rescript_graphql_node_ClubEventsListRefetchQuery) {
  return ((function(){
var v0 = [
  "events"
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
      "name": "afterDate"
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
      "name": "token"
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
      "operation": rescript_graphql_node_ClubEventsListRefetchQuery,
      "identifierInfo": {
        "identifierField": "id",
        "identifierQueryVariableName": "id"
      }
    }
  },
  "name": "ClubEventsListFragment",
  "selections": [
    {
      "alias": "events",
      "args": [
        {
          "kind": "Variable",
          "name": "afterDate",
          "variableName": "afterDate"
        },
        {
          "kind": "Variable",
          "name": "token",
          "variableName": "token"
        }
      ],
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
                (v1/*: any*/),
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "startDate",
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "timezone",
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "concreteType": "Location",
                  "kind": "LinkedField",
                  "name": "location",
                  "plural": false,
                  "selections": [
                    (v1/*: any*/)
                  ],
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "shadow",
                  "storageKey": null
                },
                {
                  "args": null,
                  "kind": "FragmentSpread",
                  "name": "ClubEventsList_event"
                },
                {
                  "args": null,
                  "kind": "FragmentSpread",
                  "name": "ClubEventsListText_event"
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
          "args": null,
          "kind": "FragmentSpread",
          "name": "PinMap_eventConnection"
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
    (v1/*: any*/)
  ],
  "type": "Club",
  "abstractKey": null
};
})());
}

var node = makeNode(ClubEventsListRefetchQuery_graphql.node);

export {
  Types ,
  Internal ,
  makeConnectionId ,
  Utils ,
  node ,
}
/* node Not a pure module */

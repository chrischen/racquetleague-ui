/* @sourceLoc EventsList.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_events_edges_node = {
    @live id: string,
    startDate: option<Util.Datetime.t>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventsList_event]>,
  }
  and fragment_events_edges = {
    node: option<fragment_events_edges_node>,
  }
  and fragment_events_pageInfo = {
    endCursor: option<string>,
    hasNextPage: bool,
    hasPreviousPage: bool,
    startCursor: option<string>,
  }
  and fragment_events = {
    edges: option<array<option<fragment_events_edges>>>,
    pageInfo: fragment_events_pageInfo,
  }
  type fragment = {
    events: fragment_events,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"events_edges_node_startDate":{"c":"Util.Datetime"},"events_edges_node":{"f":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #EventsListFragment]> => fragmentRef = "%identity"

@live
@inline
let connectionKey = "EventsListFragment_events"

%%private(
  @live @module("relay-runtime") @scope("ConnectionHandler")
  external internal_makeConnectionId: (RescriptRelay.dataId, @as("EventsListFragment_events") _, 'arguments) => RescriptRelay.dataId = "getConnectionID"
)

@live
let makeConnectionId = (connectionParentDataId: RescriptRelay.dataId, ~filters: option<RelaySchemaAssets_graphql.input_EventFilters>=?, ~afterDate: option<Util.Datetime.t>=?) => {
  let afterDate = switch afterDate { | None => None | Some(v) => Some(Util.Datetime.serialize(v)) }
  let args = {"filters": filters, "afterDate": afterDate}
  internal_makeConnectionId(connectionParentDataId, args)
}
module Utils = {
  @@warning("-33")
  open Types

  @live
  let getConnectionNodes: Types.fragment_events => array<Types.fragment_events_edges_node> = connection => 
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


%%private(let makeNode = (rescript_graphql_node_EventsListRefetchQuery): operationType => {
  ignore(rescript_graphql_node_EventsListRefetchQuery)
  %raw(json`(function(){
var v0 = [
  "events"
];
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
      "defaultValue": null,
      "kind": "LocalArgument",
      "name": "filters"
    },
    {
      "defaultValue": 20,
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
      "fragmentPathInResult": [],
      "operation": rescript_graphql_node_EventsListRefetchQuery
    }
  },
  "name": "EventsListFragment",
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
          "name": "filters",
          "variableName": "filters"
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
                  "name": "startDate",
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
    }
  ],
  "type": "Query",
  "abstractKey": null
};
})()`)
})
let node: operationType = makeNode(EventsListRefetchQuery_graphql.node)


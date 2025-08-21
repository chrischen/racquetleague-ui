/* @sourceLoc ClubEventsList.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_events_edges_node_location = {
    @live id: string,
  }
  and fragment_events_edges_node_rsvps_edges_node = {
    @live id: string,
    listType: option<int>,
  }
  and fragment_events_edges_node_rsvps_edges = {
    node: option<fragment_events_edges_node_rsvps_edges_node>,
  }
  and fragment_events_edges_node_rsvps = {
    edges: option<array<option<fragment_events_edges_node_rsvps_edges>>>,
  }
  and fragment_events_edges_node = {
    @live id: string,
    location: option<fragment_events_edges_node_location>,
    rsvps: option<fragment_events_edges_node_rsvps>,
    shadow: option<bool>,
    startDate: option<Util.Datetime.t>,
    timezone: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ClubEventsListText_event | #EventItem_event]>,
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
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PinMap_eventConnection]>,
  }
  type fragment = {
    events: fragment_events,
    @live id: string,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"events_edges_node_startDate":{"c":"Util.Datetime"},"events_edges_node":{"f":""},"events":{"f":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #ClubEventsListFragment]> => fragmentRef = "%identity"

@live
@inline
let connectionKey = "ClubEventsListFragment_events"

%%private(
  @live @module("relay-runtime") @scope("ConnectionHandler")
  external internal_makeConnectionId: (RescriptRelay.dataId, @as("ClubEventsListFragment_events") _, 'arguments) => RescriptRelay.dataId = "getConnectionID"
)

@live
let makeConnectionId = (connectionParentDataId: RescriptRelay.dataId, ~afterDate: option<Util.Datetime.t>=?, ~token: option<string>=?) => {
  let afterDate = switch afterDate { | None => None | Some(v) => Some(Util.Datetime.serialize(v)) }
  let args = {"afterDate": afterDate, "token": token}
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


%%private(let makeNode = (rescript_graphql_node_ClubEventsListRefetchQuery): operationType => {
  ignore(rescript_graphql_node_ClubEventsListRefetchQuery)
  %raw(json`(function(){
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
      "name": "__ClubEventsListFragment_events_connection",
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
                  "args": [
                    {
                      "kind": "Literal",
                      "name": "first",
                      "value": 100
                    }
                  ],
                  "concreteType": "EventRsvpConnection",
                  "kind": "LinkedField",
                  "name": "rsvps",
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
                            (v1/*: any*/),
                            {
                              "alias": null,
                              "args": null,
                              "kind": "ScalarField",
                              "name": "listType",
                              "storageKey": null
                            }
                          ],
                          "storageKey": null
                        }
                      ],
                      "storageKey": null
                    }
                  ],
                  "storageKey": "rsvps(first:100)"
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
                  "name": "EventItem_event"
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
})()`)
})
let node: operationType = makeNode(ClubEventsListRefetchQuery_graphql.node)


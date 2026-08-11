/* @sourceLoc ClubsListPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_clubs_edges_node_events_edges_node = {
    @live id: string,
    startDate: option<Util.Datetime.t>,
    timezone: option<string>,
  }
  and fragment_clubs_edges_node_events_edges = {
    node: option<fragment_clubs_edges_node_events_edges_node>,
  }
  and fragment_clubs_edges_node_events = {
    edges: option<array<option<fragment_clubs_edges_node_events_edges>>>,
  }
  and fragment_clubs_edges_node_stats = {
    activeParticipants: int,
    retentionRate: option<float>,
    topPlayersMedianSkill: option<float>,
    totalMembers: int,
  }
  and fragment_clubs_edges_node_viewerMembership = {
    isAdmin: option<bool>,
    status: option<RelaySchemaAssets_graphql.enum_T>,
  }
  and fragment_clubs_edges_node = {
    description: option<string>,
    events: fragment_clubs_edges_node_events,
    @live id: string,
    name: option<string>,
    score: option<float>,
    slug: option<string>,
    stats: option<fragment_clubs_edges_node_stats>,
    viewerMembership: option<fragment_clubs_edges_node_viewerMembership>,
  }
  and fragment_clubs_edges = {
    node: option<fragment_clubs_edges_node>,
  }
  and fragment_clubs_pageInfo = {
    endCursor: option<string>,
    hasNextPage: bool,
  }
  and fragment_clubs = {
    edges: option<array<option<fragment_clubs_edges>>>,
    pageInfo: fragment_clubs_pageInfo,
  }
  type fragment = {
    clubs: fragment_clubs,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"clubs_edges_node_events_edges_node_startDate":{"c":"Util.Datetime"}}}`
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
  RescriptRelay.fragmentRefs<[> | #ClubsListPage_query]> => fragmentRef = "%identity"

@live
@inline
let connectionKey = "ClubsListPage_query_clubs"

%%private(
  @live @module("relay-runtime") @scope("ConnectionHandler")
  external internal_makeConnectionId: (RescriptRelay.dataId, @as("ClubsListPage_query_clubs") _, 'arguments) => RescriptRelay.dataId = "getConnectionID"
)

@live
let makeConnectionId = (connectionParentDataId: RescriptRelay.dataId, ~activitySlug: string) => {
  let activitySlug = Some(activitySlug)
  let args = {"activitySlug": activitySlug}
  internal_makeConnectionId(connectionParentDataId, args)
}
module Utils = {
  @@warning("-33")
  open Types

  @live
  let getConnectionNodes: Types.fragment_clubs => array<Types.fragment_clubs_edges_node> = connection => 
    switch connection.edges {
      | None => []
      | Some(edges) => edges
        ->Belt.Array.keepMap(edge => switch edge {
          | None => None
          | Some(edge) => edge.node
        })
    }


  @live
  external t_toString: RelaySchemaAssets_graphql.enum_T => string = "%identity"
  @live
  external t_input_toString: RelaySchemaAssets_graphql.enum_T_input => string = "%identity"
  @live
  let t_decode = (enum: RelaySchemaAssets_graphql.enum_T): option<RelaySchemaAssets_graphql.enum_T_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let t_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_T_input> => {
    t_decode(Obj.magic(str))
  }
}

type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


%%private(let makeNode = (rescript_graphql_node_ClubsListPageRefetchQuery): operationType => {
  ignore(rescript_graphql_node_ClubsListPageRefetchQuery)
  %raw(json`(function(){
var v0 = [
  "clubs"
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
      "name": "afterDate"
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
      "operation": rescript_graphql_node_ClubsListPageRefetchQuery
    }
  },
  "name": "ClubsListPage_query",
  "selections": [
    {
      "alias": "clubs",
      "args": [
        {
          "kind": "Variable",
          "name": "activitySlug",
          "variableName": "activitySlug"
        }
      ],
      "concreteType": "ClubConnection",
      "kind": "LinkedField",
      "name": "__ClubsListPage_query_clubs_connection",
      "plural": false,
      "selections": [
        {
          "alias": null,
          "args": null,
          "concreteType": "ClubEdge",
          "kind": "LinkedField",
          "name": "edges",
          "plural": true,
          "selections": [
            {
              "alias": null,
              "args": null,
              "concreteType": "Club",
              "kind": "LinkedField",
              "name": "node",
              "plural": false,
              "selections": [
                (v1/*: any*/),
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "name",
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "slug",
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "description",
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
                  "concreteType": "LeagueClubStat",
                  "kind": "LinkedField",
                  "name": "stats",
                  "plural": false,
                  "selections": [
                    {
                      "alias": null,
                      "args": null,
                      "kind": "ScalarField",
                      "name": "totalMembers",
                      "storageKey": null
                    },
                    {
                      "alias": null,
                      "args": null,
                      "kind": "ScalarField",
                      "name": "activeParticipants",
                      "storageKey": null
                    },
                    {
                      "alias": null,
                      "args": null,
                      "kind": "ScalarField",
                      "name": "topPlayersMedianSkill",
                      "storageKey": null
                    },
                    {
                      "alias": null,
                      "args": null,
                      "kind": "ScalarField",
                      "name": "retentionRate",
                      "storageKey": null
                    }
                  ],
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "concreteType": "Membership",
                  "kind": "LinkedField",
                  "name": "viewerMembership",
                  "plural": false,
                  "selections": [
                    {
                      "alias": null,
                      "args": null,
                      "kind": "ScalarField",
                      "name": "status",
                      "storageKey": null
                    },
                    {
                      "alias": null,
                      "args": null,
                      "kind": "ScalarField",
                      "name": "isAdmin",
                      "storageKey": null
                    }
                  ],
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": [
                    {
                      "kind": "Variable",
                      "name": "afterDate",
                      "variableName": "afterDate"
                    },
                    {
                      "kind": "Literal",
                      "name": "first",
                      "value": 1
                    }
                  ],
                  "concreteType": "EventConnection",
                  "kind": "LinkedField",
                  "name": "events",
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
                            }
                          ],
                          "storageKey": null
                        }
                      ],
                      "storageKey": null
                    }
                  ],
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
})()`)
})
let node: operationType = makeNode(ClubsListPageRefetchQuery_graphql.node)


/* @sourceLoc AiTetsu.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_activity = {
    @live id: string,
    slug: option<string>,
  }
  and fragment_rsvps_edges_node_rating = {
    @live id: string,
    mu: option<float>,
    ordinal: option<float>,
    sigma: option<float>,
  }
  and fragment_rsvps_edges_node_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventMatchRsvpUser_user | #EventRsvpUser_user]>,
  }
  and fragment_rsvps_edges_node = {
    @live __id: RescriptRelay.dataId,
    rating: option<fragment_rsvps_edges_node_rating>,
    user: option<fragment_rsvps_edges_node_user>,
  }
  and fragment_rsvps_edges = {
    node: option<fragment_rsvps_edges_node>,
  }
  and fragment_rsvps_pageInfo = {
    endCursor: option<string>,
    hasNextPage: bool,
    hasPreviousPage: bool,
  }
  and fragment_rsvps = {
    edges: option<array<option<fragment_rsvps_edges>>>,
    pageInfo: fragment_rsvps_pageInfo,
  }
  type fragment = {
    @live __id: RescriptRelay.dataId,
    activity: option<fragment_activity>,
    @live id: string,
    rsvps: option<fragment_rsvps>,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"rsvps_edges_node_user":{"f":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #AiTetsu_event]> => fragmentRef = "%identity"

@live
@inline
let connectionKey = "SelectMatchRsvps_event_rsvps"

%%private(
  @live @module("relay-runtime") @scope("ConnectionHandler")
  external internal_makeConnectionId: (RescriptRelay.dataId, @as("SelectMatchRsvps_event_rsvps") _, 'arguments) => RescriptRelay.dataId = "getConnectionID"
)

@live
let makeConnectionId = (connectionParentDataId: RescriptRelay.dataId, ) => {
  let args = ()
  internal_makeConnectionId(connectionParentDataId, args)
}
module Utils = {
  @@warning("-33")
  open Types

  @live
  let getConnectionNodes: option<Types.fragment_rsvps> => array<Types.fragment_rsvps_edges_node> = connection => 
    switch connection {
      | None => []
      | Some(connection) => 
        switch connection.edges {
          | None => []
          | Some(edges) => edges
            ->Belt.Array.keepMap(edge => switch edge {
              | None => None
              | Some(edge) => edge.node
            })
        }
    }


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


%%private(let makeNode = (rescript_graphql_node_AiTetsuRsvpsRefetchQuery): operationType => {
  ignore(rescript_graphql_node_AiTetsuRsvpsRefetchQuery)
  %raw(json`(function(){
var v0 = [
  "rsvps"
],
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v2 = {
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
      "operation": rescript_graphql_node_AiTetsuRsvpsRefetchQuery,
      "identifierInfo": {
        "identifierField": "id",
        "identifierQueryVariableName": "id"
      }
    }
  },
  "name": "AiTetsu_event",
  "selections": [
    (v1/*: any*/),
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
      "name": "__SelectMatchRsvps_event_rsvps_connection",
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
                      "name": "gender",
                      "storageKey": null
                    },
                    {
                      "args": null,
                      "kind": "FragmentSpread",
                      "name": "EventRsvpUser_user"
                    },
                    {
                      "args": null,
                      "kind": "FragmentSpread",
                      "name": "EventMatchRsvpUser_user"
                    }
                  ],
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "concreteType": "Rating",
                  "kind": "LinkedField",
                  "name": "rating",
                  "plural": false,
                  "selections": [
                    (v1/*: any*/),
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
                (v2/*: any*/),
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
    (v2/*: any*/)
  ],
  "type": "Event",
  "abstractKey": null
};
})()`)
})
let node: operationType = makeNode(AiTetsuRsvpsRefetchQuery_graphql.node)


/* @sourceLoc ClubMembersPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_clubMembers_edges_node_user = {
    fullName: option<string>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and response_clubMembers_edges_node = {
    @live id: string,
    isAdmin: option<bool>,
    isOwner: option<bool>,
    joinDate: option<Util.Datetime.t>,
    status: option<RelaySchemaAssets_graphql.enum_T>,
    user: option<response_clubMembers_edges_node_user>,
  }
  and response_clubMembers_edges = {
    node: option<response_clubMembers_edges_node>,
  }
  and response_clubMembers_pageInfo = {
    endCursor: option<string>,
    hasNextPage: bool,
    hasPreviousPage: bool,
    startCursor: option<string>,
  }
  and response_clubMembers = {
    @live __id: RescriptRelay.dataId,
    edges: option<array<option<response_clubMembers_edges>>>,
    pageInfo: response_clubMembers_pageInfo,
  }
  type response = {
    @live __id: RescriptRelay.dataId,
    clubMembers: response_clubMembers,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    after?: string,
    clubId: string,
    first?: int,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    clubId: option<string>,
    first: option<option<int>>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~clubId=?,
    ~first=?,
  ): refetchVariables => {
    after: after,
    clubId: clubId,
    first: first
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{}`
  )
  @live
  let variablesConverterMap = ()
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
    json`{"__root":{"clubMembers_edges_node_joinDate":{"c":"Util.Datetime"}}}`
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
    json`{"__root":{"clubMembers_edges_node_joinDate":{"c":"Util.Datetime"}}}`
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
  type rawPreloadToken<'response> = {source: Js.Nullable.t<RescriptRelay.Observable.t<'response>>}
  external tokenToRaw: queryRef => rawPreloadToken<Types.response> = "%identity"
}
@live
@inline
let connectionKey = "ClubMembersPageMembersQuery_clubMembers"

%%private(
  @live @module("relay-runtime") @scope("ConnectionHandler")
  external internal_makeConnectionId: (RescriptRelay.dataId, @as("ClubMembersPageMembersQuery_clubMembers") _, 'arguments) => RescriptRelay.dataId = "getConnectionID"
)

@live
let makeConnectionId = (connectionParentDataId: RescriptRelay.dataId, ~clubId: string) => {
  let clubId = Some(clubId)
  let args = {"input": {"clubId": clubId}}
  internal_makeConnectionId(connectionParentDataId, args)
}
module Utils = {
  @@warning("-33")
  open Types

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
type operationType = RescriptRelay.queryNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "after"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "clubId"
},
v2 = {
  "defaultValue": 20,
  "kind": "LocalArgument",
  "name": "first"
},
v3 = {
  "fields": [
    {
      "kind": "Variable",
      "name": "clubId",
      "variableName": "clubId"
    }
  ],
  "kind": "ObjectValue",
  "name": "input"
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v5 = {
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
},
v6 = [
  {
    "alias": null,
    "args": null,
    "concreteType": "MembershipEdge",
    "kind": "LinkedField",
    "name": "edges",
    "plural": true,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Membership",
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          (v4/*: any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "isAdmin",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "isOwner",
            "storageKey": null
          },
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
            "name": "joinDate",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "user",
            "plural": false,
            "selections": [
              (v4/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "fullName",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "picture",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "lineUsername",
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
        "name": "hasPreviousPage",
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
  },
  (v5/*: any*/)
],
v7 = [
  {
    "kind": "Variable",
    "name": "after",
    "variableName": "after"
  },
  {
    "kind": "Variable",
    "name": "first",
    "variableName": "first"
  },
  (v3/*: any*/)
];
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "ClubMembersPageMembersQuery",
    "selections": [
      {
        "alias": "clubMembers",
        "args": [
          (v3/*: any*/)
        ],
        "concreteType": "MembershipConnection",
        "kind": "LinkedField",
        "name": "__ClubMembersPageMembersQuery_clubMembers_connection",
        "plural": false,
        "selections": (v6/*: any*/),
        "storageKey": null
      },
      (v5/*: any*/)
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v1/*: any*/),
      (v0/*: any*/),
      (v2/*: any*/)
    ],
    "kind": "Operation",
    "name": "ClubMembersPageMembersQuery",
    "selections": [
      {
        "alias": null,
        "args": (v7/*: any*/),
        "concreteType": "MembershipConnection",
        "kind": "LinkedField",
        "name": "clubMembers",
        "plural": false,
        "selections": (v6/*: any*/),
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v7/*: any*/),
        "filters": [
          "input"
        ],
        "handle": "connection",
        "key": "ClubMembersPageMembersQuery_clubMembers",
        "kind": "LinkedHandle",
        "name": "clubMembers"
      },
      (v5/*: any*/)
    ]
  },
  "params": {
    "cacheID": "eaa4e82a100efe334847312a05c6ee4d",
    "id": null,
    "metadata": {
      "connection": [
        {
          "count": "first",
          "cursor": "after",
          "direction": "forward",
          "path": [
            "clubMembers"
          ]
        }
      ]
    },
    "name": "ClubMembersPageMembersQuery",
    "operationKind": "query",
    "text": "query ClubMembersPageMembersQuery(\n  $clubId: ID!\n  $after: String\n  $first: Int = 20\n) {\n  clubMembers(input: {clubId: $clubId}, after: $after, first: $first) {\n    edges {\n      node {\n        id\n        isAdmin\n        isOwner\n        status\n        joinDate\n        user {\n          id\n          fullName\n          picture\n          lineUsername\n        }\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      startCursor\n      endCursor\n    }\n  }\n}\n"
  }
};
})() `)

let load: (
  ~environment: RescriptRelay.Environment.t,
  ~variables: Types.variables,
  ~fetchPolicy: RescriptRelay.fetchPolicy=?,
  ~fetchKey: string=?,
  ~networkCacheConfig: RescriptRelay.cacheConfig=?,
) => queryRef = (
  ~environment,
  ~variables,
  ~fetchPolicy=?,
  ~fetchKey=?,
  ~networkCacheConfig=?,
) =>
  RescriptRelay.loadQuery(
    environment,
    node,
    variables->Internal.convertVariables,
    {
      fetchKey,
      fetchPolicy,
      networkCacheConfig,
    },
  )
  
let queryRefToObservable = token => {
  let raw = token->Internal.tokenToRaw
  raw.source->Js.Nullable.toOption
}
  
let queryRefToPromise = token => {
  Js.Promise.make((~resolve, ~reject as _) => {
    switch token->queryRefToObservable {
    | None => resolve(Error())
    | Some(o) =>
      open RescriptRelay.Observable
      let _: subscription = o->subscribe(makeObserver(~complete=() => resolve(Ok())))
    }
  })
}

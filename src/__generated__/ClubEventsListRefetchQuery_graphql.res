/* @sourceLoc ClubEventsList.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_node = {
    @live __typename: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ClubEventsListFragment]>,
  }
  @live
  type response = {
    node: option<response_node>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    after?: string,
    afterDate?: Util.Datetime.t,
    before?: string,
    first?: int,
    @live id: string,
    level?: float,
    token?: string,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    afterDate: option<option<Util.Datetime.t>>,
    before: option<option<string>>,
    first: option<option<int>>,
    @live id: option<string>,
    level: option<option<float>>,
    token: option<option<string>>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~afterDate=?,
    ~before=?,
    ~first=?,
    ~id=?,
    ~level=?,
    ~token=?,
  ): refetchVariables => {
    after: after,
    afterDate: afterDate,
    before: before,
    first: first,
    id: id,
    level: level,
    token: token
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"afterDate":{"c":"Util.Datetime"}}}`
  )
  @live
  let variablesConverterMap = {
    "Util.Datetime": Util.Datetime.serialize,
  }
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
    json`{"__root":{"node":{"f":""}}}`
  )
  @live
  let wrapResponseConverterMap = ()
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
    json`{"__root":{"node":{"f":""}}}`
  )
  @live
  let responseConverterMap = ()
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
module Utils = {
  @@warning("-33")
  open Types
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
  "name": "afterDate"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "before"
},
v3 = {
  "defaultValue": 20,
  "kind": "LocalArgument",
  "name": "first"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "id"
},
v5 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "level"
},
v6 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "token"
},
v7 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "id"
  }
],
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v9 = {
  "kind": "Variable",
  "name": "after",
  "variableName": "after"
},
v10 = {
  "kind": "Variable",
  "name": "afterDate",
  "variableName": "afterDate"
},
v11 = {
  "kind": "Variable",
  "name": "before",
  "variableName": "before"
},
v12 = {
  "kind": "Variable",
  "name": "first",
  "variableName": "first"
},
v13 = {
  "kind": "Variable",
  "name": "level",
  "variableName": "level"
},
v14 = {
  "kind": "Variable",
  "name": "token",
  "variableName": "token"
},
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v16 = [
  (v15/*: any*/)
],
v17 = [
  (v9/*: any*/),
  (v10/*: any*/),
  (v11/*: any*/),
  {
    "fields": [
      (v13/*: any*/)
    ],
    "kind": "ObjectValue",
    "name": "filters"
  },
  (v12/*: any*/),
  (v14/*: any*/)
],
v18 = [
  (v15/*: any*/),
  {
    "alias": null,
    "args": null,
    "kind": "ScalarField",
    "name": "name",
    "storageKey": null
  }
],
v19 = [
  {
    "kind": "Literal",
    "name": "first",
    "value": 100
  }
],
v20 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cursor",
  "storageKey": null
},
v21 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endCursor",
  "storageKey": null
},
v22 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "hasNextPage",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/),
      (v5/*: any*/),
      (v6/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "ClubEventsListRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": (v7/*: any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          (v8/*: any*/),
          {
            "args": [
              (v9/*: any*/),
              (v10/*: any*/),
              (v11/*: any*/),
              (v12/*: any*/),
              (v13/*: any*/),
              (v14/*: any*/)
            ],
            "kind": "FragmentSpread",
            "name": "ClubEventsListFragment"
          }
        ],
        "storageKey": null
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v5/*: any*/),
      (v6/*: any*/),
      (v4/*: any*/)
    ],
    "kind": "Operation",
    "name": "ClubEventsListRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": (v7/*: any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          (v8/*: any*/),
          (v15/*: any*/),
          {
            "kind": "InlineFragment",
            "selections": [
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
                "concreteType": "Activity",
                "kind": "LinkedField",
                "name": "defaultActivity",
                "plural": false,
                "selections": (v16/*: any*/),
                "storageKey": null
              },
              {
                "alias": null,
                "args": (v17/*: any*/),
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
                          (v15/*: any*/),
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
                            "kind": "ScalarField",
                            "name": "maxRsvps",
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "listed",
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
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "deleted",
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "concreteType": "Club",
                            "kind": "LinkedField",
                            "name": "club",
                            "plural": false,
                            "selections": (v18/*: any*/),
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "concreteType": "Location",
                            "kind": "LinkedField",
                            "name": "location",
                            "plural": false,
                            "selections": (v18/*: any*/),
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": (v19/*: any*/),
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
                                      (v15/*: any*/),
                                      {
                                        "alias": null,
                                        "args": null,
                                        "kind": "ScalarField",
                                        "name": "listType",
                                        "storageKey": null
                                      },
                                      {
                                        "alias": null,
                                        "args": null,
                                        "concreteType": "User",
                                        "kind": "LinkedField",
                                        "name": "user",
                                        "plural": false,
                                        "selections": (v16/*: any*/),
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
                                          {
                                            "alias": null,
                                            "args": null,
                                            "kind": "ScalarField",
                                            "name": "mu",
                                            "storageKey": null
                                          },
                                          (v15/*: any*/)
                                        ],
                                        "storageKey": null
                                      },
                                      (v8/*: any*/)
                                    ],
                                    "storageKey": null
                                  },
                                  (v20/*: any*/)
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
                                  (v21/*: any*/),
                                  (v22/*: any*/)
                                ],
                                "storageKey": null
                              }
                            ],
                            "storageKey": "rsvps(first:100)"
                          },
                          {
                            "alias": null,
                            "args": (v19/*: any*/),
                            "filters": null,
                            "handle": "connection",
                            "key": "PkEventRow_event_rsvps",
                            "kind": "LinkedHandle",
                            "name": "rsvps"
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "title",
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "endDate",
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "tags",
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "cancelDeadline",
                            "storageKey": null
                          },
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
                          },
                          (v8/*: any*/)
                        ],
                        "storageKey": null
                      },
                      (v20/*: any*/)
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
                      (v22/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "hasPreviousPage",
                        "storageKey": null
                      },
                      (v21/*: any*/),
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
              {
                "alias": null,
                "args": (v17/*: any*/),
                "filters": [
                  "afterDate",
                  "token",
                  "filters"
                ],
                "handle": "connection",
                "key": "ClubEventsListFragment_events",
                "kind": "LinkedHandle",
                "name": "events"
              }
            ],
            "type": "Club",
            "abstractKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "5808b9afc62a8eff306b5217fb2fb8ee",
    "id": null,
    "metadata": {},
    "name": "ClubEventsListRefetchQuery",
    "operationKind": "query",
    "text": "query ClubEventsListRefetchQuery(\n  $after: String\n  $afterDate: Datetime\n  $before: String\n  $first: Int = 20\n  $level: Float\n  $token: String\n  $id: ID!\n) {\n  node(id: $id) {\n    __typename\n    ...ClubEventsListFragment_22cWgY\n    id\n  }\n}\n\nfragment ClubEventsListFragment_22cWgY on Club {\n  id\n  slug\n  defaultActivity {\n    id\n  }\n  events(after: $after, first: $first, before: $before, afterDate: $afterDate, token: $token, filters: {level: $level}) {\n    edges {\n      node {\n        id\n        startDate\n        timezone\n        maxRsvps\n        listed\n        shadow\n        deleted\n        club {\n          id\n        }\n        location {\n          id\n        }\n        rsvps(first: 100) {\n          edges {\n            node {\n              id\n              listType\n            }\n          }\n        }\n        ...PkEventRow_event\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment PkEventRow_event on Event {\n  id\n  title\n  location {\n    id\n    name\n  }\n  club {\n    name\n    id\n  }\n  maxRsvps\n  rsvps(first: 100) {\n    edges {\n      node {\n        id\n        user {\n          id\n        }\n        listType\n        rating {\n          mu\n          id\n        }\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n  startDate\n  endDate\n  timezone\n  shadow\n  listed\n  deleted\n  tags\n  cancelDeadline\n}\n"
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

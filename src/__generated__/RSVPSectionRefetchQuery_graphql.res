/* @sourceLoc RSVPSection.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_node = {
    @live __typename: string,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #RSVPSection_event]>,
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
    before?: string,
    first?: int,
    @live id: string,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    before: option<option<string>>,
    first: option<option<int>>,
    @live id: option<string>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~before=?,
    ~first=?,
    ~id=?,
  ): refetchVariables => {
    after: after,
    before: before,
    first: first,
    id: id
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
var v0 = [
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
    "defaultValue": 80,
    "kind": "LocalArgument",
    "name": "first"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "id"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "id"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v3 = [
  {
    "kind": "Variable",
    "name": "after",
    "variableName": "after"
  },
  {
    "kind": "Variable",
    "name": "before",
    "variableName": "before"
  },
  {
    "kind": "Variable",
    "name": "first",
    "variableName": "first"
  }
],
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "RSVPSectionRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          (v2/*: any*/),
          {
            "args": (v3/*: any*/),
            "kind": "FragmentSpread",
            "name": "RSVPSection_event"
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
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "RSVPSectionRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": null,
        "kind": "LinkedField",
        "name": "node",
        "plural": false,
        "selections": [
          (v2/*: any*/),
          (v4/*: any*/),
          {
            "kind": "InlineFragment",
            "selections": [
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
                "name": "minRating",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "viewerIsAdmin",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "Activity",
                "kind": "LinkedField",
                "name": "activity",
                "plural": false,
                "selections": [
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "slug",
                    "storageKey": null
                  },
                  (v4/*: any*/)
                ],
                "storageKey": null
              },
              {
                "alias": null,
                "args": (v3/*: any*/),
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
                          (v4/*: any*/),
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
                            "concreteType": "Rating",
                            "kind": "LinkedField",
                            "name": "rating",
                            "plural": false,
                            "selections": [
                              {
                                "alias": null,
                                "args": null,
                                "kind": "ScalarField",
                                "name": "ordinal",
                                "storageKey": null
                              },
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
                              (v4/*: any*/)
                            ],
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "message",
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "listType",
                            "storageKey": null
                          },
                          (v2/*: any*/)
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
              {
                "alias": null,
                "args": (v3/*: any*/),
                "filters": null,
                "handle": "connection",
                "key": "RSVPSection_event_rsvps",
                "kind": "LinkedHandle",
                "name": "rsvps"
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
              }
            ],
            "type": "Event",
            "abstractKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "4ae01fe434962c2b559e4d2eb1de42c7",
    "id": null,
    "metadata": {},
    "name": "RSVPSectionRefetchQuery",
    "operationKind": "query",
    "text": "query RSVPSectionRefetchQuery(\n  $after: String\n  $before: String\n  $first: Int = 80\n  $id: ID!\n) {\n  node(id: $id) {\n    __typename\n    ...RSVPSection_event_4uAqg1\n    id\n  }\n}\n\nfragment EventRsvpUser_user on User {\n  picture\n  lineUsername\n  ...RsvpOptions_user\n}\n\nfragment EventRsvp_rsvp on Rsvp {\n  user {\n    id\n    ...EventRsvpUser_user\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n  message\n}\n\nfragment GoingRsvps_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment MiniEventRsvp_rsvp on Rsvp {\n  user {\n    id\n    picture\n    lineUsername\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment PendingRsvps_event_4uAqg1 on Event {\n  id\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment RSVPSection_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  minRating\n  viewerIsAdmin\n  activity {\n    slug\n    id\n  }\n  ...RsvpWaitlist_event_4uAqg1\n  ...GoingRsvps_event_4uAqg1\n  ...PendingRsvps_event_4uAqg1\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n\nfragment RsvpOptions_user on User {\n  id\n}\n\nfragment RsvpWaitlist_event_4uAqg1 on Event {\n  id\n  maxRsvps\n  viewerIsAdmin\n  rsvps(after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        ...EventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          picture\n          lineUsername\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        listType\n        message\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n    }\n  }\n}\n"
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

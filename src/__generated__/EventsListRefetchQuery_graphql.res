/* @sourceLoc EventsList.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type eventFilters = RelaySchemaAssets_graphql.input_EventFilters
  @live
  type response = {
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventsListFragment]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    after?: string,
    afterDate?: Util.Datetime.t,
    before?: string,
    filters?: eventFilters,
    first?: int,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    afterDate: option<option<Util.Datetime.t>>,
    before: option<option<string>>,
    filters: option<option<eventFilters>>,
    first: option<option<int>>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~afterDate=?,
    ~before=?,
    ~filters=?,
    ~first=?,
  ): refetchVariables => {
    after: after,
    afterDate: afterDate,
    before: before,
    filters: filters,
    first: first
  }

}


type queryRef

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"eventFilters":{},"__root":{"filters":{"r":"eventFilters"},"afterDate":{"c":"Util.Datetime"}}}`
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
    json`{"__root":{"":{"f":""}}}`
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
    json`{"__root":{"":{"f":""}}}`
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
v1 = [
  {
    "kind": "Variable",
    "name": "after",
    "variableName": "after"
  },
  {
    "kind": "Variable",
    "name": "afterDate",
    "variableName": "afterDate"
  },
  {
    "kind": "Variable",
    "name": "before",
    "variableName": "before"
  },
  {
    "kind": "Variable",
    "name": "filters",
    "variableName": "filters"
  },
  {
    "kind": "Variable",
    "name": "first",
    "variableName": "first"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "EventsListRefetchQuery",
    "selections": [
      {
        "args": (v1/*: any*/),
        "kind": "FragmentSpread",
        "name": "EventsListFragment"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "EventsListRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
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
                  (v2/*: any*/),
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
                    "concreteType": "Location",
                    "kind": "LinkedField",
                    "name": "location",
                    "plural": false,
                    "selections": [
                      (v2/*: any*/),
                      (v3/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "links",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "Coords",
                        "kind": "LinkedField",
                        "name": "coords",
                        "plural": false,
                        "selections": [
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "lng",
                            "storageKey": null
                          },
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "lat",
                            "storageKey": null
                          }
                        ],
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "address",
                        "storageKey": null
                      }
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
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "title",
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
                      (v3/*: any*/),
                      (v2/*: any*/)
                    ],
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "viewerRsvpStatus",
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
                              (v2/*: any*/)
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
                    "name": "endDate",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "details",
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
      {
        "alias": null,
        "args": (v1/*: any*/),
        "filters": [
          "filters",
          "afterDate"
        ],
        "handle": "connection",
        "key": "EventsListFragment_events",
        "kind": "LinkedHandle",
        "name": "events"
      }
    ]
  },
  "params": {
    "cacheID": "dcc21831a9188cf1ccdb03e5249a7121",
    "id": null,
    "metadata": {},
    "name": "EventsListRefetchQuery",
    "operationKind": "query",
    "text": "query EventsListRefetchQuery(\n  $after: String\n  $afterDate: Datetime\n  $before: String\n  $filters: EventFilters\n  $first: Int = 20\n) {\n  ...EventsListFragment_N8DiW\n}\n\nfragment EventsListFragment_N8DiW on Query {\n  events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate) {\n    edges {\n      node {\n        id\n        startDate\n        location {\n          id\n        }\n        shadow\n        ...EventsList_event\n        ...EventsListText_event\n        __typename\n      }\n      cursor\n    }\n    ...PinMap_eventConnection\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment EventsListText_event on Event {\n  id\n  title\n  details\n  activity {\n    name\n    id\n  }\n  location {\n    name\n    links\n    id\n  }\n  rsvps {\n    edges {\n      node {\n        id\n      }\n    }\n  }\n  maxRsvps\n  startDate\n  endDate\n  shadow\n}\n\nfragment EventsList_event on Event {\n  id\n  title\n  activity {\n    name\n    id\n  }\n  location {\n    id\n    name\n  }\n  viewerRsvpStatus\n  maxRsvps\n  rsvps {\n    edges {\n      node {\n        id\n      }\n    }\n  }\n  startDate\n  endDate\n  shadow\n}\n\nfragment PinMap_eventConnection on EventConnection {\n  edges {\n    node {\n      id\n      startDate\n      location {\n        id\n        coords {\n          lng\n          lat\n        }\n        address\n      }\n    }\n  }\n}\n"
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

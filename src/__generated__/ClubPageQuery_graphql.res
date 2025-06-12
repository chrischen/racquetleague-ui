/* @sourceLoc ClubPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type eventFilters = RelaySchemaAssets_graphql.input_EventFilters
  type rec response_club = {
    name: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ClubDetails_club | #ClubEventsListFragment]>,
  }
  type response = {
    club: option<response_club>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #CalendarEventsFragment | #EventsListFragment]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    after?: string,
    afterDate?: Util.Datetime.t,
    before?: string,
    filters: eventFilters,
    first?: int,
    slug: string,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    afterDate: option<option<Util.Datetime.t>>,
    before: option<option<string>>,
    filters: option<eventFilters>,
    first: option<option<int>>,
    slug: option<string>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~afterDate=?,
    ~before=?,
    ~filters=?,
    ~first=?,
    ~slug=?,
  ): refetchVariables => {
    after: after,
    afterDate: afterDate,
    before: before,
    filters: filters,
    first: first,
    slug: slug
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
    json`{"__root":{"club":{"f":""},"":{"f":""}}}`
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
    json`{"__root":{"club":{"f":""},"":{"f":""}}}`
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
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "filters"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "first"
},
v5 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "slug"
},
v6 = [
  {
    "kind": "Variable",
    "name": "slug",
    "variableName": "slug"
  }
],
v7 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v8 = {
  "kind": "Variable",
  "name": "after",
  "variableName": "after"
},
v9 = {
  "kind": "Variable",
  "name": "afterDate",
  "variableName": "afterDate"
},
v10 = {
  "kind": "Variable",
  "name": "before",
  "variableName": "before"
},
v11 = {
  "kind": "Variable",
  "name": "first",
  "variableName": "first"
},
v12 = [
  (v8/*: any*/),
  (v9/*: any*/),
  (v10/*: any*/),
  {
    "kind": "Variable",
    "name": "filters",
    "variableName": "filters"
  },
  (v11/*: any*/)
],
v13 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": (v12/*: any*/),
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
            (v13/*: any*/),
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
                (v13/*: any*/),
                (v7/*: any*/),
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
                (v7/*: any*/),
                (v13/*: any*/)
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
                        (v13/*: any*/),
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
              "name": "deleted",
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
v15 = [
  "filters",
  "afterDate"
],
v16 = {
  "alias": null,
  "args": (v12/*: any*/),
  "filters": (v15/*: any*/),
  "handle": "connection",
  "key": "EventsListFragment_events",
  "kind": "LinkedHandle",
  "name": "events"
};
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v4/*: any*/),
      (v5/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "ClubPageQuery",
    "selections": [
      {
        "alias": null,
        "args": (v6/*: any*/),
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
        "plural": false,
        "selections": [
          (v7/*: any*/),
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "ClubDetails_club"
          },
          {
            "args": [
              (v8/*: any*/),
              (v9/*: any*/),
              (v10/*: any*/),
              (v11/*: any*/)
            ],
            "kind": "FragmentSpread",
            "name": "ClubEventsListFragment"
          }
        ],
        "storageKey": null
      },
      {
        "args": (v12/*: any*/),
        "kind": "FragmentSpread",
        "name": "EventsListFragment"
      },
      {
        "args": (v12/*: any*/),
        "kind": "FragmentSpread",
        "name": "CalendarEventsFragment"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v5/*: any*/),
      (v0/*: any*/),
      (v4/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Operation",
    "name": "ClubPageQuery",
    "selections": [
      {
        "alias": null,
        "args": (v6/*: any*/),
        "concreteType": "Club",
        "kind": "LinkedField",
        "name": "club",
        "plural": false,
        "selections": [
          (v7/*: any*/),
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "description",
            "storageKey": null
          },
          (v14/*: any*/),
          (v16/*: any*/),
          (v13/*: any*/)
        ],
        "storageKey": null
      },
      (v14/*: any*/),
      (v16/*: any*/),
      {
        "alias": null,
        "args": (v12/*: any*/),
        "filters": (v15/*: any*/),
        "handle": "connection",
        "key": "CalendarEventsFragment_events",
        "kind": "LinkedHandle",
        "name": "events"
      }
    ]
  },
  "params": {
    "cacheID": "c7f1e7c4bd538b8f87e78eae90a0dace",
    "id": null,
    "metadata": {},
    "name": "ClubPageQuery",
    "operationKind": "query",
    "text": "query ClubPageQuery(\n  $slug: String!\n  $after: String\n  $first: Int\n  $before: String\n  $filters: EventFilters!\n  $afterDate: Datetime\n) {\n  club(slug: $slug) {\n    name\n    ...ClubDetails_club\n    ...ClubEventsListFragment_4ysDAd\n    id\n  }\n  ...EventsListFragment_N8DiW\n  ...CalendarEventsFragment_N8DiW\n}\n\nfragment CalendarEventsFragment_N8DiW on Query {\n  events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate) {\n    edges {\n      node {\n        id\n        startDate\n        timezone\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment ClubDetails_club on Club {\n  name\n  description\n}\n\nfragment ClubEventsListFragment_4ysDAd on Club {\n  events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate) {\n    edges {\n      node {\n        id\n        startDate\n        timezone\n        location {\n          id\n        }\n        shadow\n        ...ClubEventsList_event\n        ...ClubEventsListText_event\n        __typename\n      }\n      cursor\n    }\n    ...PinMap_eventConnection\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n  id\n}\n\nfragment ClubEventsListText_event on Event {\n  id\n  title\n  details\n  activity {\n    name\n    id\n  }\n  location {\n    name\n    links\n    id\n  }\n  rsvps {\n    edges {\n      node {\n        id\n        listType\n      }\n    }\n  }\n  maxRsvps\n  startDate\n  endDate\n  timezone\n  shadow\n  deleted\n}\n\nfragment ClubEventsList_event on Event {\n  id\n  title\n  activity {\n    name\n    id\n  }\n  location {\n    id\n    name\n  }\n  viewerRsvpStatus\n  maxRsvps\n  rsvps {\n    edges {\n      node {\n        id\n        listType\n      }\n    }\n  }\n  startDate\n  endDate\n  timezone\n  shadow\n  deleted\n}\n\nfragment EventsListFragment_N8DiW on Query {\n  events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate) {\n    edges {\n      node {\n        id\n        startDate\n        timezone\n        location {\n          id\n        }\n        shadow\n        ...EventsList_event\n        ...EventsListText_event\n        __typename\n      }\n      cursor\n    }\n    ...PinMap_eventConnection\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment EventsListText_event on Event {\n  id\n  title\n  details\n  activity {\n    name\n    id\n  }\n  location {\n    name\n    links\n    id\n  }\n  rsvps {\n    edges {\n      node {\n        id\n        listType\n      }\n    }\n  }\n  maxRsvps\n  startDate\n  endDate\n  timezone\n  shadow\n  deleted\n}\n\nfragment EventsList_event on Event {\n  id\n  title\n  activity {\n    name\n    id\n  }\n  location {\n    id\n    name\n  }\n  viewerRsvpStatus\n  maxRsvps\n  rsvps {\n    edges {\n      node {\n        id\n        listType\n      }\n    }\n  }\n  startDate\n  endDate\n  timezone\n  shadow\n  deleted\n}\n\nfragment PinMap_eventConnection on EventConnection {\n  edges {\n    node {\n      id\n      startDate\n      location {\n        id\n        coords {\n          lng\n          lat\n        }\n        address\n      }\n    }\n  }\n}\n"
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

/* @sourceLoc EventManager.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_event_rsvps_edges_node_user_rating = {
    @live id: string,
    mu: option<float>,
    sigma: option<float>,
  }
  and response_event_rsvps_edges_node_user = {
    @live id: string,
    rating: option<response_event_rsvps_edges_node_user_rating>,
  }
  and response_event_rsvps_edges_node = {
    user: option<response_event_rsvps_edges_node_user>,
  }
  and response_event_rsvps_edges = {
    node: option<response_event_rsvps_edges_node>,
  }
  and response_event_rsvps = {
    edges: option<array<option<response_event_rsvps_edges>>>,
  }
  and response_event = {
    @live id: string,
    rsvps: option<response_event_rsvps>,
  }
  type response = {
    event: option<response_event>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activitySlug: string,
    clubId: string,
    eventId: string,
    namespace: string,
  }
  @live
  type refetchVariables = {
    activitySlug: option<string>,
    clubId: option<string>,
    eventId: option<string>,
    namespace: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activitySlug=?,
    ~clubId=?,
    ~eventId=?,
    ~namespace=?,
  ): refetchVariables => {
    activitySlug: activitySlug,
    clubId: clubId,
    eventId: eventId,
    namespace: namespace
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
    json`{}`
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
    json`{}`
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
  "name": "activitySlug"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "clubId"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "eventId"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "namespace"
},
v4 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "eventId"
  }
],
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v6 = [
  {
    "kind": "Literal",
    "name": "first",
    "value": 100
  }
],
v7 = {
  "alias": null,
  "args": null,
  "concreteType": "User",
  "kind": "LinkedField",
  "name": "user",
  "plural": false,
  "selections": [
    (v5/*: any*/),
    {
      "alias": null,
      "args": [
        {
          "kind": "Variable",
          "name": "activitySlug",
          "variableName": "activitySlug"
        },
        {
          "kind": "Variable",
          "name": "clubId",
          "variableName": "clubId"
        },
        {
          "kind": "Variable",
          "name": "namespace",
          "variableName": "namespace"
        }
      ],
      "concreteType": "Rating",
      "kind": "LinkedField",
      "name": "rating",
      "plural": false,
      "selections": [
        (v5/*: any*/),
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
        }
      ],
      "storageKey": null
    }
  ],
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": [
      (v0/*: any*/),
      (v1/*: any*/),
      (v2/*: any*/),
      (v3/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "EventManagerClubRatingsQuery",
    "selections": [
      {
        "alias": null,
        "args": (v4/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          {
            "alias": null,
            "args": (v6/*: any*/),
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
                      (v7/*: any*/)
                    ],
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": "rsvps(first:100)"
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
      (v2/*: any*/),
      (v0/*: any*/),
      (v3/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Operation",
    "name": "EventManagerClubRatingsQuery",
    "selections": [
      {
        "alias": null,
        "args": (v4/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          {
            "alias": null,
            "args": (v6/*: any*/),
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
                      (v7/*: any*/),
                      (v5/*: any*/)
                    ],
                    "storageKey": null
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": "rsvps(first:100)"
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "afeacaca3566549f8a4d6730c1f668c8",
    "id": null,
    "metadata": {},
    "name": "EventManagerClubRatingsQuery",
    "operationKind": "query",
    "text": "query EventManagerClubRatingsQuery(\n  $eventId: ID!\n  $activitySlug: String!\n  $namespace: String!\n  $clubId: ID!\n) {\n  event(id: $eventId) {\n    id\n    rsvps(first: 100) {\n      edges {\n        node {\n          user {\n            id\n            rating(activitySlug: $activitySlug, clubId: $clubId, namespace: $namespace) {\n              id\n              mu\n              sigma\n            }\n          }\n          id\n        }\n      }\n    }\n  }\n}\n"
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

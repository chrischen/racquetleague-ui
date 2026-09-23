/* @sourceLoc PkEventPage.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_event_activity = {
    name: option<string>,
    slug: option<string>,
  }
  and response_event_club_viewerMembership = {
    status: option<RelaySchemaAssets_graphql.enum_T>,
  }
  and response_event_club = {
    exemptMembersFromPayment: bool,
    @live id: string,
    name: option<string>,
    slug: option<string>,
    viewerMembership: option<response_event_club_viewerMembership>,
  }
  and response_event_location_coords = {
    lat: float,
    lng: float,
  }
  and response_event_location = {
    address: option<string>,
    coords: option<response_event_location_coords>,
    details: option<string>,
    @live id: string,
    links: option<array<string>>,
    name: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #LocationMap_location]>,
  }
  and response_event_owner = {
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  and response_event_rsvps_edges_node_payment = {
    currency: string,
    @live id: string,
    status: int,
  }
  and response_event_rsvps_edges_node_user = {
    @live id: string,
  }
  and response_event_rsvps_edges_node = {
    @live id: string,
    joinTime: option<float>,
    listType: option<int>,
    payment: option<response_event_rsvps_edges_node_payment>,
    user: option<response_event_rsvps_edges_node_user>,
  }
  and response_event_rsvps_edges = {
    node: option<response_event_rsvps_edges_node>,
  }
  and response_event_rsvps = {
    edges: option<array<option<response_event_rsvps_edges>>>,
  }
  and response_event = {
    @live __id: RescriptRelay.dataId,
    activity: option<response_event_activity>,
    cancelDeadline: option<int>,
    chargesEnabled: bool,
    club: option<response_event_club>,
    deleted: option<Util.Datetime.t>,
    details: option<string>,
    endDate: option<Util.Datetime.t>,
    @live id: string,
    listed: option<bool>,
    location: option<response_event_location>,
    maxRsvps: option<int>,
    minRating: option<float>,
    owner: option<response_event_owner>,
    price: option<int>,
    rsvps: option<response_event_rsvps>,
    shadow: option<bool>,
    startDate: option<Util.Datetime.t>,
    tags: option<array<string>>,
    timezone: option<string>,
    title: option<string>,
    viewerIsAdmin: bool,
    viewerIsBanned: option<bool>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventLocationAvailability_event | #PkRSVPSection_event]>,
  }
  and response_viewer_savedCard = {
    brand: string,
    last4: string,
  }
  and response_viewer_user_eventRating = {
    @live id: string,
  }
  and response_viewer_user = {
    email: option<string>,
    eventRating: option<response_viewer_user_eventRating>,
    @live id: string,
    lineUsername: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkRSVPSection_user]>,
  }
  and response_viewer = {
    savedCard: option<response_viewer_savedCard>,
    user: option<response_viewer_user>,
  }
  type response = {
    event: option<response_event>,
    viewer: option<response_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PkEventMessages_query | #UseProfileGate_query]>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    after?: string,
    before?: string,
    eventId: string,
    first?: int,
    topic: string,
  }
  @live
  type refetchVariables = {
    after: option<option<string>>,
    before: option<option<string>>,
    eventId: option<string>,
    first: option<option<int>>,
    topic: option<string>,
  }
  @live let makeRefetchVariables = (
    ~after=?,
    ~before=?,
    ~eventId=?,
    ~first=?,
    ~topic=?,
  ): refetchVariables => {
    after: after,
    before: before,
    eventId: eventId,
    first: first,
    topic: topic
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_location":{"f":""},"event_endDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event":{"f":""},"":{"f":""}}}`
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
    json`{"__root":{"viewer_user":{"f":""},"event_startDate":{"c":"Util.Datetime"},"event_location":{"f":""},"event_endDate":{"c":"Util.Datetime"},"event_deleted":{"c":"Util.Datetime"},"event":{"f":""},"":{"f":""}}}`
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
let connectionKey = "PkRSVPSection_event_rsvps"

%%private(
  @live @module("relay-runtime") @scope("ConnectionHandler")
  external internal_makeConnectionId: (RescriptRelay.dataId, @as("PkRSVPSection_event_rsvps") _, 'arguments) => RescriptRelay.dataId = "getConnectionID"
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
  "name": "before"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "eventId"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "first"
},
v4 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "topic"
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v6 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "email",
  "storageKey": null
},
v8 = [
  {
    "kind": "Variable",
    "name": "eventId",
    "variableName": "eventId"
  }
],
v9 = [
  (v5/*: any*/)
],
v10 = {
  "alias": null,
  "args": null,
  "concreteType": "SavedCard",
  "kind": "LinkedField",
  "name": "savedCard",
  "plural": false,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "brand",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "last4",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v11 = [
  {
    "kind": "Variable",
    "name": "id",
    "variableName": "eventId"
  }
],
v12 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "title",
  "storageKey": null
},
v13 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "startDate",
  "storageKey": null
},
v14 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "endDate",
  "storageKey": null
},
v15 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "timezone",
  "storageKey": null
},
v16 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "tags",
  "storageKey": null
},
v17 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "listed",
  "storageKey": null
},
v18 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "viewerIsAdmin",
  "storageKey": null
},
v19 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "viewerIsBanned",
  "storageKey": null
},
v20 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "deleted",
  "storageKey": null
},
v21 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "shadow",
  "storageKey": null
},
v22 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "details",
  "storageKey": null
},
v23 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "maxRsvps",
  "storageKey": null
},
v24 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "minRating",
  "storageKey": null
},
v25 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cancelDeadline",
  "storageKey": null
},
v26 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "price",
  "storageKey": null
},
v27 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v28 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "slug",
  "storageKey": null
},
v29 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "chargesEnabled",
  "storageKey": null
},
v30 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "exemptMembersFromPayment",
  "storageKey": null
},
v31 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "status",
  "storageKey": null
},
v32 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "address",
  "storageKey": null
},
v33 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "links",
  "storageKey": null
},
v34 = {
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
      "name": "lat",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "lng",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v35 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "picture",
  "storageKey": null
},
v36 = {
  "alias": null,
  "args": null,
  "concreteType": "User",
  "kind": "LinkedField",
  "name": "owner",
  "plural": false,
  "selections": [
    (v5/*: any*/),
    (v6/*: any*/),
    (v35/*: any*/)
  ],
  "storageKey": null
},
v37 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "listType",
  "storageKey": null
},
v38 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "joinTime",
  "storageKey": null
},
v39 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "currency",
  "storageKey": null
},
v40 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "__typename",
  "storageKey": null
},
v41 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "cursor",
  "storageKey": null
},
v42 = {
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
      "name": "endCursor",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "hasNextPage",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v43 = {
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
v44 = [
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
  },
  {
    "kind": "Variable",
    "name": "topic",
    "variableName": "topic"
  }
],
v45 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "biography",
  "storageKey": null
},
v46 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "gender",
  "storageKey": null
},
v47 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "selfRating",
  "storageKey": null
},
v48 = {
  "alias": null,
  "args": null,
  "concreteType": "DuprLink",
  "kind": "LinkedField",
  "name": "dupr",
  "plural": false,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "doubles",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "doublesReliable",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v49 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "ordinal",
  "storageKey": null
},
v50 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "mu",
  "storageKey": null
},
v51 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "sigma",
  "storageKey": null
},
v52 = [
  {
    "kind": "Literal",
    "name": "first",
    "value": 100
  }
],
v53 = {
  "alias": null,
  "args": null,
  "concreteType": "AvailabilityInterval",
  "kind": "LinkedField",
  "name": "intervals",
  "plural": true,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "startHour",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "endHour",
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
      (v3/*: any*/),
      (v4/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "PkEventPageQuery",
    "selections": [
      {
        "args": null,
        "kind": "FragmentSpread",
        "name": "UseProfileGate_query"
      },
      {
        "alias": null,
        "args": null,
        "concreteType": "Viewer",
        "kind": "LinkedField",
        "name": "viewer",
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
              (v5/*: any*/),
              (v6/*: any*/),
              (v7/*: any*/),
              {
                "alias": null,
                "args": (v8/*: any*/),
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "eventRating",
                "plural": false,
                "selections": (v9/*: any*/),
                "storageKey": null
              },
              {
                "args": (v8/*: any*/),
                "kind": "FragmentSpread",
                "name": "PkRSVPSection_user"
              }
            ],
            "storageKey": null
          },
          (v10/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v11/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/),
          (v16/*: any*/),
          (v17/*: any*/),
          (v18/*: any*/),
          (v19/*: any*/),
          (v20/*: any*/),
          (v21/*: any*/),
          (v22/*: any*/),
          (v23/*: any*/),
          (v24/*: any*/),
          (v25/*: any*/),
          (v26/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "activity",
            "plural": false,
            "selections": [
              (v27/*: any*/),
              (v28/*: any*/)
            ],
            "storageKey": null
          },
          (v29/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Club",
            "kind": "LinkedField",
            "name": "club",
            "plural": false,
            "selections": [
              (v5/*: any*/),
              (v27/*: any*/),
              (v28/*: any*/),
              (v30/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "Membership",
                "kind": "LinkedField",
                "name": "viewerMembership",
                "plural": false,
                "selections": [
                  (v31/*: any*/)
                ],
                "storageKey": null
              }
            ],
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
              (v5/*: any*/),
              (v27/*: any*/),
              (v22/*: any*/),
              (v32/*: any*/),
              (v33/*: any*/),
              (v34/*: any*/),
              {
                "args": null,
                "kind": "FragmentSpread",
                "name": "LocationMap_location"
              }
            ],
            "storageKey": null
          },
          (v36/*: any*/),
          {
            "alias": "rsvps",
            "args": null,
            "concreteType": "EventRsvpConnection",
            "kind": "LinkedField",
            "name": "__PkRSVPSection_event_rsvps_connection",
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
                      (v5/*: any*/),
                      (v37/*: any*/),
                      (v38/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "User",
                        "kind": "LinkedField",
                        "name": "user",
                        "plural": false,
                        "selections": (v9/*: any*/),
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "Payment",
                        "kind": "LinkedField",
                        "name": "payment",
                        "plural": false,
                        "selections": [
                          (v5/*: any*/),
                          (v31/*: any*/),
                          (v39/*: any*/)
                        ],
                        "storageKey": null
                      },
                      (v40/*: any*/)
                    ],
                    "storageKey": null
                  },
                  (v41/*: any*/)
                ],
                "storageKey": null
              },
              (v42/*: any*/)
            ],
            "storageKey": null
          },
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "PkRSVPSection_event"
          },
          {
            "args": null,
            "kind": "FragmentSpread",
            "name": "EventLocationAvailability_event"
          },
          (v43/*: any*/)
        ],
        "storageKey": null
      },
      {
        "args": (v44/*: any*/),
        "kind": "FragmentSpread",
        "name": "PkEventMessages_query"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [
      (v2/*: any*/),
      (v4/*: any*/),
      (v0/*: any*/),
      (v3/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Operation",
    "name": "PkEventPageQuery",
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Viewer",
        "kind": "LinkedField",
        "name": "viewer",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "profile",
            "plural": false,
            "selections": [
              (v5/*: any*/),
              (v6/*: any*/),
              (v7/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "fullName",
                "storageKey": null
              },
              (v45/*: any*/),
              (v46/*: any*/),
              (v47/*: any*/),
              (v48/*: any*/),
              {
                "alias": null,
                "args": [
                  {
                    "kind": "Literal",
                    "name": "activitySlug",
                    "value": "pickleball"
                  }
                ],
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "rating",
                "plural": false,
                "selections": (v9/*: any*/),
                "storageKey": "rating(activitySlug:\"pickleball\")"
              }
            ],
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
              (v5/*: any*/),
              (v6/*: any*/),
              (v7/*: any*/),
              {
                "alias": null,
                "args": (v8/*: any*/),
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "eventRating",
                "plural": false,
                "selections": [
                  (v5/*: any*/),
                  (v49/*: any*/),
                  (v50/*: any*/),
                  (v51/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v10/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v11/*: any*/),
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          (v5/*: any*/),
          (v12/*: any*/),
          (v13/*: any*/),
          (v14/*: any*/),
          (v15/*: any*/),
          (v16/*: any*/),
          (v17/*: any*/),
          (v18/*: any*/),
          (v19/*: any*/),
          (v20/*: any*/),
          (v21/*: any*/),
          (v22/*: any*/),
          (v23/*: any*/),
          (v24/*: any*/),
          (v25/*: any*/),
          (v26/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Activity",
            "kind": "LinkedField",
            "name": "activity",
            "plural": false,
            "selections": [
              (v27/*: any*/),
              (v28/*: any*/),
              (v5/*: any*/)
            ],
            "storageKey": null
          },
          (v29/*: any*/),
          {
            "alias": null,
            "args": null,
            "concreteType": "Club",
            "kind": "LinkedField",
            "name": "club",
            "plural": false,
            "selections": [
              (v5/*: any*/),
              (v27/*: any*/),
              (v28/*: any*/),
              (v30/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "Membership",
                "kind": "LinkedField",
                "name": "viewerMembership",
                "plural": false,
                "selections": [
                  (v31/*: any*/),
                  (v5/*: any*/)
                ],
                "storageKey": null
              }
            ],
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
              (v5/*: any*/),
              (v27/*: any*/),
              (v22/*: any*/),
              (v32/*: any*/),
              (v33/*: any*/),
              (v34/*: any*/)
            ],
            "storageKey": null
          },
          (v36/*: any*/),
          {
            "alias": null,
            "args": (v52/*: any*/),
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
                      (v5/*: any*/),
                      (v37/*: any*/),
                      (v38/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "User",
                        "kind": "LinkedField",
                        "name": "user",
                        "plural": false,
                        "selections": [
                          (v5/*: any*/),
                          (v35/*: any*/),
                          (v6/*: any*/),
                          (v46/*: any*/),
                          (v47/*: any*/),
                          (v48/*: any*/),
                          (v45/*: any*/)
                        ],
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "concreteType": "Payment",
                        "kind": "LinkedField",
                        "name": "payment",
                        "plural": false,
                        "selections": [
                          (v5/*: any*/),
                          (v31/*: any*/),
                          (v39/*: any*/),
                          {
                            "alias": null,
                            "args": null,
                            "kind": "ScalarField",
                            "name": "chargeable",
                            "storageKey": null
                          }
                        ],
                        "storageKey": null
                      },
                      (v40/*: any*/),
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
                        "concreteType": "Rating",
                        "kind": "LinkedField",
                        "name": "rating",
                        "plural": false,
                        "selections": [
                          (v49/*: any*/),
                          (v50/*: any*/),
                          (v51/*: any*/),
                          (v5/*: any*/)
                        ],
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "paid",
                        "storageKey": null
                      }
                    ],
                    "storageKey": null
                  },
                  (v41/*: any*/)
                ],
                "storageKey": null
              },
              (v42/*: any*/)
            ],
            "storageKey": "rsvps(first:100)"
          },
          {
            "alias": null,
            "args": (v52/*: any*/),
            "filters": null,
            "handle": "connection",
            "key": "PkRSVPSection_event_rsvps",
            "kind": "LinkedHandle",
            "name": "rsvps"
          },
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "smartRsvpThreshold",
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "LocationAvailabilityDay",
            "kind": "LinkedField",
            "name": "courtAvailability",
            "plural": true,
            "selections": [
              (v5/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "link",
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
                  (v5/*: any*/),
                  (v27/*: any*/)
                ],
                "storageKey": null
              },
              (v53/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "AvailabilityHourStat",
                "kind": "LinkedField",
                "name": "hourly",
                "plural": true,
                "selections": [
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "hour",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "indoorCount",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "outdoorCount",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "priceMin",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "priceMax",
                    "storageKey": null
                  }
                ],
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "concreteType": "CourtAvailability",
                "kind": "LinkedField",
                "name": "courts",
                "plural": true,
                "selections": [
                  (v27/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "courtType",
                    "storageKey": null
                  },
                  (v26/*: any*/),
                  (v53/*: any*/)
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v43/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v44/*: any*/),
        "concreteType": "EventMessageConnection",
        "kind": "LinkedField",
        "name": "messagesByTopic",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "EventMessageEdge",
            "kind": "LinkedField",
            "name": "edges",
            "plural": true,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "Message",
                "kind": "LinkedField",
                "name": "node",
                "plural": false,
                "selections": [
                  (v5/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "createdAt",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "payload",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "topic",
                    "storageKey": null
                  },
                  (v40/*: any*/)
                ],
                "storageKey": null
              },
              (v41/*: any*/)
            ],
            "storageKey": null
          },
          (v42/*: any*/)
        ],
        "storageKey": null
      },
      {
        "alias": null,
        "args": (v44/*: any*/),
        "filters": [
          "topic"
        ],
        "handle": "connection",
        "key": "PkEventMessages_messagesByTopic",
        "kind": "LinkedHandle",
        "name": "messagesByTopic"
      },
      (v43/*: any*/)
    ]
  },
  "params": {
    "cacheID": "ff18926b3eba3dc4d31c3e3577d50199",
    "id": null,
    "metadata": {
      "connection": [
        {
          "count": null,
          "cursor": null,
          "direction": "forward",
          "path": [
            "event",
            "rsvps"
          ]
        }
      ]
    },
    "name": "PkEventPageQuery",
    "operationKind": "query",
    "text": "query PkEventPageQuery(\n  $eventId: ID!\n  $topic: String!\n  $after: String\n  $first: Int\n  $before: String\n) {\n  ...UseProfileGate_query\n  viewer {\n    user {\n      id\n      lineUsername\n      email\n      eventRating(eventId: $eventId) {\n        id\n      }\n      ...PkRSVPSection_user_32qNee\n    }\n    savedCard {\n      brand\n      last4\n    }\n  }\n  event(id: $eventId) {\n    id\n    title\n    startDate\n    endDate\n    timezone\n    tags\n    listed\n    viewerIsAdmin\n    viewerIsBanned\n    deleted\n    shadow\n    details\n    maxRsvps\n    minRating\n    cancelDeadline\n    price\n    activity {\n      name\n      slug\n      id\n    }\n    chargesEnabled\n    club {\n      id\n      name\n      slug\n      exemptMembersFromPayment\n      viewerMembership {\n        status\n        id\n      }\n    }\n    location {\n      id\n      name\n      details\n      address\n      links\n      coords {\n        lat\n        lng\n      }\n      ...LocationMap_location\n    }\n    owner {\n      id\n      lineUsername\n      picture\n    }\n    rsvps(first: 100) {\n      edges {\n        node {\n          id\n          listType\n          joinTime\n          user {\n            id\n          }\n          payment {\n            id\n            status\n            currency\n          }\n          __typename\n        }\n        cursor\n      }\n      pageInfo {\n        endCursor\n        hasNextPage\n      }\n    }\n    ...PkRSVPSection_event\n    ...EventLocationAvailability_event\n  }\n  ...PkEventMessages_query_VpiI6\n}\n\nfragment EventLocationAvailability_event on Event {\n  id\n  title\n  details\n  startDate\n  endDate\n  timezone\n  listed\n  tags\n  maxRsvps\n  minRating\n  cancelDeadline\n  price\n  smartRsvpThreshold\n  activity {\n    id\n  }\n  club {\n    id\n  }\n  location {\n    id\n  }\n  courtAvailability {\n    id\n    link\n    location {\n      id\n      name\n    }\n    intervals {\n      startHour\n      endHour\n    }\n    hourly {\n      hour\n      indoorCount\n      outdoorCount\n      priceMin\n      priceMax\n    }\n    courts {\n      name\n      courtType\n      price\n      intervals {\n        startHour\n        endHour\n      }\n    }\n  }\n}\n\nfragment LocationMap_location on Location {\n  id\n  coords {\n    lng\n    lat\n  }\n  address\n}\n\nfragment MiniEventRsvp_rsvp on Rsvp {\n  user {\n    id\n    picture\n    lineUsername\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n}\n\nfragment PaymentIndicator_payment on Payment {\n  status\n  currency\n}\n\nfragment PkEventMessages_query_VpiI6 on Query {\n  messagesByTopic(topic: $topic, after: $after, first: $first, before: $before) {\n    edges {\n      node {\n        id\n        createdAt\n        payload\n        topic\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment PkEventRsvp_rsvp on Rsvp {\n  id\n  user {\n    id\n    picture\n    lineUsername\n    gender\n    selfRating\n    dupr {\n      doubles\n      doublesReliable\n    }\n  }\n  rating {\n    ordinal\n    mu\n    sigma\n    id\n  }\n  message\n  paid\n  payment {\n    id\n    ...PaymentIndicator_payment\n  }\n  ...RsvpOptions_rsvp\n}\n\nfragment PkRSVPSection_event on Event {\n  id\n  title\n  startDate\n  endDate\n  timezone\n  maxRsvps\n  price\n  chargesEnabled\n  minRating\n  smartRsvpThreshold\n  viewerIsAdmin\n  tags\n  club {\n    id\n  }\n  activity {\n    id\n    slug\n  }\n  location {\n    id\n    name\n  }\n  owner {\n    lineUsername\n    id\n  }\n  rsvps(first: 100) {\n    edges {\n      node {\n        id\n        listType\n        message\n        ...PkEventRsvp_rsvp\n        ...MiniEventRsvp_rsvp\n        user {\n          id\n          lineUsername\n          gender\n          picture\n          biography\n          selfRating\n          dupr {\n            doubles\n            doublesReliable\n          }\n        }\n        rating {\n          ordinal\n          mu\n          sigma\n          id\n        }\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      endCursor\n      hasNextPage\n    }\n  }\n}\n\nfragment PkRSVPSection_user_32qNee on User {\n  id\n  eventRating(eventId: $eventId) {\n    id\n    ordinal\n    mu\n    sigma\n  }\n}\n\nfragment ProfileModal_viewer on Query {\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      fullName\n      biography\n      gender\n      selfRating\n      dupr {\n        doubles\n        doublesReliable\n      }\n    }\n  }\n}\n\nfragment RsvpOptions_rsvp on Rsvp {\n  id\n  listType\n  user {\n    id\n  }\n  payment {\n    id\n    status\n    chargeable\n  }\n}\n\nfragment UseProfileGate_query on Query {\n  ...ProfileModal_viewer\n  viewer {\n    profile {\n      id\n      lineUsername\n      email\n      biography\n      selfRating\n      dupr {\n        doubles\n      }\n      rating(activitySlug: \"pickleball\") {\n        id\n      }\n    }\n  }\n}\n"
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

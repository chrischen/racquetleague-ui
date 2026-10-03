/* @sourceLoc EventInvites.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_inviteRecommendations_recommendations_rating = {
    dupr: float,
    established: bool,
  }
  and response_inviteRecommendations_recommendations_user = {
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PlayerInviteSwipeDeck_user]>,
  }
  and response_inviteRecommendations_recommendations = {
    availability: RelaySchemaAssets_graphql.enum_InviteAvailability,
    fit: RelaySchemaAssets_graphql.enum_InviteFit,
    rating: response_inviteRecommendations_recommendations_rating,
    strong: bool,
    user: response_inviteRecommendations_recommendations_user,
  }
  and response_inviteRecommendations = {
    recommendations: option<array<response_inviteRecommendations_recommendations>>,
  }
  type response = {
    inviteRecommendations: response_inviteRecommendations,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    eventId: string,
    first?: int,
  }
  @live
  type refetchVariables = {
    eventId: option<string>,
    first: option<option<int>>,
  }
  @live let makeRefetchVariables = (
    ~eventId=?,
    ~first=?,
  ): refetchVariables => {
    eventId: eventId,
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
    json`{"__root":{"inviteRecommendations_recommendations_user":{"f":""}}}`
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
    json`{"__root":{"inviteRecommendations_recommendations_user":{"f":""}}}`
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
  @live
  external inviteAvailability_toString: RelaySchemaAssets_graphql.enum_InviteAvailability => string = "%identity"
  @live
  external inviteAvailability_input_toString: RelaySchemaAssets_graphql.enum_InviteAvailability_input => string = "%identity"
  @live
  let inviteAvailability_decode = (enum: RelaySchemaAssets_graphql.enum_InviteAvailability): option<RelaySchemaAssets_graphql.enum_InviteAvailability_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let inviteAvailability_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_InviteAvailability_input> => {
    inviteAvailability_decode(Obj.magic(str))
  }
  @live
  external inviteFit_toString: RelaySchemaAssets_graphql.enum_InviteFit => string = "%identity"
  @live
  external inviteFit_input_toString: RelaySchemaAssets_graphql.enum_InviteFit_input => string = "%identity"
  @live
  let inviteFit_decode = (enum: RelaySchemaAssets_graphql.enum_InviteFit): option<RelaySchemaAssets_graphql.enum_InviteFit_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let inviteFit_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_InviteFit_input> => {
    inviteFit_decode(Obj.magic(str))
  }
}

type relayOperationNode
type operationType = RescriptRelay.queryNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "eventId"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "first"
  }
],
v1 = {
  "kind": "Variable",
  "name": "eventId",
  "variableName": "eventId"
},
v2 = [
  (v1/*: any*/),
  {
    "kind": "Variable",
    "name": "first",
    "variableName": "first"
  }
],
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "availability",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "fit",
  "storageKey": null
},
v5 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "strong",
  "storageKey": null
},
v6 = {
  "alias": null,
  "args": null,
  "concreteType": "ResolvedRating",
  "kind": "LinkedField",
  "name": "rating",
  "plural": false,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "dupr",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "established",
      "storageKey": null
    }
  ],
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v9 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "picture",
  "storageKey": null
},
v10 = [
  (v1/*: any*/)
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "EventInvitesRecommendationsQuery",
    "selections": [
      {
        "alias": null,
        "args": (v2/*: any*/),
        "concreteType": "InviteRecommendations",
        "kind": "LinkedField",
        "name": "inviteRecommendations",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "InviteRecommendation",
            "kind": "LinkedField",
            "name": "recommendations",
            "plural": true,
            "selections": [
              (v3/*: any*/),
              (v4/*: any*/),
              (v5/*: any*/),
              (v6/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "User",
                "kind": "LinkedField",
                "name": "user",
                "plural": false,
                "selections": [
                  (v7/*: any*/),
                  (v8/*: any*/),
                  (v9/*: any*/),
                  {
                    "args": (v10/*: any*/),
                    "kind": "FragmentSpread",
                    "name": "PlayerInviteSwipeDeck_user"
                  }
                ],
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
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "EventInvitesRecommendationsQuery",
    "selections": [
      {
        "alias": null,
        "args": (v2/*: any*/),
        "concreteType": "InviteRecommendations",
        "kind": "LinkedField",
        "name": "inviteRecommendations",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "InviteRecommendation",
            "kind": "LinkedField",
            "name": "recommendations",
            "plural": true,
            "selections": [
              (v3/*: any*/),
              (v4/*: any*/),
              (v5/*: any*/),
              (v6/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "User",
                "kind": "LinkedField",
                "name": "user",
                "plural": false,
                "selections": [
                  (v7/*: any*/),
                  (v8/*: any*/),
                  (v9/*: any*/),
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "gender",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "biography",
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "selfRating",
                    "storageKey": null
                  },
                  {
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
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "doublesReliability",
                        "storageKey": null
                      }
                    ],
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": (v10/*: any*/),
                    "concreteType": "Rating",
                    "kind": "LinkedField",
                    "name": "eventRating",
                    "plural": false,
                    "selections": [
                      (v7/*: any*/),
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
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "9af61420a6011a44d0cceffebf2541d5",
    "id": null,
    "metadata": {},
    "name": "EventInvitesRecommendationsQuery",
    "operationKind": "query",
    "text": "query EventInvitesRecommendationsQuery(\n  $eventId: ID!\n  $first: Int\n) {\n  inviteRecommendations(eventId: $eventId, first: $first) {\n    recommendations {\n      availability\n      fit\n      strong\n      rating {\n        dupr\n        established\n      }\n      user {\n        id\n        lineUsername\n        picture\n        ...PlayerInviteSwipeDeck_user_32qNee\n      }\n    }\n  }\n}\n\nfragment PlayerInviteSwipeDeck_user_32qNee on User {\n  id\n  lineUsername\n  picture\n  gender\n  biography\n  selfRating\n  dupr {\n    doubles\n    doublesReliable\n    doublesReliability\n  }\n  eventRating(eventId: $eventId) {\n    id\n    mu\n    sigma\n  }\n}\n"
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

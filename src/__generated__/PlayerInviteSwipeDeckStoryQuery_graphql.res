/* @sourceLoc PlayerInviteSwipeDeckStory.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_inviteRecommendations_recommendations_user = {
    @live id: string,
    lineUsername: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PlayerInviteSwipeDeck_user]>,
  }
  and response_inviteRecommendations_recommendations = {
    availability: RelaySchemaAssets_graphql.enum_InviteAvailability,
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
  type variables = unit
  @live
  type refetchVariables = unit
  @live let makeRefetchVariables = () => ()
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
}

type relayOperationNode
type operationType = RescriptRelay.queryNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = {
  "kind": "Literal",
  "name": "eventId",
  "value": "evt-story-1"
},
v1 = [
  (v0/*: any*/),
  {
    "kind": "Literal",
    "name": "first",
    "value": 12
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "availability",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v5 = [
  (v0/*: any*/)
];
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "PlayerInviteSwipeDeckStoryQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
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
              (v2/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "User",
                "kind": "LinkedField",
                "name": "user",
                "plural": false,
                "selections": [
                  (v3/*: any*/),
                  (v4/*: any*/),
                  {
                    "args": (v5/*: any*/),
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
        "storageKey": "inviteRecommendations(eventId:\"evt-story-1\",first:12)"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "PlayerInviteSwipeDeckStoryQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
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
              (v2/*: any*/),
              {
                "alias": null,
                "args": null,
                "concreteType": "User",
                "kind": "LinkedField",
                "name": "user",
                "plural": false,
                "selections": [
                  (v3/*: any*/),
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
                    "args": (v5/*: any*/),
                    "concreteType": "Rating",
                    "kind": "LinkedField",
                    "name": "eventRating",
                    "plural": false,
                    "selections": [
                      (v3/*: any*/),
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
                    "storageKey": "eventRating(eventId:\"evt-story-1\")"
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          }
        ],
        "storageKey": "inviteRecommendations(eventId:\"evt-story-1\",first:12)"
      }
    ]
  },
  "params": {
    "cacheID": "2b369d524e1f8609fa823ccb7063d01a",
    "id": null,
    "metadata": {},
    "name": "PlayerInviteSwipeDeckStoryQuery",
    "operationKind": "query",
    "text": "query PlayerInviteSwipeDeckStoryQuery {\n  inviteRecommendations(eventId: \"evt-story-1\", first: 12) {\n    recommendations {\n      availability\n      user {\n        id\n        lineUsername\n        ...PlayerInviteSwipeDeck_user_21MSXc\n      }\n    }\n  }\n}\n\nfragment PlayerInviteSwipeDeck_user_21MSXc on User {\n  id\n  lineUsername\n  picture\n  gender\n  biography\n  selfRating\n  dupr {\n    doubles\n    doublesReliable\n    doublesReliability\n  }\n  eventRating(eventId: \"evt-story-1\") {\n    id\n    mu\n    sigma\n  }\n}\n"
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

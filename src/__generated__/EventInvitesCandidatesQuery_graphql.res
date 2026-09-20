/* @sourceLoc EventInvites.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec response_availabilityUsersForDay_intervals = {
    endHour: int,
    startHour: int,
  }
  and response_availabilityUsersForDay_user = {
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PlayerInviteSwipeDeck_user]>,
  }
  and response_availabilityUsersForDay = {
    @live id: string,
    intervals: array<response_availabilityUsersForDay_intervals>,
    localDate: string,
    user: option<response_availabilityUsersForDay_user>,
  }
  type response = {
    availabilityUsersForDay: array<response_availabilityUsersForDay>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    activityId: string,
    activitySlug: string,
    clubId?: string,
    localDate: string,
  }
  @live
  type refetchVariables = {
    activityId: option<string>,
    activitySlug: option<string>,
    clubId: option<option<string>>,
    localDate: option<string>,
  }
  @live let makeRefetchVariables = (
    ~activityId=?,
    ~activitySlug=?,
    ~clubId=?,
    ~localDate=?,
  ): refetchVariables => {
    activityId: activityId,
    activitySlug: activitySlug,
    clubId: clubId,
    localDate: localDate
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
    json`{"__root":{"availabilityUsersForDay_user":{"f":""}}}`
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
    json`{"__root":{"availabilityUsersForDay_user":{"f":""}}}`
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
  "name": "activityId"
},
v1 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "activitySlug"
},
v2 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "clubId"
},
v3 = {
  "defaultValue": null,
  "kind": "LocalArgument",
  "name": "localDate"
},
v4 = [
  {
    "kind": "Variable",
    "name": "localDate",
    "variableName": "localDate"
  },
  {
    "fields": [
      {
        "kind": "Variable",
        "name": "activityId",
        "variableName": "activityId"
      },
      {
        "kind": "Variable",
        "name": "clubId",
        "variableName": "clubId"
      }
    ],
    "kind": "ObjectValue",
    "name": "scope"
  }
],
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
  "name": "localDate",
  "storageKey": null
},
v7 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "lineUsername",
  "storageKey": null
},
v8 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "picture",
  "storageKey": null
},
v9 = [
  {
    "kind": "Variable",
    "name": "activitySlug",
    "variableName": "activitySlug"
  }
],
v10 = {
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
      (v3/*: any*/)
    ],
    "kind": "Fragment",
    "metadata": null,
    "name": "EventInvitesCandidatesQuery",
    "selections": [
      {
        "alias": null,
        "args": (v4/*: any*/),
        "concreteType": "AvailabilityDay",
        "kind": "LinkedField",
        "name": "availabilityUsersForDay",
        "plural": true,
        "selections": [
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
              (v5/*: any*/),
              (v7/*: any*/),
              (v8/*: any*/),
              {
                "args": (v9/*: any*/),
                "kind": "FragmentSpread",
                "name": "PlayerInviteSwipeDeck_user"
              }
            ],
            "storageKey": null
          },
          (v10/*: any*/)
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
      (v3/*: any*/),
      (v0/*: any*/),
      (v2/*: any*/),
      (v1/*: any*/)
    ],
    "kind": "Operation",
    "name": "EventInvitesCandidatesQuery",
    "selections": [
      {
        "alias": null,
        "args": (v4/*: any*/),
        "concreteType": "AvailabilityDay",
        "kind": "LinkedField",
        "name": "availabilityUsersForDay",
        "plural": true,
        "selections": [
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
              (v5/*: any*/),
              (v7/*: any*/),
              (v8/*: any*/),
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
                  }
                ],
                "storageKey": null
              },
              {
                "alias": null,
                "args": (v9/*: any*/),
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
                  }
                ],
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v10/*: any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "3667ecab54704154d4e01c4017543b3f",
    "id": null,
    "metadata": {},
    "name": "EventInvitesCandidatesQuery",
    "operationKind": "query",
    "text": "query EventInvitesCandidatesQuery(\n  $localDate: String!\n  $activityId: ID!\n  $clubId: ID\n  $activitySlug: String!\n) {\n  availabilityUsersForDay(localDate: $localDate, scope: {activityId: $activityId, clubId: $clubId}) {\n    id\n    localDate\n    user {\n      id\n      lineUsername\n      picture\n      ...PlayerInviteSwipeDeck_user_36AXNO\n    }\n    intervals {\n      startHour\n      endHour\n    }\n  }\n}\n\nfragment PlayerInviteSwipeDeck_user_36AXNO on User {\n  id\n  lineUsername\n  picture\n  gender\n  biography\n  selfRating\n  dupr {\n    doubles\n    doublesReliable\n  }\n  rating(activitySlug: $activitySlug) {\n    id\n    mu\n  }\n}\n"
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

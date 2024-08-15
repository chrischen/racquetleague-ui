/* @sourceLoc AiTetsu.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live
  type rec response_createLeagueRating_rating = {
    @live id: string,
  }
  @live
  and response_createLeagueRating = {
    rating: option<response_createLeagueRating_rating>,
  }
  @live
  type response = {
    createLeagueRating: option<response_createLeagueRating>,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    userId?: string,
  }
}

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
}
module Utils = {
  @@warning("-33")
  open Types
}

type relayOperationNode
type operationType = RescriptRelay.mutationNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "userId"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "fields": [
          {
            "kind": "Literal",
            "name": "activitySlug",
            "value": "pickleball"
          },
          {
            "kind": "Literal",
            "name": "namespace",
            "value": "doubles:rec"
          },
          {
            "kind": "Variable",
            "name": "userId",
            "variableName": "userId"
          }
        ],
        "kind": "ObjectValue",
        "name": "input"
      }
    ],
    "concreteType": "CreateRatingResponse",
    "kind": "LinkedField",
    "name": "createLeagueRating",
    "plural": false,
    "selections": [
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
            "name": "id",
            "storageKey": null
          }
        ],
        "storageKey": null
      }
    ],
    "storageKey": null
  }
];
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "AiTetsuCreateRatingMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "AiTetsuCreateRatingMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "da9520d1f3931583b0e261fd074cb343",
    "id": null,
    "metadata": {},
    "name": "AiTetsuCreateRatingMutation",
    "operationKind": "mutation",
    "text": "mutation AiTetsuCreateRatingMutation(\n  $userId: String\n) {\n  createLeagueRating(input: {activitySlug: \"pickleball\", namespace: \"doubles:rec\", userId: $userId}) {\n    rating {\n      id\n    }\n  }\n}\n"
  }
};
})() `)



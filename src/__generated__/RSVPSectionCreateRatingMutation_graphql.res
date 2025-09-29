/* @sourceLoc RSVPSection.res */
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
  type variables = unit
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
    "alias": null,
    "args": [
      {
        "kind": "Literal",
        "name": "input",
        "value": {
          "activitySlug": "pickleball",
          "namespace": "doubles:rec"
        }
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
    "storageKey": "createLeagueRating(input:{\"activitySlug\":\"pickleball\",\"namespace\":\"doubles:rec\"})"
  }
];
return {
  "fragment": {
    "argumentDefinitions": [],
    "kind": "Fragment",
    "metadata": null,
    "name": "RSVPSectionCreateRatingMutation",
    "selections": (v0/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": [],
    "kind": "Operation",
    "name": "RSVPSectionCreateRatingMutation",
    "selections": (v0/*: any*/)
  },
  "params": {
    "cacheID": "1b9bd7dc50bf37302044b2dc37c8250b",
    "id": null,
    "metadata": {},
    "name": "RSVPSectionCreateRatingMutation",
    "operationKind": "mutation",
    "text": "mutation RSVPSectionCreateRatingMutation {\n  createLeagueRating(input: {activitySlug: \"pickleball\", namespace: \"doubles:rec\"}) {\n    rating {\n      id\n    }\n  }\n}\n"
  }
};
})() `)



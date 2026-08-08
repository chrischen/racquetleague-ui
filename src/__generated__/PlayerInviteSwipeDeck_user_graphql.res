/* @sourceLoc PlayerInviteSwipeDeck.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_rating = {
    @live id: string,
    mu: option<float>,
  }
  type fragment = {
    biography: option<string>,
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
    rating: option<fragment_rating>,
    selfRating: option<float>,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{}`
  )
  @live
  let fragmentConverterMap = ()
  @live
  let convertFragment = v => v->RescriptRelay.convertObj(
    fragmentConverter,
    fragmentConverterMap,
    Js.undefined
  )
}

type t
type fragmentRef
external getFragmentRef:
  RescriptRelay.fragmentRefs<[> | #PlayerInviteSwipeDeck_user]> => fragmentRef = "%identity"

module Utils = {
  @@warning("-33")
  open Types
  @live
  external gender_toString: RelaySchemaAssets_graphql.enum_Gender => string = "%identity"
  @live
  external gender_input_toString: RelaySchemaAssets_graphql.enum_Gender_input => string = "%identity"
  @live
  let gender_decode = (enum: RelaySchemaAssets_graphql.enum_Gender): option<RelaySchemaAssets_graphql.enum_Gender_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let gender_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_Gender_input> => {
    gender_decode(Obj.magic(str))
  }
}

type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


let node: operationType = %raw(json` (function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "argumentDefinitions": [
    {
      "defaultValue": "pickleball",
      "kind": "LocalArgument",
      "name": "activitySlug"
    }
  ],
  "kind": "Fragment",
  "metadata": null,
  "name": "PlayerInviteSwipeDeck_user",
  "selections": [
    (v0/*: any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "lineUsername",
      "storageKey": null
    },
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
      "args": [
        {
          "kind": "Variable",
          "name": "activitySlug",
          "variableName": "activitySlug"
        }
      ],
      "concreteType": "Rating",
      "kind": "LinkedField",
      "name": "rating",
      "plural": false,
      "selections": [
        (v0/*: any*/),
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
  "type": "User",
  "abstractKey": null
};
})() `)


/* @sourceLoc RatingList.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_user = {
    gender: option<RelaySchemaAssets_graphql.enum_Gender>,
    @live id: string,
    lineUsername: option<string>,
    picture: option<string>,
  }
  type fragment = {
    @live id: string,
    ordinal: option<float>,
    user: option<fragment_user>,
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
  RescriptRelay.fragmentRefs<[> | #RatingList_rating]> => fragmentRef = "%identity"

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
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "RatingList_rating",
  "selections": [
    (v0/*: any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "ordinal",
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
        }
      ],
      "storageKey": null
    }
  ],
  "type": "Rating",
  "abstractKey": null
};
})() `)


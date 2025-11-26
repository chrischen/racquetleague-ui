/* @sourceLoc PlayerCheckin.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type fragment = {
    lineUsername: option<string>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #PlayerAvatar_user]>,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"":{"f":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #PlayerCheckin_user]> => fragmentRef = "%identity"

module Utils = {
  @@warning("-33")
  open Types
}

type relayOperationNode
type operationType = RescriptRelay.fragmentNode<relayOperationNode>


let node: operationType = %raw(json` {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "PlayerCheckin_user",
  "selections": [
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "PlayerAvatar_user"
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "lineUsername",
      "storageKey": null
    }
  ],
  "type": "User",
  "abstractKey": null
} `)


/* @sourceLoc UseProfileGate.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_viewer_profile_dupr = {
    doubles: option<float>,
    doublesReliability: option<float>,
    doublesReliable: bool,
  }
  and fragment_viewer_profile_rating = {
    @live id: string,
  }
  and fragment_viewer_profile = {
    biography: option<string>,
    dupr: option<fragment_viewer_profile_dupr>,
    email: option<string>,
    @live id: string,
    lineUsername: option<string>,
    rating: option<fragment_viewer_profile_rating>,
    selfRating: option<float>,
  }
  and fragment_viewer = {
    profile: option<fragment_viewer_profile>,
  }
  type fragment = {
    viewer: option<fragment_viewer>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #ProfileModal_viewer]>,
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
  RescriptRelay.fragmentRefs<[> | #UseProfileGate_query]> => fragmentRef = "%identity"

module Utils = {
  @@warning("-33")
  open Types
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
  "name": "UseProfileGate_query",
  "selections": [
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "ProfileModal_viewer"
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
          "name": "profile",
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
              "name": "email",
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
                (v0/*: any*/)
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
};
})() `)


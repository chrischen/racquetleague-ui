/* @sourceLoc EventRsvp.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_rating = {
    mu: option<float>,
    ordinal: option<float>,
    sigma: option<float>,
  }
  and fragment_user_dupr = {
    doubles: option<float>,
    doublesReliability: option<float>,
    doublesReliable: bool,
  }
  and fragment_user = {
    dupr: option<fragment_user_dupr>,
    @live id: string,
    selfRating: option<float>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #EventRsvpUser_user]>,
  }
  type fragment = {
    message: option<string>,
    paid: option<int>,
    rating: option<fragment_rating>,
    user: option<fragment_user>,
    fragmentRefs: RescriptRelay.fragmentRefs<[ | #RsvpOptions_rsvp]>,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"user":{"f":""},"":{"f":""}}}`
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
  RescriptRelay.fragmentRefs<[> | #EventRsvp_rsvp]> => fragmentRef = "%identity"

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
  "name": "EventRsvp_rsvp",
  "selections": [
    {
      "alias": null,
      "args": null,
      "concreteType": "User",
      "kind": "LinkedField",
      "name": "user",
      "plural": false,
      "selections": [
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "id",
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
          "args": null,
          "kind": "FragmentSpread",
          "name": "EventRsvpUser_user"
        }
      ],
      "storageKey": null
    },
    {
      "args": null,
      "kind": "FragmentSpread",
      "name": "RsvpOptions_rsvp"
    },
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
          "name": "ordinal",
          "storageKey": null
        },
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
    },
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
      "kind": "ScalarField",
      "name": "paid",
      "storageKey": null
    }
  ],
  "type": "Rsvp",
  "abstractKey": null
} `)


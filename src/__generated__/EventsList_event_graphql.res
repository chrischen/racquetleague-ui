/* @sourceLoc EventsList.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_activity = {
    name: option<string>,
  }
  and fragment_location = {
    @live id: string,
    name: option<string>,
  }
  and fragment_rsvps_edges_node = {
    @live id: string,
    listType: option<int>,
  }
  and fragment_rsvps_edges = {
    node: option<fragment_rsvps_edges_node>,
  }
  and fragment_rsvps = {
    edges: option<array<option<fragment_rsvps_edges>>>,
  }
  type fragment = {
    activity: option<fragment_activity>,
    deleted: option<Util.Datetime.t>,
    endDate: option<Util.Datetime.t>,
    @live id: string,
    location: option<fragment_location>,
    maxRsvps: option<int>,
    rsvps: option<fragment_rsvps>,
    shadow: option<bool>,
    startDate: option<Util.Datetime.t>,
    title: option<string>,
    viewerRsvpStatus: option<RelaySchemaAssets_graphql.enum_RsvpStatus>,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"startDate":{"c":"Util.Datetime"},"endDate":{"c":"Util.Datetime"},"deleted":{"c":"Util.Datetime"}}}`
  )
  @live
  let fragmentConverterMap = {
    "Util.Datetime": Util.Datetime.parse,
  }
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
  RescriptRelay.fragmentRefs<[> | #EventsList_event]> => fragmentRef = "%identity"

module Utils = {
  @@warning("-33")
  open Types
  @live
  external rsvpStatus_toString: RelaySchemaAssets_graphql.enum_RsvpStatus => string = "%identity"
  @live
  external rsvpStatus_input_toString: RelaySchemaAssets_graphql.enum_RsvpStatus_input => string = "%identity"
  @live
  let rsvpStatus_decode = (enum: RelaySchemaAssets_graphql.enum_RsvpStatus): option<RelaySchemaAssets_graphql.enum_RsvpStatus_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let rsvpStatus_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_RsvpStatus_input> => {
    rsvpStatus_decode(Obj.magic(str))
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
},
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
};
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "EventsList_event",
  "selections": [
    (v0/*: any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "title",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "Activity",
      "kind": "LinkedField",
      "name": "activity",
      "plural": false,
      "selections": [
        (v1/*: any*/)
      ],
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "Location",
      "kind": "LinkedField",
      "name": "location",
      "plural": false,
      "selections": [
        (v0/*: any*/),
        (v1/*: any*/)
      ],
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "viewerRsvpStatus",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "maxRsvps",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "EventRsvpConnection",
      "kind": "LinkedField",
      "name": "rsvps",
      "plural": false,
      "selections": [
        {
          "alias": null,
          "args": null,
          "concreteType": "EventRsvpEdge",
          "kind": "LinkedField",
          "name": "edges",
          "plural": true,
          "selections": [
            {
              "alias": null,
              "args": null,
              "concreteType": "Rsvp",
              "kind": "LinkedField",
              "name": "node",
              "plural": false,
              "selections": [
                (v0/*: any*/),
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "listType",
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
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "startDate",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "endDate",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "shadow",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "deleted",
      "storageKey": null
    }
  ],
  "type": "Event",
  "abstractKey": null
};
})() `)


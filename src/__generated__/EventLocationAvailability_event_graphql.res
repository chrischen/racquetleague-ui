/* @sourceLoc EventLocationAvailability.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  type rec fragment_activity = {
    @live id: string,
  }
  and fragment_club = {
    @live id: string,
  }
  and fragment_courtAvailability_courts_intervals = {
    endHour: int,
    startHour: int,
  }
  and fragment_courtAvailability_courts = {
    courtType: option<RelaySchemaAssets_graphql.enum_CourtType>,
    intervals: array<fragment_courtAvailability_courts_intervals>,
    name: option<string>,
    price: option<int>,
  }
  and fragment_courtAvailability_hourly = {
    hour: int,
    indoorCount: int,
    outdoorCount: int,
    priceMax: option<int>,
    priceMin: option<int>,
  }
  and fragment_courtAvailability_intervals = {
    endHour: int,
    startHour: int,
  }
  and fragment_courtAvailability_location = {
    @live id: string,
    name: option<string>,
  }
  and fragment_courtAvailability = {
    courts: option<array<fragment_courtAvailability_courts>>,
    hourly: array<fragment_courtAvailability_hourly>,
    @live id: string,
    intervals: array<fragment_courtAvailability_intervals>,
    link: option<string>,
    location: option<fragment_courtAvailability_location>,
  }
  and fragment_location = {
    @live id: string,
  }
  type fragment = {
    activity: option<fragment_activity>,
    cancelDeadline: option<int>,
    club: option<fragment_club>,
    courtAvailability: array<fragment_courtAvailability>,
    details: option<string>,
    endDate: option<Util.Datetime.t>,
    @live id: string,
    listed: option<bool>,
    location: option<fragment_location>,
    maxRsvps: option<int>,
    minRating: option<float>,
    price: option<int>,
    smartRsvpThreshold: option<float>,
    startDate: option<Util.Datetime.t>,
    tags: option<array<string>>,
    timezone: option<string>,
    title: option<string>,
  }
}

module Internal = {
  @live
  type fragmentRaw
  @live
  let fragmentConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"__root":{"startDate":{"c":"Util.Datetime"},"endDate":{"c":"Util.Datetime"}}}`
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
  RescriptRelay.fragmentRefs<[> | #EventLocationAvailability_event]> => fragmentRef = "%identity"

module Utils = {
  @@warning("-33")
  open Types
  @live
  external courtType_toString: RelaySchemaAssets_graphql.enum_CourtType => string = "%identity"
  @live
  external courtType_input_toString: RelaySchemaAssets_graphql.enum_CourtType_input => string = "%identity"
  @live
  let courtType_decode = (enum: RelaySchemaAssets_graphql.enum_CourtType): option<RelaySchemaAssets_graphql.enum_CourtType_input> => {
    switch enum {
      | FutureAddedValue(_) => None
      | valid => Some(Obj.magic(valid))
    }
  }
  @live
  let courtType_fromString = (str: string): option<RelaySchemaAssets_graphql.enum_CourtType_input> => {
    courtType_decode(Obj.magic(str))
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
  "name": "price",
  "storageKey": null
},
v2 = [
  (v0/*: any*/)
],
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "name",
  "storageKey": null
},
v4 = {
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
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "EventLocationAvailability_event",
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
      "kind": "ScalarField",
      "name": "details",
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
      "name": "timezone",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "listed",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "tags",
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
      "kind": "ScalarField",
      "name": "minRating",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "cancelDeadline",
      "storageKey": null
    },
    (v1/*: any*/),
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "smartRsvpThreshold",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "Activity",
      "kind": "LinkedField",
      "name": "activity",
      "plural": false,
      "selections": (v2/*: any*/),
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "Club",
      "kind": "LinkedField",
      "name": "club",
      "plural": false,
      "selections": (v2/*: any*/),
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "Location",
      "kind": "LinkedField",
      "name": "location",
      "plural": false,
      "selections": (v2/*: any*/),
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "LocationAvailabilityDay",
      "kind": "LinkedField",
      "name": "courtAvailability",
      "plural": true,
      "selections": [
        (v0/*: any*/),
        {
          "alias": null,
          "args": null,
          "kind": "ScalarField",
          "name": "link",
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
            (v3/*: any*/)
          ],
          "storageKey": null
        },
        (v4/*: any*/),
        {
          "alias": null,
          "args": null,
          "concreteType": "AvailabilityHourStat",
          "kind": "LinkedField",
          "name": "hourly",
          "plural": true,
          "selections": [
            {
              "alias": null,
              "args": null,
              "kind": "ScalarField",
              "name": "hour",
              "storageKey": null
            },
            {
              "alias": null,
              "args": null,
              "kind": "ScalarField",
              "name": "indoorCount",
              "storageKey": null
            },
            {
              "alias": null,
              "args": null,
              "kind": "ScalarField",
              "name": "outdoorCount",
              "storageKey": null
            },
            {
              "alias": null,
              "args": null,
              "kind": "ScalarField",
              "name": "priceMin",
              "storageKey": null
            },
            {
              "alias": null,
              "args": null,
              "kind": "ScalarField",
              "name": "priceMax",
              "storageKey": null
            }
          ],
          "storageKey": null
        },
        {
          "alias": null,
          "args": null,
          "concreteType": "CourtAvailability",
          "kind": "LinkedField",
          "name": "courts",
          "plural": true,
          "selections": [
            (v3/*: any*/),
            {
              "alias": null,
              "args": null,
              "kind": "ScalarField",
              "name": "courtType",
              "storageKey": null
            },
            (v1/*: any*/),
            (v4/*: any*/)
          ],
          "storageKey": null
        }
      ],
      "storageKey": null
    }
  ],
  "type": "Event",
  "abstractKey": null
};
})() `)


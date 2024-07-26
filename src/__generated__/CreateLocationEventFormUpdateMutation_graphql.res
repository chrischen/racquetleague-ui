/* @sourceLoc CreateLocationEventForm.res */
/* @generated */
%%raw("/* @generated */")
module Types = {
  @@warning("-30")

  @live type createEventInput = RelaySchemaAssets_graphql.input_CreateEventInput
  @live
  type rec response_updateEvent_event_activity = {
    @live id: string,
  }
  @live
  and response_updateEvent_event_club = {
    @live id: string,
    name: option<string>,
    slug: option<string>,
  }
  @live
  and response_updateEvent_event_location = {
    @live id: string,
  }
  @live
  and response_updateEvent_event = {
    @live __typename: [ | #Event],
    activity: option<response_updateEvent_event_activity>,
    club: option<response_updateEvent_event_club>,
    details: option<string>,
    endDate: option<Util.Datetime.t>,
    @live id: string,
    listed: option<bool>,
    location: option<response_updateEvent_event_location>,
    maxRsvps: option<int>,
    startDate: option<Util.Datetime.t>,
    title: option<string>,
  }
  @live
  and response_updateEvent = {
    event: option<response_updateEvent_event>,
  }
  @live
  type response = {
    updateEvent: response_updateEvent,
  }
  @live
  type rawResponse = response
  @live
  type variables = {
    eventId: string,
    input: createEventInput,
  }
}

module Internal = {
  @live
  let variablesConverter: Js.Dict.t<Js.Dict.t<Js.Dict.t<string>>> = %raw(
    json`{"createEventInput":{"startDate":{"c":"Util.Datetime"},"endDate":{"c":"Util.Datetime"}},"__root":{"input":{"r":"createEventInput"}}}`
  )
  @live
  let variablesConverterMap = {
    "Util.Datetime": Util.Datetime.serialize,
  }
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
    json`{"__root":{"updateEvent_event_startDate":{"c":"Util.Datetime"},"updateEvent_event_endDate":{"c":"Util.Datetime"}}}`
  )
  @live
  let wrapResponseConverterMap = {
    "Util.Datetime": Util.Datetime.serialize,
  }
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
    json`{"__root":{"updateEvent_event_startDate":{"c":"Util.Datetime"},"updateEvent_event_endDate":{"c":"Util.Datetime"}}}`
  )
  @live
  let responseConverterMap = {
    "Util.Datetime": Util.Datetime.parse,
  }
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
    "name": "eventId"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "input"
  }
],
v1 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v2 = [
  (v1/*: any*/)
],
v3 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "eventId",
        "variableName": "eventId"
      },
      {
        "kind": "Variable",
        "name": "input",
        "variableName": "input"
      }
    ],
    "concreteType": "MutationResult2",
    "kind": "LinkedField",
    "name": "updateEvent",
    "plural": false,
    "selections": [
      {
        "alias": null,
        "args": null,
        "concreteType": "Event",
        "kind": "LinkedField",
        "name": "event",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "kind": "ScalarField",
            "name": "__typename",
            "storageKey": null
          },
          (v1/*: any*/),
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
            "name": "maxRsvps",
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
            "concreteType": "Club",
            "kind": "LinkedField",
            "name": "club",
            "plural": false,
            "selections": [
              (v1/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "name",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "slug",
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
            "name": "listed",
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
    "name": "CreateLocationEventFormUpdateMutation",
    "selections": (v3/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "CreateLocationEventFormUpdateMutation",
    "selections": (v3/*: any*/)
  },
  "params": {
    "cacheID": "ff8c4419cc4c3d3a1405dd18f70136bd",
    "id": null,
    "metadata": {},
    "name": "CreateLocationEventFormUpdateMutation",
    "operationKind": "mutation",
    "text": "mutation CreateLocationEventFormUpdateMutation(\n  $eventId: ID!\n  $input: CreateEventInput!\n) {\n  updateEvent(eventId: $eventId, input: $input) {\n    event {\n      __typename\n      id\n      title\n      details\n      maxRsvps\n      activity {\n        id\n      }\n      location {\n        id\n      }\n      club {\n        id\n        name\n        slug\n      }\n      startDate\n      endDate\n      listed\n    }\n  }\n}\n"
  }
};
})() `)



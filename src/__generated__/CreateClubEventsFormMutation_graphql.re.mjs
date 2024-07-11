// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as Util from "../components/shared/Util.re.mjs";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";

var Types = {};

var variablesConverter = {"createEventsInput":{},"__root":{"input":{"r":"createEventsInput"}}};

function convertVariables(v) {
  return RescriptRelay.convertObj(v, variablesConverter, undefined, undefined);
}

var wrapResponseConverter = {"__root":{"createEvents_events_startDate":{"c":"Util.Datetime"},"createEvents_events_endDate":{"c":"Util.Datetime"}}};

var wrapResponseConverterMap = {
  "Util.Datetime": Util.Datetime.serialize
};

function convertWrapResponse(v) {
  return RescriptRelay.convertObj(v, wrapResponseConverter, wrapResponseConverterMap, null);
}

var responseConverter = {"__root":{"createEvents_events_startDate":{"c":"Util.Datetime"},"createEvents_events_endDate":{"c":"Util.Datetime"}}};

var responseConverterMap = {
  "Util.Datetime": Util.Datetime.parse
};

function convertResponse(v) {
  return RescriptRelay.convertObj(v, responseConverter, responseConverterMap, undefined);
}

var Internal = {
  variablesConverter: variablesConverter,
  variablesConverterMap: undefined,
  convertVariables: convertVariables,
  wrapResponseConverter: wrapResponseConverter,
  wrapResponseConverterMap: wrapResponseConverterMap,
  convertWrapResponse: convertWrapResponse,
  responseConverter: responseConverter,
  responseConverterMap: responseConverterMap,
  convertResponse: convertResponse,
  convertWrapRawResponse: convertWrapResponse,
  convertRawResponse: convertResponse
};

var Utils = {};

var node = ((function(){
var v0 = [
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "connections"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "input"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "input",
    "variableName": "input"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "concreteType": "Event",
  "kind": "LinkedField",
  "name": "events",
  "plural": true,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "__typename",
      "storageKey": null
    },
    (v2/*: any*/),
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
      "concreteType": "Activity",
      "kind": "LinkedField",
      "name": "activity",
      "plural": false,
      "selections": [
        (v2/*: any*/),
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
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "CreateClubEventsFormMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "CreateEventsResult",
        "kind": "LinkedField",
        "name": "createEvents",
        "plural": false,
        "selections": [
          (v3/*: any*/)
        ],
        "storageKey": null
      }
    ],
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "CreateClubEventsFormMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "CreateEventsResult",
        "kind": "LinkedField",
        "name": "createEvents",
        "plural": false,
        "selections": [
          (v3/*: any*/),
          {
            "alias": null,
            "args": null,
            "filters": null,
            "handle": "appendNode",
            "key": "",
            "kind": "LinkedHandle",
            "name": "events",
            "handleArgs": [
              {
                "kind": "Variable",
                "name": "connections",
                "variableName": "connections"
              },
              {
                "kind": "Literal",
                "name": "edgeTypeName",
                "value": "EventEdge"
              }
            ]
          }
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "5386dc7459aa4800d1638411579ebdd9",
    "id": null,
    "metadata": {},
    "name": "CreateClubEventsFormMutation",
    "operationKind": "mutation",
    "text": "mutation CreateClubEventsFormMutation(\n  $input: CreateEventsInput!\n) {\n  createEvents(input: $input) {\n    events {\n      __typename\n      id\n      title\n      details\n      activity {\n        id\n        name\n        slug\n      }\n      startDate\n      endDate\n      listed\n    }\n  }\n}\n"
  }
};
})());

export {
  Types ,
  Internal ,
  Utils ,
  node ,
}
/* node Not a pure module */
// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";

var Types = {};

var variablesConverter = {"updateViewerRsvpMessageInput":{},"__root":{"input":{"r":"updateViewerRsvpMessageInput"}}};

function convertVariables(v) {
  return RescriptRelay.convertObj(v, variablesConverter, undefined, undefined);
}

var wrapResponseConverter = {};

function convertWrapResponse(v) {
  return RescriptRelay.convertObj(v, wrapResponseConverter, undefined, null);
}

var responseConverter = {};

function convertResponse(v) {
  return RescriptRelay.convertObj(v, responseConverter, undefined, undefined);
}

var Internal = {
  variablesConverter: variablesConverter,
  variablesConverterMap: undefined,
  convertVariables: convertVariables,
  wrapResponseConverter: wrapResponseConverter,
  wrapResponseConverterMap: undefined,
  convertWrapResponse: convertWrapResponse,
  responseConverter: responseConverter,
  responseConverterMap: undefined,
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
    "name": "input"
  }
],
v1 = [
  {
    "alias": null,
    "args": [
      {
        "kind": "Variable",
        "name": "input",
        "variableName": "input"
      }
    ],
    "concreteType": "Rsvp",
    "kind": "LinkedField",
    "name": "updateViewerRsvpMessage",
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
        "name": "message",
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
    "name": "EventRsvpsUpdateMessageMutation",
    "selections": (v1/*: any*/),
    "type": "Mutation",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "EventRsvpsUpdateMessageMutation",
    "selections": (v1/*: any*/)
  },
  "params": {
    "cacheID": "e385412953d44b93bffd2fd2aa804791",
    "id": null,
    "metadata": {},
    "name": "EventRsvpsUpdateMessageMutation",
    "operationKind": "mutation",
    "text": "mutation EventRsvpsUpdateMessageMutation(\n  $input: UpdateViewerRsvpMessageInput!\n) {\n  updateViewerRsvpMessage(input: $input) {\n    id\n    message\n  }\n}\n"
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

// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";

var Types = {};

var variablesConverter = {"updateProfileInput":{},"__root":{"input":{"r":"updateProfileInput"}}};

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
    "kind": "Variable",
    "name": "input",
    "variableName": "input"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "fullName",
  "storageKey": null
},
v3 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "biography",
  "storageKey": null
},
v4 = {
  "alias": null,
  "args": null,
  "concreteType": "Error",
  "kind": "LinkedField",
  "name": "errors",
  "plural": true,
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "message",
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
    "name": "SettingsProfileFormMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "UpdateProfileResult",
        "kind": "LinkedField",
        "name": "updateProfile",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "viewer",
            "plural": false,
            "selections": [
              (v2/*: any*/),
              (v3/*: any*/)
            ],
            "storageKey": null
          },
          (v4/*: any*/)
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
    "name": "SettingsProfileFormMutation",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "UpdateProfileResult",
        "kind": "LinkedField",
        "name": "updateProfile",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "User",
            "kind": "LinkedField",
            "name": "viewer",
            "plural": false,
            "selections": [
              (v2/*: any*/),
              (v3/*: any*/),
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "id",
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          (v4/*: any*/)
        ],
        "storageKey": null
      }
    ]
  },
  "params": {
    "cacheID": "1524ec79395c3bcc75d6522a8b39e918",
    "id": null,
    "metadata": {},
    "name": "SettingsProfileFormMutation",
    "operationKind": "mutation",
    "text": "mutation SettingsProfileFormMutation(\n  $input: UpdateProfileInput!\n) {\n  updateProfile(input: $input) {\n    viewer {\n      fullName\n      biography\n      id\n    }\n    errors {\n      message\n    }\n  }\n}\n"
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
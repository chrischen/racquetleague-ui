// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";

var Types = {};

var fragmentConverter = {};

function convertFragment(v) {
  return RescriptRelay.convertObj(v, fragmentConverter, undefined, undefined);
}

var Internal = {
  fragmentConverter: fragmentConverter,
  fragmentConverterMap: undefined,
  convertFragment: convertFragment
};

var Utils = {};

var node = {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "DeferTestRouteFragment2",
  "selections": [
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "currentTime2",
      "storageKey": null
    }
  ],
  "type": "Query",
  "abstractKey": null
};

export {
  Types ,
  Internal ,
  Utils ,
  node ,
}
/* RescriptRelay Not a pure module */
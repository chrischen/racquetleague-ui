// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as Util from "../components/shared/Util.re.mjs";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";

var Types = {};

var fragmentConverter = {"__root":{"winners":{"f":""},"losers":{"f":""},"createdAt":{"c":"Util.Datetime"}}};

var fragmentConverterMap = {
  "Util.Datetime": Util.Datetime.parse
};

function convertFragment(v) {
  return RescriptRelay.convertObj(v, fragmentConverter, fragmentConverterMap, undefined);
}

var Internal = {
  fragmentConverter: fragmentConverter,
  fragmentConverterMap: fragmentConverterMap,
  convertFragment: convertFragment
};

var Utils = {};

var node = ((function(){
var v0 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
},
v1 = {
  "args": null,
  "kind": "FragmentSpread",
  "name": "MatchListTeam_user"
};
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "MatchList_match",
  "selections": [
    (v0/*: any*/),
    {
      "alias": null,
      "args": null,
      "concreteType": "User",
      "kind": "LinkedField",
      "name": "winners",
      "plural": true,
      "selections": [
        (v0/*: any*/),
        (v1/*: any*/)
      ],
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "concreteType": "User",
      "kind": "LinkedField",
      "name": "losers",
      "plural": true,
      "selections": [
        (v1/*: any*/)
      ],
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "score",
      "storageKey": null
    },
    {
      "alias": null,
      "args": null,
      "kind": "ScalarField",
      "name": "createdAt",
      "storageKey": null
    }
  ],
  "type": "Match",
  "abstractKey": null
};
})());

export {
  Types ,
  Internal ,
  Utils ,
  node ,
}
/* node Not a pure module */

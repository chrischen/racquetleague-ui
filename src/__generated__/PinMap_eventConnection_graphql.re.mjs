// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as Util from "../components/shared/Util.re.mjs";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";

var Types = {};

var fragmentConverter = {"__root":{"edges_node_startDate":{"c":"Util.Datetime"}}};

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
};
return {
  "argumentDefinitions": [],
  "kind": "Fragment",
  "metadata": null,
  "name": "PinMap_eventConnection",
  "selections": [
    {
      "alias": null,
      "args": null,
      "concreteType": "EventEdge",
      "kind": "LinkedField",
      "name": "edges",
      "plural": true,
      "selections": [
        {
          "alias": null,
          "args": null,
          "concreteType": "Event",
          "kind": "LinkedField",
          "name": "node",
          "plural": false,
          "selections": [
            (v0/*: any*/),
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
              "concreteType": "Location",
              "kind": "LinkedField",
              "name": "location",
              "plural": false,
              "selections": [
                (v0/*: any*/),
                {
                  "alias": null,
                  "args": null,
                  "concreteType": "Coords",
                  "kind": "LinkedField",
                  "name": "coords",
                  "plural": false,
                  "selections": [
                    {
                      "alias": null,
                      "args": null,
                      "kind": "ScalarField",
                      "name": "lng",
                      "storageKey": null
                    },
                    {
                      "alias": null,
                      "args": null,
                      "kind": "ScalarField",
                      "name": "lat",
                      "storageKey": null
                    }
                  ],
                  "storageKey": null
                },
                {
                  "alias": null,
                  "args": null,
                  "kind": "ScalarField",
                  "name": "address",
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
    }
  ],
  "type": "EventConnection",
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

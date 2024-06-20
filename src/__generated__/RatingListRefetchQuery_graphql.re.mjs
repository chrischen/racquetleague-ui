// Generated by ReScript, PLEASE EDIT WITH CARE
/* @generated */

import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as ReactRelay from "react-relay";
import * as RescriptRelay from "rescript-relay/src/RescriptRelay.re.mjs";

function makeRefetchVariables(activitySlug, after, before, first, namespace) {
  return {
          activitySlug: activitySlug,
          after: after,
          before: before,
          first: first,
          namespace: namespace
        };
}

var Types = {
  makeRefetchVariables: makeRefetchVariables
};

var variablesConverter = {};

function convertVariables(v) {
  return RescriptRelay.convertObj(v, variablesConverter, undefined, undefined);
}

var wrapResponseConverter = {"__root":{"":{"f":""}}};

function convertWrapResponse(v) {
  return RescriptRelay.convertObj(v, wrapResponseConverter, undefined, null);
}

var responseConverter = {"__root":{"":{"f":""}}};

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
    "name": "activitySlug"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "after"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "before"
  },
  {
    "defaultValue": 20,
    "kind": "LocalArgument",
    "name": "first"
  },
  {
    "defaultValue": null,
    "kind": "LocalArgument",
    "name": "namespace"
  }
],
v1 = [
  {
    "kind": "Variable",
    "name": "activitySlug",
    "variableName": "activitySlug"
  },
  {
    "kind": "Variable",
    "name": "after",
    "variableName": "after"
  },
  {
    "kind": "Variable",
    "name": "before",
    "variableName": "before"
  },
  {
    "kind": "Variable",
    "name": "first",
    "variableName": "first"
  },
  {
    "kind": "Variable",
    "name": "namespace",
    "variableName": "namespace"
  }
],
v2 = {
  "alias": null,
  "args": null,
  "kind": "ScalarField",
  "name": "id",
  "storageKey": null
};
return {
  "fragment": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Fragment",
    "metadata": null,
    "name": "RatingListRefetchQuery",
    "selections": [
      {
        "args": (v1/*: any*/),
        "kind": "FragmentSpread",
        "name": "RatingListFragment"
      }
    ],
    "type": "Query",
    "abstractKey": null
  },
  "kind": "Request",
  "operation": {
    "argumentDefinitions": (v0/*: any*/),
    "kind": "Operation",
    "name": "RatingListRefetchQuery",
    "selections": [
      {
        "alias": null,
        "args": (v1/*: any*/),
        "concreteType": "RatingConnection",
        "kind": "LinkedField",
        "name": "ratings",
        "plural": false,
        "selections": [
          {
            "alias": null,
            "args": null,
            "concreteType": "RatingEdge",
            "kind": "LinkedField",
            "name": "edges",
            "plural": true,
            "selections": [
              {
                "alias": null,
                "args": null,
                "concreteType": "Rating",
                "kind": "LinkedField",
                "name": "node",
                "plural": false,
                "selections": [
                  (v2/*: any*/),
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
                    "concreteType": "User",
                    "kind": "LinkedField",
                    "name": "user",
                    "plural": false,
                    "selections": [
                      (v2/*: any*/),
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "lineUsername",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "picture",
                        "storageKey": null
                      },
                      {
                        "alias": null,
                        "args": null,
                        "kind": "ScalarField",
                        "name": "gender",
                        "storageKey": null
                      }
                    ],
                    "storageKey": null
                  },
                  {
                    "alias": null,
                    "args": null,
                    "kind": "ScalarField",
                    "name": "__typename",
                    "storageKey": null
                  }
                ],
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "cursor",
                "storageKey": null
              }
            ],
            "storageKey": null
          },
          {
            "alias": null,
            "args": null,
            "concreteType": "PageInfo",
            "kind": "LinkedField",
            "name": "pageInfo",
            "plural": false,
            "selections": [
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "hasNextPage",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "hasPreviousPage",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "endCursor",
                "storageKey": null
              },
              {
                "alias": null,
                "args": null,
                "kind": "ScalarField",
                "name": "startCursor",
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
        "args": (v1/*: any*/),
        "filters": [
          "activitySlug",
          "namespace"
        ],
        "handle": "connection",
        "key": "RatingListFragment_ratings",
        "kind": "LinkedHandle",
        "name": "ratings"
      }
    ]
  },
  "params": {
    "cacheID": "14accb23cafc9a6bdcebcd68c28e8bb1",
    "id": null,
    "metadata": {},
    "name": "RatingListRefetchQuery",
    "operationKind": "query",
    "text": "query RatingListRefetchQuery(\n  $activitySlug: String!\n  $after: String\n  $before: String\n  $first: Int = 20\n  $namespace: String!\n) {\n  ...RatingListFragment_2Xn26q\n}\n\nfragment RatingListFragment_2Xn26q on Query {\n  ratings(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace) {\n    edges {\n      node {\n        id\n        ordinal\n        ...RatingList_rating\n        __typename\n      }\n      cursor\n    }\n    pageInfo {\n      hasNextPage\n      hasPreviousPage\n      endCursor\n      startCursor\n    }\n  }\n}\n\nfragment RatingList_rating on Rating {\n  id\n  ordinal\n  user {\n    id\n    lineUsername\n    picture\n    gender\n  }\n}\n"
  }
};
})());

function load(environment, variables, fetchPolicy, fetchKey, networkCacheConfig) {
  return ReactRelay.loadQuery(environment, node, convertVariables(variables), {
              fetchKey: fetchKey,
              fetchPolicy: fetchPolicy,
              networkCacheConfig: networkCacheConfig
            });
}

function queryRefToObservable(token) {
  return Caml_option.nullable_to_opt(token.source);
}

function queryRefToPromise(token) {
  return new Promise((function (resolve, param) {
                var o = queryRefToObservable(token);
                if (o !== undefined) {
                  Caml_option.valFromOption(o).subscribe({
                        complete: (function () {
                            resolve({
                                  TAG: "Ok",
                                  _0: undefined
                                });
                          })
                      });
                  return ;
                } else {
                  return resolve({
                              TAG: "Error",
                              _0: undefined
                            });
                }
              }));
}

export {
  Types ,
  Internal ,
  Utils ,
  node ,
  load ,
  queryRefToObservable ,
  queryRefToPromise ,
}
/* node Not a pure module */

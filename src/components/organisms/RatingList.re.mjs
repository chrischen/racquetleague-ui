// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Layout from "../shared/Layout.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as Core from "@lingui/core";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as LangProvider from "../shared/LangProvider.re.mjs";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";
import * as ReactExperimental from "rescript-relay/src/ReactExperimental.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as Solid from "@heroicons/react/24/solid";
import * as RatingList_rating_graphql from "../../__generated__/RatingList_rating_graphql.re.mjs";
import * as RatingListFragment_graphql from "../../__generated__/RatingListFragment_graphql.re.mjs";
import * as RatingListRefetchQuery_graphql from "../../__generated__/RatingListRefetchQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

var getConnectionNodes = RatingListFragment_graphql.Utils.getConnectionNodes;

var convertFragment = RatingListFragment_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(RatingListFragment_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, RatingListFragment_graphql.node, convertFragment);
}

var makeRefetchVariables = RatingListRefetchQuery_graphql.Types.makeRefetchVariables;

var convertRefetchVariables = RatingListRefetchQuery_graphql.Internal.convertVariables;

function useRefetchable(fRef) {
  return RescriptRelay_Fragment.useRefetchableFragment(RatingListFragment_graphql.node, convertFragment, convertRefetchVariables, fRef);
}

function usePagination(fRef) {
  return RescriptRelay_Fragment.usePaginationFragment(RatingListFragment_graphql.node, fRef, convertFragment, convertRefetchVariables);
}

function useBlockingPagination(fRef) {
  return RescriptRelay_Fragment.useBlockingPaginationFragment(RatingListFragment_graphql.node, fRef, convertFragment, convertRefetchVariables);
}

var Fragment = {
  getConnectionNodes: getConnectionNodes,
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment,
  use: use,
  useOpt: useOpt,
  makeRefetchVariables: makeRefetchVariables,
  convertRefetchVariables: convertRefetchVariables,
  useRefetchable: useRefetchable,
  usePagination: usePagination,
  useBlockingPagination: useBlockingPagination
};

var convertFragment$1 = RatingList_rating_graphql.Internal.convertFragment;

function use$1(fRef) {
  return RescriptRelay_Fragment.useFragment(RatingList_rating_graphql.node, convertFragment$1, fRef);
}

function useOpt$1(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, RatingList_rating_graphql.node, convertFragment$1);
}

var ItemFragment_gender_decode = RatingList_rating_graphql.Utils.gender_decode;

var ItemFragment_gender_fromString = RatingList_rating_graphql.Utils.gender_fromString;

var ItemFragment = {
  gender_decode: ItemFragment_gender_decode,
  gender_fromString: ItemFragment_gender_fromString,
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment$1,
  use: use$1,
  useOpt: useOpt$1
};

function make(key, id) {
  return [
          key,
          id
        ];
}

function toId(param) {
  return param[1];
}

var NodeId = {
  toId: toId,
  make: make
};

function toDomain(t) {
  var match = t.split(":");
  if (match.length !== 2) {
    return {
            TAG: "Error",
            _0: "InvalidNode"
          };
  }
  var key = match[0];
  var id = match[1];
  return {
          TAG: "Ok",
          _0: [
            key,
            id
          ]
        };
}

var NodeIdDto = {
  toDomain: toDomain
};

function td(prim) {
  return Core.i18n._(prim);
}

function ts(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

function RatingList$RatingItem(props) {
  var minRating = props.minRating;
  var maxRating = props.maxRating;
  var match = use$1(props.rating);
  var ordinal = match.ordinal;
  var id = match.id;
  var tier = Core__Option.getOr(Core__Option.map(Core__Option.map(ordinal, (function (rating) {
                  return (rating - minRating) / (maxRating - minRating) * 100;
                })), (function (__x) {
              return __x.toFixed(2);
            })), "0.0");
  return Core__Option.getOr(Core__Option.map(match.user, (function (user) {
                    return JsxRuntime.jsxs("li", {
                                children: [
                                  JsxRuntime.jsxs("div", {
                                        children: [
                                          JsxRuntime.jsxs("div", {
                                                children: [
                                                  Core__Option.getOr(Core__Option.map(user.picture, (function (picture) {
                                                              return JsxRuntime.jsx("img", {
                                                                          className: "h-24 w-24 flex-none rounded-full bg-gray-50",
                                                                          alt: "",
                                                                          src: picture
                                                                        });
                                                            })), null),
                                                  JsxRuntime.jsxs("div", {
                                                        children: [
                                                          JsxRuntime.jsx("p", {
                                                                children: JsxRuntime.jsxs(LangProvider.Router.Link.make, {
                                                                      to: "./p/" + user.id,
                                                                      children: [
                                                                        JsxRuntime.jsx("span", {
                                                                              className: "absolute inset-x-0 -top-px bottom-0"
                                                                            }),
                                                                        Core__Option.getOr(Core__Option.map(user.lineUsername, (function (lineUsername) {
                                                                                    return lineUsername;
                                                                                  })), null)
                                                                      ]
                                                                    }),
                                                                className: "text-lg mt-9 font-semibold leading-6 text-gray-900"
                                                              }),
                                                          JsxRuntime.jsx("p", {
                                                                children: JsxRuntime.jsx("a", {
                                                                      className: "relative truncate hover:underline",
                                                                      href: "#"
                                                                    }),
                                                                className: "mt-1 flex text-xs leading-5 text-gray-500"
                                                              })
                                                        ],
                                                        className: "min-w-0 flex-auto"
                                                      })
                                                ],
                                                className: "flex min-w-0 gap-x-4"
                                              }),
                                          JsxRuntime.jsxs("div", {
                                                children: [
                                                  JsxRuntime.jsxs("div", {
                                                        children: [
                                                          JsxRuntime.jsx("p", {
                                                                children: Core__Option.getOr(Core__Option.map(user.gender, (function (gender) {
                                                                            if (gender === "female" || gender === "male") {
                                                                              if (gender === "female") {
                                                                                return t`Female`;
                                                                              } else {
                                                                                return t`Male`;
                                                                              }
                                                                            } else {
                                                                              return "--";
                                                                            }
                                                                          })), null),
                                                                className: "text-sm leading-6 text-gray-900"
                                                              }),
                                                          JsxRuntime.jsx("p", {
                                                                children: Core__Option.getOr(Core__Option.map(ordinal, (function (ordinal) {
                                                                            return ordinal.toFixed(2);
                                                                          })), "ordinal missing"),
                                                                className: "mt-1 text-xs leading-5 text-gray-500"
                                                              })
                                                        ],
                                                        className: "sm:flex sm:flex-col sm:items-end"
                                                      }),
                                                  JsxRuntime.jsx(Solid.ChevronRightIcon, {
                                                        className: "h-5 w-5 flex-none text-gray-400",
                                                        "aria-hidden": "true"
                                                      })
                                                ],
                                                className: "flex shrink-0 items-center gap-x-4"
                                              })
                                        ],
                                        className: "flex justify-between gap-x-6 "
                                      }),
                                  JsxRuntime.jsx("div", {
                                        children: JsxRuntime.jsx("div", {
                                              className: "h-2 rounded-full bg-red-400",
                                              style: {
                                                width: tier + "%"
                                              }
                                            }),
                                        className: "overflow-hidden rounded-full bg-gray-200 mt-5"
                                      })
                                ],
                                className: "relative px-4 py-5 hover:bg-gray-50 sm:px-6 lg:px-8"
                              }, id);
                  })), null);
}

var RatingItem = {
  td: td,
  ts: ts,
  make: RatingList$RatingItem
};

function RatingList(props) {
  ReactExperimental.useTransition();
  var match = usePagination(props.ratings);
  var data = match.data;
  var ratings = getConnectionNodes(data.ratings);
  var pageInfo = data.ratings.pageInfo;
  var hasPrevious = pageInfo.hasPreviousPage;
  var maxRating = Core__Array.reduce(ratings, 0, (function (acc, next) {
          if (Core__Option.getOr(next.ordinal, 0) > acc) {
            return Core__Option.getOr(next.ordinal, 0);
          } else {
            return acc;
          }
        }));
  var minRating = Core__Array.reduce(ratings, maxRating, (function (acc, next) {
          if (Core__Option.getOr(next.ordinal, maxRating) < acc) {
            return Core__Option.getOr(next.ordinal, maxRating);
          } else {
            return acc;
          }
        }));
  return JsxRuntime.jsxs(Layout.Container.make, {
              children: [
                !match.isLoadingPrevious && hasPrevious ? Core__Option.getOr(Core__Option.map(pageInfo.startCursor, (function (startCursor) {
                              return JsxRuntime.jsx(LangProvider.Router.Link.make, {
                                          to: "./?before=" + encodeURIComponent(startCursor),
                                          children: t`...load higher rated players`
                                        });
                            })), null) : null,
                JsxRuntime.jsx("ul", {
                      children: ratings.map(function (edge) {
                            return JsxRuntime.jsx(RatingList$RatingItem, {
                                        rating: edge.fragmentRefs,
                                        maxRating: maxRating,
                                        minRating: minRating
                                      }, edge.id);
                          }),
                      className: "divide-y divide-gray-200",
                      role: "list"
                    }),
                match.hasNext && !match.isLoadingNext ? Core__Option.getOr(Core__Option.map(pageInfo.endCursor, (function (endCursor) {
                              return JsxRuntime.jsx(LangProvider.Router.Link.make, {
                                          to: "./?after=" + encodeURIComponent(endCursor),
                                          children: t`Load more players...`,
                                          className: "block py-4"
                                        });
                            })), null) : null
              ],
              className: "mt-4"
            });
}

var make$1 = RatingList;

var $$default = RatingList;

export {
  Fragment ,
  ItemFragment ,
  NodeId ,
  NodeIdDto ,
  RatingItem ,
  make$1 as make,
  $$default as default,
}
/*  Not a pure module */

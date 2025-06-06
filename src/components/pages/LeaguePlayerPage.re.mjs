// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Layout from "../shared/Layout.re.mjs";
import * as Rating from "../../lib/Rating.re.mjs";
import * as MatchList from "../organisms/MatchList.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as LeaguePlayerPageQuery_graphql from "../../__generated__/LeaguePlayerPageQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var convertVariables = LeaguePlayerPageQuery_graphql.Internal.convertVariables;

var convertResponse = LeaguePlayerPageQuery_graphql.Internal.convertResponse;

var convertWrapRawResponse = LeaguePlayerPageQuery_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, LeaguePlayerPageQuery_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, LeaguePlayerPageQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(LeaguePlayerPageQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(LeaguePlayerPageQuery_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(LeaguePlayerPageQuery_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(LeaguePlayerPageQuery_graphql.node, convertVariables);

var Query_gender_decode = LeaguePlayerPageQuery_graphql.Utils.gender_decode;

var Query_gender_fromString = LeaguePlayerPageQuery_graphql.Utils.gender_fromString;

var Query = {
  gender_decode: Query_gender_decode,
  gender_fromString: Query_gender_fromString,
  Operation: undefined,
  Types: undefined,
  convertVariables: convertVariables,
  convertResponse: convertResponse,
  convertWrapRawResponse: convertWrapRawResponse,
  use: use,
  useLoader: useLoader,
  usePreloaded: usePreloaded,
  $$fetch: $$fetch,
  fetchPromised: fetchPromised,
  retain: retain
};

var Params = {};

function LeaguePlayerPage(props) {
  var query = ReactRouterDom.useLoaderData();
  var match = usePreloaded(query.data);
  var fragmentRefs = match.fragmentRefs;
  var user = match.user;
  var params = ReactRouterDom.useParams();
  var activitySlug = params.activitySlug;
  var userRefs = Core__Option.map(user, (function (user) {
          return user.fragmentRefs;
        }));
  return Core__Option.map(user, (function (user) {
                return JsxRuntime.jsx(WaitForMessages.make, {
                            children: (function () {
                                var tmp = activitySlug === "pickleball" ? Core__Option.getOr(Core__Option.map(Core__Option.flatMap(user.rating, (function (r) {
                                                  return r.mu;
                                                })), (function (mu) {
                                              var dupr = Rating.guessDupr(mu);
                                              return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                                          children: [
                                                            JsxRuntime.jsx("dt", {
                                                                  children: t`Estimated DUPR`,
                                                                  className: "mt-4 truncate text-sm font-medium text-gray-500"
                                                                }),
                                                            JsxRuntime.jsx("dd", {
                                                                  children: dupr.toFixed(2),
                                                                  className: "mt-1 text-3xl font-semibold tracking-tight text-gray-900"
                                                                })
                                                          ]
                                                        });
                                            })), null) : null;
                                return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                            children: [
                                              JsxRuntime.jsx("div", {
                                                    children: JsxRuntime.jsx(Layout.Container.make, {
                                                          children: JsxRuntime.jsxs("div", {
                                                                children: [
                                                                  JsxRuntime.jsx("h2", {
                                                                        children: t`Player Profile Page`,
                                                                        className: "sr-only",
                                                                        id: "profile-overview-title"
                                                                      }),
                                                                  JsxRuntime.jsx("div", {
                                                                        children: JsxRuntime.jsx("div", {
                                                                              children: JsxRuntime.jsxs("div", {
                                                                                    children: [
                                                                                      JsxRuntime.jsx("div", {
                                                                                            children: Core__Option.getOr(Core__Option.map(user.picture, (function (picture) {
                                                                                                        return JsxRuntime.jsx("img", {
                                                                                                                    className: "mx-auto h-20 w-20 rounded-full",
                                                                                                                    alt: "",
                                                                                                                    src: picture
                                                                                                                  });
                                                                                                      })), null),
                                                                                            className: "flex-shrink-0"
                                                                                          }),
                                                                                      JsxRuntime.jsxs("div", {
                                                                                            children: [
                                                                                              JsxRuntime.jsx("p", {
                                                                                                    children: Core__Option.getOr(user.lineUsername, ""),
                                                                                                    className: "text-xl font-bold text-gray-900 sm:text-2xl"
                                                                                                  }),
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
                                                                                                    className: "text-sm font-medium text-gray-600"
                                                                                                  })
                                                                                            ],
                                                                                            className: "mt-4 text-center sm:mt-0 sm:pt-1 sm:text-left"
                                                                                          })
                                                                                    ],
                                                                                    className: "sm:flex sm:space-x-5 mx-auto"
                                                                                  }),
                                                                              className: "sm:flex sm:items-center sm:justify-between"
                                                                            }),
                                                                        className: "bg-white p-6"
                                                                      })
                                                                ],
                                                                className: "overflow-hidden rounded-lg bg-white"
                                                              })
                                                        }),
                                                    className: "border-b border-black-500"
                                                  }),
                                              JsxRuntime.jsxs(Layout.Container.make, {
                                                    children: [
                                                      JsxRuntime.jsx("h1", {
                                                            children: t`Player Profile Page`,
                                                            className: "sr-only"
                                                          }),
                                                      JsxRuntime.jsxs("div", {
                                                            children: [
                                                              JsxRuntime.jsx("div", {
                                                                    children: JsxRuntime.jsxs("section", {
                                                                          children: [
                                                                            JsxRuntime.jsx("h2", {
                                                                                  children: t`Match History`,
                                                                                  className: "sr-only",
                                                                                  id: "section-1-title"
                                                                                }),
                                                                            JsxRuntime.jsx("div", {
                                                                                  children: JsxRuntime.jsxs("div", {
                                                                                        children: [
                                                                                          JsxRuntime.jsx("h2", {
                                                                                                children: t`Match History`,
                                                                                                className: "text-2xl font-semibold text-gray-900"
                                                                                              }),
                                                                                          JsxRuntime.jsx(React.Suspense, {
                                                                                                children: Caml_option.some(JsxRuntime.jsx(MatchList.make, {
                                                                                                          matches: fragmentRefs,
                                                                                                          user: userRefs
                                                                                                        })),
                                                                                                fallback: Caml_option.some(JsxRuntime.jsx(Layout.Container.make, {
                                                                                                          children: t`Loading rankings...`
                                                                                                        }))
                                                                                              })
                                                                                        ],
                                                                                        className: "p-6"
                                                                                      }),
                                                                                  className: "overflow-hidden rounded-lg bg-white shadow"
                                                                                })
                                                                          ],
                                                                          "aria-labelledby": "section-1-title"
                                                                        }),
                                                                    className: "grid grid-cols-1 gap-4 lg:col-span-2"
                                                                  }),
                                                              JsxRuntime.jsx("div", {
                                                                    children: JsxRuntime.jsxs("section", {
                                                                          children: [
                                                                            JsxRuntime.jsx("h2", {
                                                                                  children: t`Rating`,
                                                                                  className: "sr-only",
                                                                                  id: "section-2-title"
                                                                                }),
                                                                            JsxRuntime.jsx("div", {
                                                                                  children: JsxRuntime.jsxs("div", {
                                                                                        children: [
                                                                                          JsxRuntime.jsx("dt", {
                                                                                                children: t`Rating`,
                                                                                                className: "truncate text-sm font-medium text-gray-500"
                                                                                              }),
                                                                                          JsxRuntime.jsx("dd", {
                                                                                                children: Core__Option.getOr(Core__Option.flatMap(user.rating, (function (r) {
                                                                                                            return Core__Option.map(r.ordinal, (function (__x) {
                                                                                                                          return __x.toFixed(2);
                                                                                                                        }));
                                                                                                          })), "Unrated"),
                                                                                                className: "mt-1 text-3xl font-semibold tracking-tight text-gray-900"
                                                                                              }),
                                                                                          tmp
                                                                                        ],
                                                                                        className: "p-6"
                                                                                      }),
                                                                                  className: "overflow-hidden rounded-lg bg-white shadow"
                                                                                })
                                                                          ],
                                                                          "aria-labelledby": "section-2-title"
                                                                        }),
                                                                    className: "grid grid-cols-1 gap-4"
                                                                  })
                                                            ],
                                                            className: "grid grid-cols-1 items-start gap-4 lg:grid-cols-3 lg:gap-8"
                                                          })
                                                    ],
                                                    className: "mt-5"
                                                  })
                                            ]
                                          });
                              })
                          });
              }));
}

var make = LeaguePlayerPage;

export {
  Query ,
  Params ,
  make ,
}
/*  Not a pure module */

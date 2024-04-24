// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Layout from "../shared/Layout.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as LocationPageQuery_graphql from "../../__generated__/LocationPageQuery_graphql.re.mjs";

import { t } from '@lingui/macro'
;

var convertVariables = LocationPageQuery_graphql.Internal.convertVariables;

var convertResponse = LocationPageQuery_graphql.Internal.convertResponse;

var convertWrapRawResponse = LocationPageQuery_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, LocationPageQuery_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, LocationPageQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(LocationPageQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(LocationPageQuery_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(LocationPageQuery_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(LocationPageQuery_graphql.node, convertVariables);

var Query = {
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

function LoginPage(props) {
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return JsxRuntime.jsxs(Layout.Container.make, {
                              children: [
                                JsxRuntime.jsxs("h1", {
                                      children: [
                                        JsxRuntime.jsx("div", {
                                              children: t`Login with Line`,
                                              className: "text-base leading-6 text-gray-500"
                                            }),
                                        JsxRuntime.jsx("div", {
                                              children: t`Privacy Disclosure`,
                                              className: "mt-1 text-2xl font-semibold leading-6 text-gray-900"
                                            })
                                      ]
                                    }),
                                JsxRuntime.jsx("h2", {
                                      children: t`We will collect the following information from your Line account`,
                                      className: "mt-4 text-lg font-semibold leading-6 text-gray-900"
                                    }),
                                JsxRuntime.jsxs("dl", {
                                      children: [
                                        JsxRuntime.jsx("dt", {
                                              children: t`Email Address`,
                                              className: "mt-4 text-lg font-semibold leading-6 text-gray-900"
                                            }),
                                        JsxRuntime.jsx("dd", {
                                              children: JsxRuntime.jsxs("ul", {
                                                    children: [
                                                      JsxRuntime.jsx("li", {
                                                            children: t`Notification of updates or cancellations to events (you can opt out)`,
                                                            className: "mt-1"
                                                          }),
                                                      JsxRuntime.jsx("li", {
                                                            children: t`Event organizers and other users cannot view your email`,
                                                            className: "mt-1"
                                                          })
                                                    ],
                                                    className: "list-disc list-inside"
                                                  }),
                                              className: "mt-2 text-base leading-6 text-gray-500"
                                            }),
                                        JsxRuntime.jsx("dt", {
                                              children: t`Display Name`,
                                              className: "mt-4 text-lg font-semibold leading-6 text-gray-900"
                                            }),
                                        JsxRuntime.jsx("dd", {
                                              children: t`Publicly displayed on event attendance lists`,
                                              className: "mt-2 text-base leading-6 text-gray-500"
                                            }),
                                        JsxRuntime.jsx("dt", {
                                              children: t`Profile Picture`,
                                              className: "mt-4 text-lg font-semibold leading-6 text-gray-900"
                                            }),
                                        JsxRuntime.jsx("dd", {
                                              children: t`Publicly displayed on event attendance lists`,
                                              className: "mt-2 text-base leading-6 text-gray-500"
                                            })
                                      ],
                                      className: ""
                                    }),
                                JsxRuntime.jsx("a", {
                                      children: t`login with Line`,
                                      className: "block mt-4 text-2xl",
                                      href: "/login"
                                    })
                              ]
                            });
                })
            });
}

var make = LoginPage;

export {
  Query ,
  make ,
}
/*  Not a pure module */

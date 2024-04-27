// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Layout from "../shared/Layout.re.mjs";
import * as EventsList from "../organisms/EventsList.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as EventLocation from "../organisms/EventLocation.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as LocationPageQuery_graphql from "../../__generated__/LocationPageQuery_graphql.re.mjs";

import { t } from '@lingui/macro'
;

var convertVariables = LocationPageQuery_graphql.Internal.convertVariables;

var convertResponse = LocationPageQuery_graphql.Internal.convertResponse;

RescriptRelay_Query.useQuery(convertVariables, LocationPageQuery_graphql.node, convertResponse);

RescriptRelay_Query.useLoader(convertVariables, LocationPageQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(LocationPageQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

RescriptRelay_Query.$$fetch(LocationPageQuery_graphql.node, convertResponse, convertVariables);

RescriptRelay_Query.fetchPromised(LocationPageQuery_graphql.node, convertResponse, convertVariables);

RescriptRelay_Query.retain(LocationPageQuery_graphql.node, convertVariables);

function LocationPage(props) {
  var data = ReactRouterDom.useLoaderData();
  var query = usePreloaded(data.data);
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return Core__Option.getOr(Core__Option.map(query.location, (function ($$location) {
                                    return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                                children: [
                                                  JsxRuntime.jsxs(Layout.Container.make, {
                                                        children: [
                                                          JsxRuntime.jsxs("h1", {
                                                                children: [
                                                                  JsxRuntime.jsx("div", {
                                                                        children: t`location`,
                                                                        className: "text-base leading-6 text-gray-500"
                                                                      }),
                                                                  JsxRuntime.jsx("div", {
                                                                        children: Core__Option.getOr($$location.name, "?"),
                                                                        className: "mt-1 text-2xl font-semibold leading-6 text-gray-900"
                                                                      })
                                                                ]
                                                              }),
                                                          JsxRuntime.jsx(EventLocation.make, {
                                                                location: $$location.fragmentRefs
                                                              })
                                                        ]
                                                      }),
                                                  JsxRuntime.jsx(EventsList.make, {
                                                        events: query.fragmentRefs
                                                      })
                                                ]
                                              });
                                  })), JsxRuntime.jsx(Layout.Container.make, {
                                  children: t`page not found`
                                }));
                })
            });
}

var make = LocationPage;

export {
  make ,
}
/*  Not a pure module */

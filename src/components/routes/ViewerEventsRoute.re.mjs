// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Grid from "../vanillaui/atoms/Grid.re.mjs";
import * as Util from "../shared/Util.re.mjs";
import * as React from "react";
import * as Layout from "../shared/Layout.re.mjs";
import * as Lingui from "../../locales/Lingui.re.mjs";
import * as RelayEnv from "../../entry/RelayEnv.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as PageTitle from "../vanillaui/atoms/PageTitle.re.mjs";
import * as EventsList from "../organisms/EventsList.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as ViewerEventsRouteQuery_graphql from "../../__generated__/ViewerEventsRouteQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var convertVariables = ViewerEventsRouteQuery_graphql.Internal.convertVariables;

var convertResponse = ViewerEventsRouteQuery_graphql.Internal.convertResponse;

var convertWrapRawResponse = ViewerEventsRouteQuery_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, ViewerEventsRouteQuery_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, ViewerEventsRouteQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(ViewerEventsRouteQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(ViewerEventsRouteQuery_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(ViewerEventsRouteQuery_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(ViewerEventsRouteQuery_graphql.node, convertVariables);

var EventsQuery = {
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

function ViewerEventsRoute(props) {
  var query = ReactRouterDom.useLoaderData();
  var match = usePreloaded(query.data);
  var fragmentRefs = match.fragmentRefs;
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                              children: [
                                JsxRuntime.jsx(Layout.Container.make, {
                                      children: JsxRuntime.jsx(Grid.make, {
                                            children: JsxRuntime.jsx(PageTitle.make, {
                                                  children: t`all events`
                                                })
                                          })
                                    }),
                                JsxRuntime.jsx(React.Suspense, {
                                      children: Caml_option.some(JsxRuntime.jsx(EventsList.make, {
                                                events: fragmentRefs
                                              })),
                                      fallback: Caml_option.some(JsxRuntime.jsx(Layout.Container.make, {
                                                children: "Loading events..."
                                              }))
                                    })
                              ]
                            });
                })
            });
}

var LoaderArgs = {};

function loadMessages(lang) {
  var tmp = lang === "ja" ? import("../../locales/src/components/pages/Events.re/ja") : import("../../locales/src/components/pages/Events.re/en");
  return [tmp.then(function (messages) {
                React.startTransition(function () {
                      Lingui.i18n.load(lang, messages.messages);
                    });
              })];
}

async function loader(param) {
  var params = param.params;
  var url = new URL(param.request.url);
  var after = url.searchParams.get("after");
  var before = url.searchParams.get("before");
  if (import.meta.env.SSR) {
    await Localized.loadMessages(params.lang, loadMessages);
  }
  return {
          data: Core__Option.map(RelayEnv.getRelayEnv(param.context, import.meta.env.SSR), (function (env) {
                  return ViewerEventsRouteQuery_graphql.load(env, {
                              after: after,
                              afterDate: Caml_option.some(Util.Datetime.fromDate(new Date())),
                              before: before,
                              filters: {
                                viewer: true
                              }
                            }, "store-or-network", undefined, undefined);
                })),
          i18nLoaders: import.meta.env.SSR ? undefined : Caml_option.some(Localized.loadMessages(params.lang, loadMessages))
        };
}

var HydrateFallbackElement = JsxRuntime.jsx("div", {
      children: "Loading fallback..."
    });

var make = ViewerEventsRoute;

var $$default = ViewerEventsRoute;

var Component = ViewerEventsRoute;

export {
  EventsQuery ,
  make ,
  $$default as default,
  Component ,
  LoaderArgs ,
  loadMessages ,
  loader ,
  HydrateFallbackElement ,
}
/*  Not a pure module */

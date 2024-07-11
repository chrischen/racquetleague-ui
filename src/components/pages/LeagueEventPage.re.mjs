// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Layout from "../shared/Layout.re.mjs";
import * as MatchList from "../organisms/MatchList.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as AddLeagueMatch from "../organisms/AddLeagueMatch.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as LeagueEventPageQuery_graphql from "../../__generated__/LeagueEventPageQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var convertVariables = LeagueEventPageQuery_graphql.Internal.convertVariables;

var convertResponse = LeagueEventPageQuery_graphql.Internal.convertResponse;

var convertWrapRawResponse = LeagueEventPageQuery_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, LeagueEventPageQuery_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, LeagueEventPageQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(LeagueEventPageQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(LeagueEventPageQuery_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(LeagueEventPageQuery_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(LeagueEventPageQuery_graphql.node, convertVariables);

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

function LeagueEventPage(props) {
  var query = ReactRouterDom.useLoaderData();
  var match = usePreloaded(query.data);
  var queryRefs = match.fragmentRefs;
  var $$event = match.event;
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return Core__Option.getOr(Core__Option.map($$event, (function ($$event) {
                                    return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                                children: [
                                                  JsxRuntime.jsx(React.Suspense, {
                                                        children: Caml_option.some(JsxRuntime.jsx(MatchList.make, {
                                                                  matches: queryRefs
                                                                })),
                                                        fallback: Caml_option.some(JsxRuntime.jsx(Layout.Container.make, {
                                                                  children: t`Loading rankings...`
                                                                }))
                                                      }),
                                                  JsxRuntime.jsx(AddLeagueMatch.make, {
                                                        event: $$event.fragmentRefs
                                                      })
                                                ]
                                              });
                                  })), null);
                })
            });
}

var make = LeagueEventPage;

export {
  Query ,
  make ,
}
/*  Not a pure module */

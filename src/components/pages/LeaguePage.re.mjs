// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Grid from "../vanillaui/atoms/Grid.re.mjs";
import * as React from "react";
import * as Layout from "../shared/Layout.re.mjs";
import * as PageTitle from "../vanillaui/atoms/PageTitle.re.mjs";
import * as RatingList from "../organisms/RatingList.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import JplLogoPng from "./jpl-logo.png";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as LeaguePageQuery_graphql from "../../__generated__/LeaguePageQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var jplLogo = JplLogoPng;

var convertVariables = LeaguePageQuery_graphql.Internal.convertVariables;

var convertResponse = LeaguePageQuery_graphql.Internal.convertResponse;

RescriptRelay_Query.useQuery(convertVariables, LeaguePageQuery_graphql.node, convertResponse);

RescriptRelay_Query.useLoader(convertVariables, LeaguePageQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(LeaguePageQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

RescriptRelay_Query.$$fetch(LeaguePageQuery_graphql.node, convertResponse, convertVariables);

RescriptRelay_Query.fetchPromised(LeaguePageQuery_graphql.node, convertResponse, convertVariables);

RescriptRelay_Query.retain(LeaguePageQuery_graphql.node, convertVariables);

function LeaguePage(props) {
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
                                                  children: JsxRuntime.jsx("img", {
                                                        alt: t`japan pickle league`,
                                                        src: jplLogo
                                                      })
                                                })
                                          })
                                    }),
                                JsxRuntime.jsx(React.Suspense, {
                                      children: Caml_option.some(JsxRuntime.jsx(RatingList.make, {
                                                ratings: fragmentRefs
                                              })),
                                      fallback: Caml_option.some(JsxRuntime.jsx(Layout.Container.make, {
                                                children: t`Loading rankings...`
                                              }))
                                    })
                              ]
                            });
                })
            });
}

var make = LeaguePage;

export {
  make ,
}
/*  Not a pure module */

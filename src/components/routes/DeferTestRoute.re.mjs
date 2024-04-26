// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as RelayEnv from "../../entry/RelayEnv.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as DeferTestRouteQuery_graphql from "../../__generated__/DeferTestRouteQuery_graphql.re.mjs";
import * as DeferTestRouteFragment_graphql from "../../__generated__/DeferTestRouteFragment_graphql.re.mjs";
import * as DeferTestRouteFragment2_graphql from "../../__generated__/DeferTestRouteFragment2_graphql.re.mjs";

var convertVariables = DeferTestRouteQuery_graphql.Internal.convertVariables;

var convertResponse = DeferTestRouteQuery_graphql.Internal.convertResponse;

var convertWrapRawResponse = DeferTestRouteQuery_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, DeferTestRouteQuery_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, DeferTestRouteQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(DeferTestRouteQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(DeferTestRouteQuery_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(DeferTestRouteQuery_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(DeferTestRouteQuery_graphql.node, convertVariables);

var DeferTestRouteQuery = {
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

var convertFragment = DeferTestRouteFragment_graphql.Internal.convertFragment;

function use$1(fRef) {
  return RescriptRelay_Fragment.useFragment(DeferTestRouteFragment_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, DeferTestRouteFragment_graphql.node, convertFragment);
}

var DeferTestRouteFragment = {
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment,
  use: use$1,
  useOpt: useOpt
};

var convertFragment$1 = DeferTestRouteFragment2_graphql.Internal.convertFragment;

function use$2(fRef) {
  return RescriptRelay_Fragment.useFragment(DeferTestRouteFragment2_graphql.node, convertFragment$1, fRef);
}

function useOpt$1(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, DeferTestRouteFragment2_graphql.node, convertFragment$1);
}

var DeferTestRouteFragment2 = {
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment$1,
  use: use$2,
  useOpt: useOpt$1
};

function DeferTestRoute$CurrentTime(props) {
  var query = use$1(props.fragmentRefs);
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                "Current time: ",
                Core__Option.getOr(Core__Option.map(query.currentTime, (function (__x) {
                            return __x.toString(undefined);
                          })), "0")
              ]
            });
}

var CurrentTime = {
  make: DeferTestRoute$CurrentTime
};

function DeferTestRoute$CurrentTime2(props) {
  var query = use$2(props.fragmentRefs);
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                "Current time2: ",
                Core__Option.getOr(Core__Option.map(query.currentTime2, (function (__x) {
                            return __x.toString(undefined);
                          })), "0")
              ]
            });
}

var CurrentTime2 = {
  make: DeferTestRoute$CurrentTime2
};

function DeferTestRoute$DeferTest(props) {
  var query = ReactRouterDom.useLoaderData();
  var match = usePreloaded(query.data);
  var fragmentRefs = match.fragmentRefs;
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsx(React.Suspense, {
                      children: Caml_option.some(JsxRuntime.jsx(DeferTestRoute$CurrentTime, {
                                fragmentRefs: fragmentRefs
                              })),
                      fallback: "..."
                    }),
                JsxRuntime.jsx(React.Suspense, {
                      children: Caml_option.some(JsxRuntime.jsx(DeferTestRoute$CurrentTime2, {
                                fragmentRefs: fragmentRefs
                              })),
                      fallback: "..."
                    })
              ]
            });
}

var DeferTest = {
  make: DeferTestRoute$DeferTest
};

var LoaderArgs = {};

async function loader(param) {
  return ReactRouterDom.defer({
              data: Core__Option.map(RelayEnv.getRelayEnv(param.context, import.meta.env.SSR), (function (env) {
                      return DeferTestRouteQuery_graphql.load(env, undefined, "store-or-network", undefined, undefined);
                    }))
            });
}

var Component = DeferTestRoute$DeferTest;

export {
  DeferTestRouteQuery ,
  DeferTestRouteFragment ,
  DeferTestRouteFragment2 ,
  CurrentTime ,
  CurrentTime2 ,
  DeferTest ,
  Component ,
  LoaderArgs ,
  loader ,
}
/* use Not a pure module */

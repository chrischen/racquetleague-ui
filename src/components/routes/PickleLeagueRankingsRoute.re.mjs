// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Lingui from "../../locales/Lingui.re.mjs";
import * as RelayEnv from "../../entry/RelayEnv.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as JsxRuntime from "react/jsx-runtime";
import * as LeagueRankingsPage from "../pages/LeagueRankingsPage.re.mjs";
import * as LeagueRankingsPageQuery_graphql from "../../__generated__/LeagueRankingsPageQuery_graphql.re.mjs";

var LoaderArgs = {};

function loadMessages(lang) {
  var tmp = lang === "ja" ? import("../../locales/src/components/pages/LeagueRankingsPage.re/ja") : import("../../locales/src/components/pages/LeagueRankingsPage.re/en");
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
          data: {
            query: (function (env) {
                  return LeagueRankingsPageQuery_graphql.load(env, {
                              activitySlug: "pickleball",
                              after: after,
                              before: before,
                              namespace: "doubles:rec"
                            }, "store-or-network", undefined, undefined);
                })(RelayEnv.getRelayEnv(param.context, import.meta.env.SSR))
          },
          i18nLoaders: import.meta.env.SSR ? undefined : Caml_option.some(Localized.loadMessages(params.lang, loadMessages))
        };
}

var HydrateFallbackElement = JsxRuntime.jsx("div", {
      children: "Loading fallback..."
    });

var Component = LeagueRankingsPage.make;

export {
  Component ,
  LoaderArgs ,
  loadMessages ,
  loader ,
  HydrateFallbackElement ,
}
/* HydrateFallbackElement Not a pure module */

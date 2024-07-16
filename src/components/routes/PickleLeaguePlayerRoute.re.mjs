// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Lingui from "../../locales/Lingui.re.mjs";
import * as Router from "../shared/Router.re.mjs";
import * as RelayEnv from "../../entry/RelayEnv.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as LeaguePlayerPage from "../pages/LeaguePlayerPage.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as LeaguePlayerPageQuery_graphql from "../../__generated__/LeaguePlayerPageQuery_graphql.re.mjs";

var LoaderArgs = {};

function loadMessages(lang) {
  var tmp = lang === "ja" ? import("../../locales/src/components/pages/LeaguePlayerPage.re/ja") : import("../../locales/src/components/pages/LeaguePlayerPage.re/en");
  return [tmp.then(function (messages) {
                React.startTransition(function () {
                      Lingui.i18n.load(lang, messages.messages);
                    });
              })];
}

async function loader(param) {
  var params = param.params;
  var url = new URL(param.request.url);
  var after = Router.SearchParams.get(url.searchParams, "after");
  var before = Router.SearchParams.get(url.searchParams, "before");
  if (import.meta.env.SSR) {
    await Localized.loadMessages(params.lang, loadMessages);
  }
  return {
          data: LeaguePlayerPageQuery_graphql.load(RelayEnv.getRelayEnv(param.context, import.meta.env.SSR), {
                activitySlug: "pickleball",
                after: after,
                before: before,
                first: 5,
                namespace: "doubles:rec",
                userId: params.userId
              }, "store-or-network", undefined, undefined),
          i18nLoaders: import.meta.env.SSR ? undefined : Caml_option.some(Localized.loadMessages(params.lang, loadMessages))
        };
}

var HydrateFallbackElement = JsxRuntime.jsx("div", {
      children: "Loading fallback..."
    });

var Component = LeaguePlayerPage.make;

export {
  Component ,
  LoaderArgs ,
  loadMessages ,
  loader ,
  HydrateFallbackElement ,
}
/* HydrateFallbackElement Not a pure module */

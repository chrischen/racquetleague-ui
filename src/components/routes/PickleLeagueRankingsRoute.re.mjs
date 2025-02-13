// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Lingui from "../../locales/Lingui.re.mjs";
import * as Router from "../shared/Router.re.mjs";
import * as RelayEnv from "../../entry/RelayEnv.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as JsxRuntime from "react/jsx-runtime";
import * as LeagueRankingsPage from "../pages/LeagueRankingsPage.re.mjs";
import * as LeagueRankingsPageQuery_graphql from "../../__generated__/LeagueRankingsPageQuery_graphql.re.mjs";

var LoaderArgs = {};

var loadMessages = Lingui.loadMessages({
      ja: import("../../locales/src/components/pages/LeagueRankingsPage.re/ja"),
      en: import("../../locales/src/components/pages/LeagueRankingsPage.re/en")
    });

async function loader(param) {
  var params = param.params;
  var url = new URL(param.request.url);
  var after = Router.SearchParams.get(url.searchParams, "after");
  var before = Router.SearchParams.get(url.searchParams, "before");
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
/* loadMessages Not a pure module */

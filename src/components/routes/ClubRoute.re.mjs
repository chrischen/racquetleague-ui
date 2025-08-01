// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Util from "../shared/Util.re.mjs";
import * as Lingui from "../../locales/Lingui.re.mjs";
import * as Router from "../shared/Router.re.mjs";
import * as ClubPage from "../pages/ClubPage.re.mjs";
import * as RelayEnv from "../../entry/RelayEnv.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as ClubPageQuery_graphql from "../../__generated__/ClubPageQuery_graphql.re.mjs";

var LoaderArgs = {};

var loadMessages = Lingui.loadMessages({
      ja: import("../../locales/src/components/pages/ClubPage.re/ja"),
      en: import("../../locales/src/components/pages/ClubPage.re/en")
    });

async function loader(param) {
  var params = param.params;
  var url = new URL(param.request.url);
  var after = Router.SearchParams.get(url.searchParams, "after");
  var before = Router.SearchParams.get(url.searchParams, "before");
  var token = Router.SearchParams.get(url.searchParams, "token");
  var afterDate = Core__Option.map(Router.SearchParams.get(url.searchParams, "afterDate"), (function (d) {
          return Util.Datetime.fromDate(new Date(d));
        }));
  var query = ClubPageQuery_graphql.load(RelayEnv.getRelayEnv(param.context, import.meta.env.SSR), {
        after: after,
        afterDate: afterDate,
        before: before,
        slug: params.slug,
        token: token
      }, "store-or-network", undefined, undefined);
  if (import.meta.env.SSR) {
    await Localized.loadMessages(params.lang, loadMessages);
  }
  return ReactRouterDom.defer({
              data: query,
              i18nLoaders: import.meta.env.SSR ? undefined : Caml_option.some(Localized.loadMessages(params.lang, loadMessages))
            });
}

var Component = ClubPage.make;

export {
  Component ,
  LoaderArgs ,
  loadMessages ,
  loader ,
}
/* loadMessages Not a pure module */

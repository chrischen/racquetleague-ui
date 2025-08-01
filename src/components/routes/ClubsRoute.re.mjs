// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Lingui from "../../locales/Lingui.re.mjs";
import * as ClubsPage from "../pages/ClubsPage.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as ReactRouterDom from "react-router-dom";

var LoaderArgs = {};

var loadMessages = Lingui.loadMessages({
      ja: import("../../locales/src/components/pages/ClubsPage.re/ja"),
      en: import("../../locales/src/components/pages/ClubsPage.re/en")
    });

async function loader(param) {
  var params = param.params;
  if (import.meta.env.SSR) {
    await Localized.loadMessages(params.lang, loadMessages);
  }
  return ReactRouterDom.defer({
              i18nLoaders: import.meta.env.SSR ? undefined : Caml_option.some(Localized.loadMessages(params.lang, loadMessages))
            });
}

var Component = ClubsPage.make;

export {
  Component ,
  LoaderArgs ,
  loadMessages ,
  loader ,
}
/* loadMessages Not a pure module */

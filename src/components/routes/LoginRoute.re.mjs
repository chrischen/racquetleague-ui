// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Lingui from "../../locales/Lingui.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as LoginPage from "../pages/LoginPage.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as ReactRouterDom from "react-router-dom";

var LoaderArgs = {};

function loadMessages(lang) {
  var tmp = lang === "ja" ? import("../../locales/src/components/pages/LoginPage.re/ja") : import("../../locales/src/components/pages/LoginPage.re/en");
  return [tmp.then(function (messages) {
                React.startTransition(function () {
                      Lingui.i18n.load(lang, messages.messages);
                    });
              })];
}

async function loader(param) {
  var params = param.params;
  if (import.meta.env.SSR) {
    await Localized.loadMessages(params.lang, loadMessages);
  }
  return ReactRouterDom.defer({
              i18nLoaders: import.meta.env.SSR ? undefined : Caml_option.some(Localized.loadMessages(params.lang, loadMessages))
            });
}

var Component = LoginPage.make;

export {
  Component ,
  LoaderArgs ,
  loadMessages ,
  loader ,
}
/* react Not a pure module */
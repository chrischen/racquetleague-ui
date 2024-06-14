// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Lingui from "../../locales/Lingui.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as ReactRouterDom from "react-router-dom";
import * as LoginLineErrorPage from "../pages/LoginLineErrorPage.re.mjs";

var LoaderArgs = {};

function loadMessages(lang) {
  var tmp = lang === "ja" ? import("../../locales/src/components/pages/LoginLineErrorPage.re/ja") : import("../../locales/src/components/pages/LoginLineErrorPage.re/en");
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

var Component = LoginLineErrorPage.make;

export {
  Component ,
  LoaderArgs ,
  loadMessages ,
  loader ,
}
/* react Not a pure module */
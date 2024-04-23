// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Lingui from "../../locales/Lingui.re.mjs";
import * as NotFound from "../pages/NotFound.re.mjs";
import * as ReactIntl from "react-intl";
import * as React from "@lingui/react";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";

function LangProvider(props) {
  var data = ReactRouterDom.useLoaderData();
  var match = data.lang;
  var locale;
  switch (match) {
    case "en" :
        locale = "en";
        break;
    case "ja" :
        locale = "ja";
        break;
    default:
      locale = undefined;
  }
  return JsxRuntime.jsx(React.I18nProvider, {
              i18n: Lingui.i18n,
              children: locale !== undefined ? JsxRuntime.jsx(ReactIntl.IntlProvider, {
                      locale: locale,
                      timeZone: "jst",
                      children: JsxRuntime.jsx(ReactRouterDom.Outlet, {})
                    }) : JsxRuntime.jsx(NotFound.make, {})
            });
}

var make = LangProvider;

export {
  make ,
}
/* Lingui Not a pure module */
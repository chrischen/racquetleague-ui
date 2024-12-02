// Generated by ReScript, PLEASE EDIT WITH CARE

import * as I18n from "../../lib/I18n.re.mjs";
import * as React from "react";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as React$1 from "@lingui/react";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";

function LangSwitch$LocaleButton(props) {
  var locale = props.locale;
  var locPath = I18n.getLangPath(locale.lang);
  if (props.active) {
    return JsxRuntime.jsx("span", {
                children: locale.display
              });
  } else {
    return JsxRuntime.jsx(ReactRouterDom.Link, {
                to: locPath + props.path,
                children: JsxRuntime.jsx("span", {
                      children: locale.display
                    })
              });
  }
}

var LocaleButton = {
  make: LangSwitch$LocaleButton
};

var locales = [
  {
    lang: "en",
    display: "english"
  },
  {
    lang: "ja",
    display: "日本語"
  }
];

function LangSwitch(props) {
  var match = React$1.useLingui();
  var locale = match.i18n.locale;
  var match$1 = ReactRouterDom.useLocation();
  var basePath = I18n.getBasePath(locale, match$1.pathname);
  return Belt_Array.mapWithIndex(locales, (function (index, loc) {
                return JsxRuntime.jsxs(React.Fragment, {
                            children: [
                              index > 0 ? " | " : null,
                              JsxRuntime.jsx(LangSwitch$LocaleButton, {
                                    locale: loc,
                                    path: basePath,
                                    active: loc.lang === locale
                                  })
                            ]
                          }, loc.lang);
              }));
}

var make = LangSwitch;

var $$default = LangSwitch;

export {
  LocaleButton ,
  locales ,
  make ,
  $$default as default,
}
/* react Not a pure module */

// Generated by ReScript, PLEASE EDIT WITH CARE

import * as UiAction from "../atoms/UiAction.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as Solid from "@heroicons/react/24/solid";

function ErrorAlert(props) {
  var ctaClick = props.ctaClick;
  return JsxRuntime.jsx("div", {
              children: JsxRuntime.jsxs("div", {
                    children: [
                      JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsx(Solid.LockClosedIcon, {
                                  className: "h-5 w-5 text-red-400",
                                  "aria-hidden": "true"
                                }),
                            className: "flex-shrink-0"
                          }),
                      JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsxs("p", {
                                  children: [
                                    props.children,
                                    Core__Option.getOr(Core__Option.flatMap(props.cta, (function (cta) {
                                                return Core__Option.map(ctaClick, (function (ctaClick) {
                                                              return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                                                          children: [
                                                                            " ",
                                                                            JsxRuntime.jsx(UiAction.make, {
                                                                                  onClick: (function (param) {
                                                                                      ctaClick();
                                                                                    }),
                                                                                  className: "font-medium text-red-700 underline hover:text-red-600",
                                                                                  children: cta
                                                                                })
                                                                          ]
                                                                        });
                                                            }));
                                              })), null)
                                  ],
                                  className: "text-sm text-red-700"
                                }),
                            className: "ml-3"
                          })
                    ],
                    className: "flex"
                  }),
              className: "border-l-4 border-red-400 bg-red-50 p-4"
            });
}

var make = ErrorAlert;

export {
  make ,
}
/* UiAction Not a pure module */

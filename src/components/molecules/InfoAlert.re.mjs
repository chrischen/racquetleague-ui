// Generated by ReScript, PLEASE EDIT WITH CARE

import * as UiAction from "../atoms/UiAction.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as Solid from "@heroicons/react/24/solid";

function InfoAlert(props) {
  var ctaClick = props.ctaClick;
  return JsxRuntime.jsx("div", {
              children: JsxRuntime.jsxs("div", {
                    children: [
                      JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsx(Solid.ExclamationTriangleIcon, {
                                  className: "h-5 w-5 text-yellow-400",
                                  "aria-hidden": "true"
                                }),
                            className: "flex-shrink-0"
                          }),
                      JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsxs("p", {
                                  children: [
                                    props.children,
                                    " ",
                                    JsxRuntime.jsx(UiAction.make, {
                                          onClick: (function (param) {
                                              ctaClick();
                                            }),
                                          className: "font-medium text-yellow-700 underline hover:text-yellow-600",
                                          children: props.cta
                                        })
                                  ],
                                  className: "text-sm text-yellow-700"
                                }),
                            className: "ml-3"
                          })
                    ],
                    className: "flex"
                  }),
              className: "border-l-4 border-yellow-400 bg-yellow-50 p-4"
            });
}

var make = InfoAlert;

export {
  make ,
}
/* UiAction Not a pure module */

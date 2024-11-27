// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as Core from "@linaria/core";
import * as React from "@headlessui/react";
import * as JsxRuntime from "react/jsx-runtime";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

function SeekingPartnerInput(props) {
  var checked = Core__Option.isSome(props.seekingPartner);
  return JsxRuntime.jsx(JsxRuntime.Fragment, {
              children: Caml_option.some(JsxRuntime.jsxs(React.Switch.Group, {
                        as: "div",
                        className: "flex items-center",
                        children: [
                          JsxRuntime.jsx(React.Switch, {
                                className: Core.cx(checked ? "bg-indigo-600" : "bg-gray-200", "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2"),
                                children: JsxRuntime.jsx("span", {
                                      "aria-hidden": true,
                                      className: Core.cx(checked ? "translate-x-5" : "translate-x-0", "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out")
                                    }),
                                checked: checked,
                                onChange: props.onChange
                              }),
                          JsxRuntime.jsxs(React.Switch.Label, {
                                as: "span",
                                className: "ml-3 text-sm",
                                children: [
                                  JsxRuntime.jsx("span", {
                                        children: t`seeking a doubles partner`,
                                        className: "font-medium text-gray-900"
                                      }),
                                  " ",
                                  JsxRuntime.jsx("span", {
                                        children: t`shows a badge next to your name in RSVP lists to tell people you are looking for a partner`,
                                        className: "text-gray-500"
                                      })
                                ]
                              })
                        ]
                      }))
            });
}

var make = SeekingPartnerInput;

export {
  make ,
}
/*  Not a pure module */
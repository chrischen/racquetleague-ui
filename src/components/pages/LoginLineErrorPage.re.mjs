// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Layout from "../shared/Layout.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";

import { t } from '@lingui/macro'
;

function LoginLineErrorPage(props) {
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return JsxRuntime.jsxs(Layout.Container.make, {
                              children: [
                                JsxRuntime.jsxs("h1", {
                                      children: [
                                        JsxRuntime.jsx("div", {
                                              children: t`login with Line`,
                                              className: "text-base leading-6 text-gray-500"
                                            }),
                                        JsxRuntime.jsx("div", {
                                              children: t`login failed`,
                                              className: "mt-1 text-2xl font-semibold leading-6 text-gray-900"
                                            })
                                      ]
                                    }),
                                JsxRuntime.jsx("h2", {
                                      children: t`are you in a private browsing mode?`,
                                      className: "mt-4 text-lg font-semibold leading-6 text-gray-900"
                                    }),
                                JsxRuntime.jsx("p", {
                                      children: t`please try again outside of private browsing as it can interfere with Line login. if the problem pursists, you can try the safe-mode login button below.`,
                                      className: "mt-2 text-base leading-6 text-gray-500"
                                    }),
                                JsxRuntime.jsx("a", {
                                      children: t`safe-mode login with Line`,
                                      className: "block mt-4 text-2xl",
                                      href: "/login?safe=true"
                                    })
                              ]
                            });
                })
            });
}

var make = LoginLineErrorPage;

export {
  make ,
}
/*  Not a pure module */

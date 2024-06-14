// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Layout from "../shared/Layout.re.mjs";
import * as PageTitle from "../vanillaui/atoms/PageTitle.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

function FindGamesPage(props) {
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return JsxRuntime.jsx(JsxRuntime.Fragment, {
                              children: Caml_option.some(JsxRuntime.jsx("div", {
                                        children: JsxRuntime.jsxs(Layout.Container.make, {
                                              children: [
                                                JsxRuntime.jsx(PageTitle.make, {
                                                      children: JsxRuntime.jsx("span", {
                                                            children: t`Where to Play`,
                                                            className: "text-white font-extrabold text-3xl"
                                                          })
                                                    }),
                                                JsxRuntime.jsxs("p", {
                                                      children: [
                                                        t`To participate in the league and win prizes, please join the league events.`,
                                                        " ",
                                                        JsxRuntime.jsx("a", {
                                                              children: t`Find League Games`,
                                                              className: "text-gray-200 border-red-200 rounded p-5 border-2",
                                                              href: "https://www.racquetleague.com"
                                                            })
                                                      ]
                                                    })
                                              ]
                                            }),
                                        className: "py-10 text-white bg-leaguePrimary"
                                      }))
                            });
                })
            });
}

var make = FindGamesPage;

export {
  make ,
}
/*  Not a pure module */
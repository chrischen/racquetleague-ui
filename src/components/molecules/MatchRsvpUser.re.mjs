// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as LangProvider from "../shared/LangProvider.re.mjs";
import * as Core from "@linaria/core";
import * as JsxRuntime from "react/jsx-runtime";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

function MatchRsvpUser(props) {
  var link = props.link;
  var __highlight = props.highlight;
  var __compact = props.compact;
  var user = props.user;
  var compact = __compact !== undefined ? __compact : false;
  var highlight = __highlight !== undefined ? __highlight : "Available";
  var tmp;
  if (link !== undefined) {
    var tmp$1;
    tmp$1 = highlight === "Queued" ? JsxRuntime.jsx("strong", {
            children: user.name,
            className: "text-lg"
          }) : user.name;
    tmp = JsxRuntime.jsxs(LangProvider.Router.Link.make, {
          to: link,
          children: [
            JsxRuntime.jsx("span", {
                  className: "absolute inset-x-0 -top-px bottom-0"
                }),
            tmp$1
          ]
        });
  } else {
    tmp = JsxRuntime.jsxs(JsxRuntime.Fragment, {
          children: [
            JsxRuntime.jsx("span", {
                  className: "absolute inset-x-0 -top-px bottom-0"
                }),
            user.name
          ]
        });
  }
  var tmp$2;
  switch (highlight) {
    case "Break" :
        tmp$2 = "bg-yellow-300";
        break;
    case "Available" :
        tmp$2 = "bg-white";
        break;
    case "Queued" :
        tmp$2 = "bg-green-300";
        break;
    case "Playing" :
        tmp$2 = "bg-white opacity-50 blur-sm";
        break;
    
  }
  return JsxRuntime.jsxs("div", {
              children: [
                Core__Option.getOr(Core__Option.map(user.picture, (function (picture) {
                            return JsxRuntime.jsx("img", {
                                        className: Core.cx(compact ? "h-8 w-8" : "h-16 w-16", "flex-none rounded-full bg-gray-50", "drop-shadow-lg"),
                                        alt: "",
                                        src: picture
                                      });
                          })), JsxRuntime.jsx("div", {
                          className: Core.cx(compact ? "h-8 w-8" : "h-16 w-16", "flex-none rounded-full bg-gray-50")
                        })),
                JsxRuntime.jsxs("div", {
                      children: [
                        JsxRuntime.jsx("p", {
                              children: tmp,
                              className: "text-2xl font-semibold leading-6 text-gray-900"
                            }),
                        JsxRuntime.jsx("p", {
                              children: JsxRuntime.jsx("span", {
                                    className: "relative truncate hover:underline"
                                  }),
                              className: "mt-1 flex text-xs leading-5 text-gray-500"
                            })
                      ],
                      className: "min-w-0 flex-auto"
                    })
              ],
              className: Core.cx("relative flex min-w-0 gap-x-4", "w-full", "rounded-lg shadow", compact ? "p-2" : "p-4", tmp$2)
            });
}

var make = MatchRsvpUser;

export {
  make ,
}
/*  Not a pure module */

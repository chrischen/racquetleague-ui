// Generated by ReScript, PLEASE EDIT WITH CARE

import * as EventsList from "../organisms/EventsList.mjs";
import * as Core from "@linaria/core";
import * as JsxRuntime from "react/jsx-runtime";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

function Events(props) {
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsx("h1", {
                      children: (t`All Events`)
                    }),
                JsxRuntime.jsx("div", {
                      className: Core.cx("grid", "grid-cols-1", "gap-y-10", "sm:grid-cols-2", "gap-x-6", "lg:grid-cols-3", "xl:gap-x-8")
                    }),
                JsxRuntime.jsx(EventsList.make, {
                      events: props.events
                    })
              ],
              className: "bg-white"
            });
}

var make = Events;

var $$default = Events;

export {
  make ,
  $$default ,
  $$default as default,
}
/*  Not a pure module */

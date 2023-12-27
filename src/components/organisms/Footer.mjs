// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Nav from "./Nav.mjs";
import * as JsxRuntime from "react/jsx-runtime";

import { css, cx } from '@linaria/core'
;

var style = (css`

    border-color: rgba(127, 127, 127, 0.3);
    @apply border-t py-3 mt-3;
    &> div {
      @apply sm:grid sm:grid-cols-2 md:grid-cols-3 gap-4 text-xs leading-5;
      h3 {
        @apply text-xl mb-2;
      }
      ul {
        @apply list-none;
      }

    }
    `);

var Root = {
  style: style
};

function Footer(props) {
  return JsxRuntime.jsx("div", {
              children: JsxRuntime.jsx(Nav.LayoutContainer.make, {
                    children: JsxRuntime.jsx("div", {
                          children: "Copyright the Racquet League Club"
                        })
                  }),
              className: style
            });
}

var make = Footer;

var $$default = Footer;

export {
  Root ,
  make ,
  $$default ,
  $$default as default,
}
/*  Not a pure module */
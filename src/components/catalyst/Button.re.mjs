// Generated by ReScript, PLEASE EDIT WITH CARE

import * as ButtonTsx from "./button.tsx";
import * as JsxRuntime from "react/jsx-runtime";

var make = ButtonTsx.Button;

var Button = {
  make: make
};

var make$1 = ButtonTsx.TouchTarget;

var TouchTarget = {
  make: make$1
};

function Button$makeExample(props) {
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsx(make, {
                      children: "Default Button"
                    }),
                JsxRuntime.jsx(make, {
                      color: "blue",
                      children: "Blue Button"
                    }),
                JsxRuntime.jsx(make, {
                      outline: true,
                      children: "Outline Button"
                    }),
                JsxRuntime.jsx(make, {
                      plain: true,
                      children: "Plain Button"
                    }),
                JsxRuntime.jsx(make, {
                      children: "Link Button",
                      href: "/some/path"
                    }),
                JsxRuntime.jsx(make, {
                      children: "Disabled Button",
                      disabled: true
                    }),
                JsxRuntime.jsx(make, {
                      children: "Click Me",
                      onClick: (function (param) {
                          console.log("Clicked!");
                        })
                    }),
                JsxRuntime.jsx(make, {
                      children: JsxRuntime.jsx(make$1, {
                            children: "Button with explicit TouchTarget"
                          })
                    })
              ]
            });
}

var makeExample = Button$makeExample;

export {
  Button ,
  TouchTarget ,
  makeExample ,
}
/* make Not a pure module */

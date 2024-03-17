// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.mjs";
import * as Core from "@linaria/core";
import * as Nav_user_graphql from "../../__generated__/Nav_user_graphql.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as NavigationMenu from "../ui/navigation-menu";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var convertFragment = Nav_user_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(Nav_user_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, Nav_user_graphql.node, convertFragment);
}

var Fragment = {
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment,
  use: use,
  useOpt: useOpt
};

function Nav$LayoutContainer(props) {
  return JsxRuntime.jsx("div", {
              children: props.children,
              className: Core.cx("container", "mx-auto", "px-4", "sm:px-6", "lg:px-8")
            });
}

var LayoutContainer = {
  make: Nav$LayoutContainer
};

var make = NavigationMenu.MenuInstance;

var MenuInstance = {
  make: make
};

function Nav(props) {
  var match = use(props.fragmentRefs);
  return JsxRuntime.jsx("div", {
              children: JsxRuntime.jsx("header", {
                    children: JsxRuntime.jsx("nav", {
                          children: JsxRuntime.jsxs("div", {
                                children: [
                                  JsxRuntime.jsx(ReactRouterDom.Link, {
                                        to: "/",
                                        children: JsxRuntime.jsx("span", {
                                              children: "Racquet League"
                                            })
                                      }),
                                  " - ",
                                  Core__Option.getOr(Core__Option.flatMap(match.viewer, (function (viewer) {
                                              return Core__Option.map(viewer.user.lineUsername, (function (lineUsername) {
                                                            return JsxRuntime.jsx("span", {
                                                                        children: lineUsername
                                                                      });
                                                          }));
                                            })), JsxRuntime.jsx("a", {
                                            children: "Login",
                                            href: "/login"
                                          })),
                                  " ",
                                  JsxRuntime.jsx("a", {
                                        children: (t`(Logout)`),
                                        href: "/logout"
                                      }),
                                  JsxRuntime.jsx(ReactRouterDom.Link, {
                                        to: "/jp",
                                        children: JsxRuntime.jsx("span", {
                                              children: "日本語"
                                            })
                                      }),
                                  " | ",
                                  JsxRuntime.jsx(ReactRouterDom.Link, {
                                        to: "/",
                                        children: JsxRuntime.jsx("span", {
                                              children: "EN"
                                            })
                                      })
                                ]
                              })
                        })
                  })
            });
}

var make$1 = Nav;

var $$default = Nav;

export {
  Fragment ,
  LayoutContainer ,
  MenuInstance ,
  make$1 as make,
  $$default as default,
}
/*  Not a pure module */

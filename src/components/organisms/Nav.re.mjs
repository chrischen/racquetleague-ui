// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Layout from "../shared/Layout.re.mjs";
import * as LoginLink from "../molecules/LoginLink.re.mjs";
import * as LangSwitch from "../molecules/LangSwitch.re.mjs";
import * as LogoutLink from "../molecules/LogoutLink.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as LangProvider from "../shared/LangProvider.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as Nav_query_graphql from "../../__generated__/Nav_query_graphql.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as Nav_viewer_graphql from "../../__generated__/Nav_viewer_graphql.re.mjs";
import * as NavigationMenu from "../ui/navigation-menu";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var convertFragment = Nav_query_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(Nav_query_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, Nav_query_graphql.node, convertFragment);
}

var Fragment = {
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment,
  use: use,
  useOpt: useOpt
};

var convertFragment$1 = Nav_viewer_graphql.Internal.convertFragment;

function use$1(fRef) {
  return RescriptRelay_Fragment.useFragment(Nav_viewer_graphql.node, convertFragment$1, fRef);
}

function useOpt$1(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, Nav_viewer_graphql.node, convertFragment$1);
}

var ViewerFragment = {
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment$1,
  use: use$1,
  useOpt: useOpt$1
};

function Nav$Viewer(props) {
  var viewer = use$1(props.viewer);
  return Core__Option.getOr(Core__Option.flatMap(viewer.user, (function (user) {
                    return Core__Option.map(user.lineUsername, (function (lineUsername) {
                                  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                              children: [
                                                JsxRuntime.jsx("span", {
                                                      children: lineUsername
                                                    }),
                                                " ",
                                                JsxRuntime.jsx(LogoutLink.make, {})
                                              ]
                                            });
                                }));
                  })), JsxRuntime.jsx(LoginLink.make, {}));
}

var Viewer = {
  make: Nav$Viewer
};

var make = NavigationMenu.MenuInstance;

var MenuInstance = {
  make: make
};

function Nav(props) {
  var query = use(props.query);
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return JsxRuntime.jsx(Layout.Container.make, {
                              children: JsxRuntime.jsx("header", {
                                    children: JsxRuntime.jsxs("nav", {
                                          children: [
                                            JsxRuntime.jsx(LangProvider.Router.Link.make, {
                                                  to: "/",
                                                  children: JsxRuntime.jsx("span", {
                                                        children: t`racquet league`
                                                      })
                                                }),
                                            " - ",
                                            Core__Option.getOr(Core__Option.map(query.viewer, (function (viewer) {
                                                        return JsxRuntime.jsx(React.Suspense, {
                                                                    children: Caml_option.some(JsxRuntime.jsx(Nav$Viewer, {
                                                                              viewer: viewer.fragmentRefs
                                                                            })),
                                                                    fallback: "..."
                                                                  });
                                                      })), JsxRuntime.jsx(LoginLink.make, {})),
                                            " - ",
                                            JsxRuntime.jsx(LangSwitch.make, {}),
                                            " - ",
                                            Core__Option.getOr(Core__Option.map(Core__Option.flatMap(query.viewer, (function (viewer) {
                                                            return Core__Option.flatMap(viewer.user, (function (user) {
                                                                          return Core__Array.indexOfOpt([
                                                                                      "Hasby Riduan",
                                                                                      "hasbyriduan9",
                                                                                      "notchrischen",
                                                                                      "Matthew",
                                                                                      "David Vo",
                                                                                      "Kai"
                                                                                    ], Core__Option.getOr(user.lineUsername, ""));
                                                                        }));
                                                          })), (function (param) {
                                                        return JsxRuntime.jsx(LangProvider.Router.Link.make, {
                                                                    to: "/events/create",
                                                                    children: "Add Event"
                                                                  });
                                                      })), null)
                                          ]
                                        })
                                  }),
                              className: "mt-4"
                            });
                })
            });
}

var make$1 = Nav;

var $$default = Nav;

export {
  Fragment ,
  ViewerFragment ,
  Viewer ,
  MenuInstance ,
  make$1 as make,
  $$default as default,
}
/*  Not a pure module */

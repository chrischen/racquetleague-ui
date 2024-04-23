// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Grid from "../vanillaui/atoms/Grid.re.mjs";
import * as React from "react";
import * as Layout from "../shared/Layout.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as FormSection from "../molecules/forms/FormSection.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as FramerMotion from "framer-motion";
import * as CreateLocation from "../organisms/CreateLocation.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as AppContext from "../layouts/appContext";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as CreateEvent_query_graphql from "../../__generated__/CreateEvent_query_graphql.re.mjs";
import * as CreateEventRefetchQuery_graphql from "../../__generated__/CreateEventRefetchQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var getConnectionNodes = CreateEvent_query_graphql.Utils.getConnectionNodes;

var convertFragment = CreateEvent_query_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(CreateEvent_query_graphql.node, convertFragment, fRef);
}

function CreateEvent(props) {
  ReactRouterDom.useLocation();
  var data = use(props.locations);
  var locations = getConnectionNodes(data.locations);
  var match = React.useState(function () {
        return false;
      });
  var setShowCreateLocation = match[1];
  var showCreateLocation = match[0];
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return JsxRuntime.jsx(Layout.Container.make, {
                              children: JsxRuntime.jsxs(Grid.make, {
                                    children: [
                                      JsxRuntime.jsx(FormSection.make, {
                                            title: t`Event Location`,
                                            description: Caml_option.some(t`Choose the location where this event will be held.`),
                                            children: JsxRuntime.jsxs("div", {
                                                  children: [
                                                    JsxRuntime.jsx("ul", {
                                                          children: locations.map(function (node) {
                                                                return JsxRuntime.jsx("li", {
                                                                            children: JsxRuntime.jsx(ReactRouterDom.Link, {
                                                                                  to: encodeURIComponent(node.id),
                                                                                  children: Core__Option.getOr(node.name, "?")
                                                                                })
                                                                          }, node.id);
                                                              })
                                                        }),
                                                    JsxRuntime.jsxs("a", {
                                                          children: [
                                                            showCreateLocation ? "- " : "+ ",
                                                            t`Add New Location`
                                                          ],
                                                          href: "#",
                                                          onClick: (function (param) {
                                                              setShowCreateLocation(function (prev) {
                                                                    return !prev;
                                                                  });
                                                            })
                                                        }),
                                                    JsxRuntime.jsx(FramerMotion.AnimatePresence, {
                                                          mode: "sync",
                                                          children: showCreateLocation ? JsxRuntime.jsx(FramerMotion.motion.div, {
                                                                  className: "",
                                                                  style: {
                                                                    opacity: 1,
                                                                    y: 0
                                                                  },
                                                                  animate: {
                                                                    opacity: 1,
                                                                    scale: 1,
                                                                    y: 0.00
                                                                  },
                                                                  initial: {
                                                                    opacity: 0,
                                                                    scale: 1,
                                                                    y: -50
                                                                  },
                                                                  exit: {
                                                                    opacity: 0,
                                                                    scale: 1,
                                                                    y: -50
                                                                  },
                                                                  children: Caml_option.some(JsxRuntime.jsx(CreateLocation.make, {
                                                                            onCancel: (function (param) {
                                                                                setShowCreateLocation(function (param) {
                                                                                      return false;
                                                                                    });
                                                                              })
                                                                          }))
                                                                }) : null
                                                        })
                                                  ],
                                                  className: "mt-10 grid grid-cols-1 gap-x-6 gap-y-8"
                                                })
                                          }),
                                      JsxRuntime.jsx(FramerMotion.AnimatePresence, {
                                            mode: "wait",
                                            children: JsxRuntime.jsx(ReactRouterDom.Outlet, {})
                                          })
                                    ]
                                  })
                            });
                })
            });
}

var make = CreateEvent;

export {
  make ,
}
/*  Not a pure module */
// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Avatar from "../catalyst/Avatar.re.mjs";
import * as Navbar from "../catalyst/Navbar.re.mjs";
import * as Sidebar from "../catalyst/Sidebar.re.mjs";
import * as Dropdown from "../catalyst/Dropdown.re.mjs";
import * as LoginLink from "../molecules/LoginLink.re.mjs";
import * as LangSwitch from "../molecules/LangSwitch.re.mjs";
import * as LogoutLink from "../molecules/LogoutLink.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as GlobalQuery from "../shared/GlobalQuery.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as LangProvider from "../shared/LangProvider.re.mjs";
import * as StackedLayout from "../catalyst/StackedLayout.re.mjs";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";
import * as ReactRouterDom from "react-router-dom";
import * as React from "@headlessui/react";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as Solid from "@heroicons/react/24/solid";
import * as DefaultLayout2Query_graphql from "../../__generated__/DefaultLayout2Query_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

import '../../global/static.css'
;

var convertVariables = DefaultLayout2Query_graphql.Internal.convertVariables;

var convertResponse = DefaultLayout2Query_graphql.Internal.convertResponse;

var convertWrapRawResponse = DefaultLayout2Query_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, DefaultLayout2Query_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, DefaultLayout2Query_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(DefaultLayout2Query_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(DefaultLayout2Query_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(DefaultLayout2Query_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(DefaultLayout2Query_graphql.node, convertVariables);

var Query = {
  Operation: undefined,
  Types: undefined,
  convertVariables: convertVariables,
  convertResponse: convertResponse,
  convertWrapRawResponse: convertWrapRawResponse,
  use: use,
  useLoader: useLoader,
  usePreloaded: usePreloaded,
  $$fetch: $$fetch,
  fetchPromised: fetchPromised,
  retain: retain
};

function ts(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

var navItems = [
  {
    label: t`Events`,
    url: "/"
  },
  {
    label: t`Rankings`,
    url: "/league/badminton"
  }
];

function DefaultLayout2$Layout(props) {
  var viewer = props.viewer;
  var gviewer = Core__Option.map(viewer, (function (v) {
          return v.fragmentRefs;
        }));
  return JsxRuntime.jsx(GlobalQuery.Provider.make, {
              value: gviewer,
              children: JsxRuntime.jsx(StackedLayout.make, {
                    navbar: Caml_option.some(JsxRuntime.jsxs(Navbar.make, {
                              children: [
                                JsxRuntime.jsx(React.Menu, {
                                      children: JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                            className: "max-lg:hidden",
                                            as: Navbar.NavbarItem.make,
                                            children: [
                                              JsxRuntime.jsx(Navbar.NavbarLabel.make, {
                                                    children: "Racquet League"
                                                  }),
                                              JsxRuntime.jsx(Solid.ChevronDownIcon, {})
                                            ]
                                          })
                                    }),
                                JsxRuntime.jsx(Navbar.NavbarDivider.make, {
                                      className: "max-lg:hidden"
                                    }),
                                JsxRuntime.jsx(Navbar.NavbarSection.make, {
                                      className: "max-lg:hidden",
                                      children: navItems.map(function (param) {
                                            var label = param.label;
                                            return JsxRuntime.jsx(Navbar.NavbarItem.make, {
                                                        children: JsxRuntime.jsx(LangProvider.Router.NavLink.make, {
                                                              to: param.url,
                                                              children: label
                                                            })
                                                      }, label);
                                          })
                                    }),
                                JsxRuntime.jsx(Navbar.NavbarSpacer.make, {}),
                                JsxRuntime.jsx(Navbar.NavbarSection.make, {
                                      className: "max-lg:hidden",
                                      children: JsxRuntime.jsx(LangSwitch.make, {})
                                    }),
                                JsxRuntime.jsx(Navbar.NavbarSpacer.make, {}),
                                JsxRuntime.jsxs(Navbar.NavbarSection.make, {
                                      children: [
                                        JsxRuntime.jsx(Navbar.NavbarItem.make, {
                                              href: "/search",
                                              "aria-label": "Search",
                                              children: ""
                                            }),
                                        JsxRuntime.jsx(Navbar.NavbarItem.make, {
                                              href: "/inbox",
                                              "aria-label": "Inbox",
                                              children: ""
                                            }),
                                        Core__Option.getOr(Core__Option.flatMap(viewer, (function (v) {
                                                    return Core__Option.map(v.user, (function (user) {
                                                                  return JsxRuntime.jsxs(React.Menu, {
                                                                              children: [
                                                                                JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                                                                      as: Navbar.NavbarItem.make,
                                                                                      children: [
                                                                                        Core__Option.getOr(user.lineUsername, ""),
                                                                                        JsxRuntime.jsx(Avatar.make, {
                                                                                              src: user.picture,
                                                                                              square: true
                                                                                            })
                                                                                      ]
                                                                                    }),
                                                                                JsxRuntime.jsx(Dropdown.DropdownMenu.make, {
                                                                                      className: "min-w-64",
                                                                                      anchor: "bottom end",
                                                                                      children: JsxRuntime.jsx(Dropdown.DropdownItem.make, {
                                                                                            href: "/logout",
                                                                                            children: JsxRuntime.jsx(Dropdown.DropdownLabel.make, {
                                                                                                  children: JsxRuntime.jsx(LogoutLink.make, {})
                                                                                                })
                                                                                          })
                                                                                    })
                                                                              ]
                                                                            });
                                                                }));
                                                  })), JsxRuntime.jsx(LoginLink.make, {}))
                                      ]
                                    })
                              ]
                            })),
                    sidebar: Caml_option.some(JsxRuntime.jsxs(Sidebar.Sidebar.make, {
                              children: [
                                JsxRuntime.jsx(Sidebar.SidebarHeader.make, {
                                      children: JsxRuntime.jsx(React.Menu, {
                                            children: JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                                  className: "lg:mb-2.5",
                                                  as: Sidebar.SidebarItem.make,
                                                  children: [
                                                    JsxRuntime.jsx(Sidebar.SidebarLabel.make, {
                                                          children: t`Racquet League`
                                                        }),
                                                    JsxRuntime.jsx(Solid.ChevronDownIcon, {})
                                                  ]
                                                })
                                          })
                                    }),
                                JsxRuntime.jsx(Sidebar.SidebarBody.make, {
                                      children: JsxRuntime.jsx(Sidebar.SidebarSection.make, {
                                            children: navItems.map(function (param) {
                                                  var label = param.label;
                                                  return JsxRuntime.jsx(Sidebar.SidebarItem.make, {
                                                              children: JsxRuntime.jsx(LangProvider.Router.NavLink.make, {
                                                                    to: param.url,
                                                                    children: label
                                                                  })
                                                            }, label);
                                                })
                                          })
                                    })
                              ]
                            })),
                    children: props.children
                  })
            });
}

var Layout = {
  make: DefaultLayout2$Layout
};

function DefaultLayout2(props) {
  var query = ReactRouterDom.useLoaderData();
  var match = usePreloaded(query.data);
  return JsxRuntime.jsx(DefaultLayout2$Layout, {
              children: JsxRuntime.jsx(ReactRouterDom.Outlet, {}),
              viewer: match.viewer
            });
}

var make = DefaultLayout2;

export {
  Query ,
  ts ,
  navItems ,
  Layout ,
  make ,
}
/*  Not a pure module */

// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Avatar from "../catalyst/Avatar.re.mjs";
import * as Navbar from "../catalyst/Navbar.re.mjs";
import * as Sidebar from "../catalyst/Sidebar.re.mjs";
import * as Dropdown from "../catalyst/Dropdown.re.mjs";
import * as LoginLink from "../molecules/LoginLink.re.mjs";
import * as NavViewer from "../organisms/NavViewer.re.mjs";
import * as LangSwitch from "../molecules/LangSwitch.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as GlobalQuery from "../shared/GlobalQuery.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as StackedLayout from "../catalyst/StackedLayout.re.mjs";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";
import * as ReactRouterDom from "react-router-dom";
import * as React$1 from "@headlessui/react";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as Solid from "@heroicons/react/24/solid";
import * as DefaultLayoutMapQuery_graphql from "../../__generated__/DefaultLayoutMapQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

import '../../global/static.css'
;

var convertVariables = DefaultLayoutMapQuery_graphql.Internal.convertVariables;

var convertResponse = DefaultLayoutMapQuery_graphql.Internal.convertResponse;

var convertWrapRawResponse = DefaultLayoutMapQuery_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, DefaultLayoutMapQuery_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, DefaultLayoutMapQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(DefaultLayoutMapQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(DefaultLayoutMapQuery_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(DefaultLayoutMapQuery_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(DefaultLayoutMapQuery_graphql.node, convertVariables);

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

function DefaultLayoutMap$Content(props) {
  return JsxRuntime.jsx("div", {
              children: JsxRuntime.jsx("div", {
                    children: props.children,
                    className: "mx-auto max-w-7xl"
                  }),
              className: "grow p-0 lg:rounded-lg lg:bg-white lg:p-10 lg:shadow-sm lg:ring-1 lg:ring-zinc-950/5 dark:lg:bg-zinc-900 dark:lg:ring-white/10"
            });
}

var Content = {
  make: DefaultLayoutMap$Content
};

function ts(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

function DefaultLayoutMap$ActivityDropdownMenu(props) {
  var activities = [
    {
      label: t`All`,
      url: "/"
    },
    {
      label: t`Pickleball`,
      url: "/?activity=pickleball",
      initials: "P"
    },
    {
      label: t`Badminton`,
      url: "/?activity=badminton",
      initials: "B"
    }
  ];
  return JsxRuntime.jsx(Dropdown.DropdownMenu.make, {
              className: "min-w-80 lg:min-w-64",
              anchor: "bottom start",
              children: activities.map(function (a) {
                    return JsxRuntime.jsxs(React.Fragment, {
                                children: [
                                  JsxRuntime.jsxs(Dropdown.DropdownItem.make, {
                                        href: a.url,
                                        children: [
                                          Core__Option.getOr(Core__Option.map(a.initials, (function (initials) {
                                                      return JsxRuntime.jsx(Avatar.make, {
                                                                  className: "bg-purple-500 text-white",
                                                                  slot: "icon",
                                                                  initials: initials
                                                                });
                                                    })), null),
                                          JsxRuntime.jsx(Dropdown.DropdownLabel.make, {
                                                children: a.label
                                              })
                                        ]
                                      }),
                                  JsxRuntime.jsx(Dropdown.DropdownDivider.make, {})
                                ]
                              }, a.label);
                  })
            });
}

var ActivityDropdownMenu = {
  ts: ts,
  make: DefaultLayoutMap$ActivityDropdownMenu
};

function ts$1(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

function DefaultLayoutMap$ActivityLeagueDropdownMenu(props) {
  var activities = [
    {
      label: t`Pickleball`,
      url: "/league/pickleball",
      initials: "P"
    },
    {
      label: t`Badminton`,
      url: "/league/badminton",
      initials: "B"
    }
  ];
  return JsxRuntime.jsx(Dropdown.DropdownMenu.make, {
              className: "min-w-80 lg:min-w-64",
              anchor: "bottom start",
              children: activities.map(function (a) {
                    return JsxRuntime.jsxs(React.Fragment, {
                                children: [
                                  JsxRuntime.jsxs(Dropdown.DropdownItem.make, {
                                        href: a.url,
                                        children: [
                                          Core__Option.getOr(Core__Option.map(a.initials, (function (initials) {
                                                      return JsxRuntime.jsx(Avatar.make, {
                                                                  className: "bg-purple-500 text-white",
                                                                  slot: "icon",
                                                                  initials: initials
                                                                });
                                                    })), null),
                                          JsxRuntime.jsx(Dropdown.DropdownLabel.make, {
                                                children: a.label
                                              })
                                        ]
                                      }),
                                  JsxRuntime.jsx(Dropdown.DropdownDivider.make, {})
                                ]
                              }, a.label);
                  })
            });
}

var ActivityLeagueDropdownMenu = {
  ts: ts$1,
  make: DefaultLayoutMap$ActivityLeagueDropdownMenu
};

function DefaultLayoutMap$Layout(props) {
  var children = props.children;
  var viewer = props.viewer;
  var gviewer = Core__Option.map(viewer, (function (v) {
          return v.fragmentRefs;
        }));
  return JsxRuntime.jsx(GlobalQuery.Provider.make, {
              value: gviewer,
              children: JsxRuntime.jsx(WaitForMessages.make, {
                    children: (function () {
                        return JsxRuntime.jsx(StackedLayout.make, {
                                    navbar: Caml_option.some(JsxRuntime.jsxs(Navbar.make, {
                                              children: [
                                                JsxRuntime.jsx(Navbar.NavbarItem.make, {
                                                      className: "max-lg:hidden",
                                                      href: "/",
                                                      children: JsxRuntime.jsx(Navbar.NavbarLabel.make, {
                                                            children: t`Racquet League`
                                                          })
                                                    }),
                                                JsxRuntime.jsx(Navbar.NavbarDivider.make, {
                                                      className: "max-lg:hidden"
                                                    }),
                                                JsxRuntime.jsxs(Navbar.NavbarSection.make, {
                                                      className: "max-lg:hidden",
                                                      children: [
                                                        JsxRuntime.jsxs(React$1.Menu, {
                                                              children: [
                                                                JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                                                      className: "max-lg:hidden",
                                                                      as: Navbar.NavbarItem.make,
                                                                      children: [
                                                                        JsxRuntime.jsx(Navbar.NavbarLabel.make, {
                                                                              children: t`Events`
                                                                            }),
                                                                        JsxRuntime.jsx(Solid.ChevronDownIcon, {})
                                                                      ]
                                                                    }),
                                                                JsxRuntime.jsx(DefaultLayoutMap$ActivityDropdownMenu, {})
                                                              ]
                                                            }),
                                                        JsxRuntime.jsxs(React$1.Menu, {
                                                              children: [
                                                                JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                                                      className: "max-lg:hidden",
                                                                      as: Navbar.NavbarItem.make,
                                                                      children: [
                                                                        JsxRuntime.jsx(Navbar.NavbarLabel.make, {
                                                                              children: t`Rankings`
                                                                            }),
                                                                        JsxRuntime.jsx(Solid.ChevronDownIcon, {})
                                                                      ]
                                                                    }),
                                                                JsxRuntime.jsx(DefaultLayoutMap$ActivityLeagueDropdownMenu, {})
                                                              ]
                                                            })
                                                      ]
                                                    }),
                                                JsxRuntime.jsx(Navbar.NavbarSpacer.make, {}),
                                                JsxRuntime.jsx(Navbar.NavbarSection.make, {
                                                      className: "max-lg:hidden",
                                                      children: JsxRuntime.jsx(LangSwitch.make, {})
                                                    }),
                                                JsxRuntime.jsx(Navbar.NavbarSpacer.make, {}),
                                                JsxRuntime.jsx(Navbar.NavbarSection.make, {
                                                      children: Core__Option.getOr(Core__Option.map(viewer, (function (viewer) {
                                                                  return JsxRuntime.jsx(React.Suspense, {
                                                                              children: Caml_option.some(JsxRuntime.jsx(NavViewer.make, {
                                                                                        viewer: viewer.fragmentRefs
                                                                                      })),
                                                                              fallback: Caml_option.some(JsxRuntime.jsx(LoginLink.make, {}))
                                                                            });
                                                                })), JsxRuntime.jsx(LoginLink.make, {}))
                                                    })
                                              ]
                                            })),
                                    sidebar: Caml_option.some(JsxRuntime.jsxs(Sidebar.Sidebar.make, {
                                              children: [
                                                JsxRuntime.jsx(Sidebar.SidebarHeader.make, {
                                                      children: JsxRuntime.jsx(Sidebar.SidebarItem.make, {
                                                            href: "/",
                                                            children: JsxRuntime.jsx(Sidebar.SidebarLabel.make, {
                                                                  children: t`Racquet League`
                                                                })
                                                          })
                                                    }),
                                                JsxRuntime.jsx(Sidebar.SidebarBody.make, {
                                                      children: JsxRuntime.jsxs(Sidebar.SidebarSection.make, {
                                                            children: [
                                                              JsxRuntime.jsxs(React$1.Menu, {
                                                                    children: [
                                                                      JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                                                            className: "lg:mb-2.5",
                                                                            as: Sidebar.SidebarItem.make,
                                                                            children: [
                                                                              JsxRuntime.jsx(Sidebar.SidebarLabel.make, {
                                                                                    children: t`Events`
                                                                                  }),
                                                                              JsxRuntime.jsx(Solid.ChevronDownIcon, {})
                                                                            ]
                                                                          }),
                                                                      JsxRuntime.jsx(DefaultLayoutMap$ActivityDropdownMenu, {})
                                                                    ]
                                                                  }),
                                                              JsxRuntime.jsxs(React$1.Menu, {
                                                                    children: [
                                                                      JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                                                            className: "lg:mb-2.5",
                                                                            as: Sidebar.SidebarItem.make,
                                                                            children: [
                                                                              JsxRuntime.jsx(Sidebar.SidebarLabel.make, {
                                                                                    children: t`Rankings`
                                                                                  }),
                                                                              JsxRuntime.jsx(Solid.ChevronDownIcon, {})
                                                                            ]
                                                                          }),
                                                                      JsxRuntime.jsx(DefaultLayoutMap$ActivityLeagueDropdownMenu, {})
                                                                    ]
                                                                  }),
                                                              JsxRuntime.jsx("div", {
                                                                    children: JsxRuntime.jsx(LangSwitch.make, {}),
                                                                    className: "ml-2 mt-2"
                                                                  })
                                                            ]
                                                          })
                                                    })
                                              ]
                                            })),
                                    children: children
                                  });
                      })
                  })
            });
}

var Layout = {
  make: DefaultLayoutMap$Layout
};

function DefaultLayoutMap(props) {
  var query = ReactRouterDom.useLoaderData();
  var match = usePreloaded(query.data);
  return JsxRuntime.jsx(DefaultLayoutMap$Layout, {
              viewer: match.viewer,
              children: JsxRuntime.jsx(ReactRouterDom.Outlet, {})
            });
}

var make = DefaultLayoutMap;

export {
  Query ,
  Content ,
  ActivityDropdownMenu ,
  ActivityLeagueDropdownMenu ,
  Layout ,
  make ,
}
/*  Not a pure module */
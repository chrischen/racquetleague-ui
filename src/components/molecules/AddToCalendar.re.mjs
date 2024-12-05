// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Avatar from "../catalyst/Avatar.re.mjs";
import * as Navbar from "../catalyst/Navbar.re.mjs";
import * as Dropdown from "../catalyst/Dropdown.re.mjs";
import * as GlobalQuery from "../shared/GlobalQuery.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as LucideReact from "lucide-react";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";
import * as React$1 from "@headlessui/react";
import * as JsxRuntime from "react/jsx-runtime";

import { t } from '@lingui/macro'
;

function ts(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

function AddToCalendar$ProvidersMenu(props) {
  var userId = props.userId;
  var activities = [
    {
      label: t`Apple iCal`,
      url: "webcal://www.pkuru.com/cal-feed/" + userId,
      initials: "I"
    },
    {
      label: t`Google Calendar`,
      url: "https://calendar.google.com/calendar/u/0/r?cid=" + encodeURIComponent("webcal://www.pkuru.com/cal-feed/" + userId),
      initials: "G"
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

var ProvidersMenu = {
  ts: ts,
  make: AddToCalendar$ProvidersMenu
};

function AddToCalendar(props) {
  var viewer = GlobalQuery.useViewer();
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  return Core__Option.getOr(Core__Option.map(viewer.user, (function (user) {
                                    return JsxRuntime.jsx("div", {
                                                children: JsxRuntime.jsxs(React$1.Menu, {
                                                      children: [
                                                        JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                                              as: Navbar.NavbarItem.make,
                                                              children: [
                                                                JsxRuntime.jsx(LucideReact.CalendarPlus, {
                                                                      className: "mr-1.5 h-5 w-5 flex-shrink-0 text-gray-500",
                                                                      "aria-hidden": "true"
                                                                    }),
                                                                t`sync calendar`
                                                              ]
                                                            }),
                                                        JsxRuntime.jsx(AddToCalendar$ProvidersMenu, {
                                                              userId: user.id
                                                            })
                                                      ]
                                                    }),
                                                className: "flex items-center lg:text-sm"
                                              });
                                  })), null);
                })
            });
}

var make = AddToCalendar;

export {
  ProvidersMenu ,
  make ,
}
/*  Not a pure module */

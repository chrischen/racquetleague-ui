// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Util from "../shared/Util.re.mjs";
import * as React from "react";
import * as ReactIntl from "react-intl";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as LangProvider from "../shared/LangProvider.re.mjs";
import * as ReactCalendar from "react-calendar";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as CalendarEventsFragment_graphql from "../../__generated__/CalendarEventsFragment_graphql.re.mjs";
import * as CalendarEventsRefetchQuery_graphql from "../../__generated__/CalendarEventsRefetchQuery_graphql.re.mjs";

import { t } from '@lingui/macro'
;

import './Calendar.css'
;

var getConnectionNodes = CalendarEventsFragment_graphql.Utils.getConnectionNodes;

var convertFragment = CalendarEventsFragment_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(CalendarEventsFragment_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, CalendarEventsFragment_graphql.node, convertFragment);
}

var makeRefetchVariables = CalendarEventsRefetchQuery_graphql.Types.makeRefetchVariables;

var convertRefetchVariables = CalendarEventsRefetchQuery_graphql.Internal.convertVariables;

function useRefetchable(fRef) {
  return RescriptRelay_Fragment.useRefetchableFragment(CalendarEventsFragment_graphql.node, convertFragment, convertRefetchVariables, fRef);
}

function usePagination(fRef) {
  return RescriptRelay_Fragment.usePaginationFragment(CalendarEventsFragment_graphql.node, fRef, convertFragment, convertRefetchVariables);
}

function useBlockingPagination(fRef) {
  return RescriptRelay_Fragment.useBlockingPaginationFragment(CalendarEventsFragment_graphql.node, fRef, convertFragment, convertRefetchVariables);
}

var Fragment = {
  getConnectionNodes: getConnectionNodes,
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment,
  use: use,
  useOpt: useOpt,
  makeRefetchVariables: makeRefetchVariables,
  convertRefetchVariables: convertRefetchVariables,
  useRefetchable: useRefetchable,
  usePagination: usePagination,
  useBlockingPagination: useBlockingPagination
};

function isSameDay(date1, date2) {
  if (date1.getDate() === date2.getDate() && date1.getMonth() === date2.getMonth()) {
    return date1.getFullYear() === date2.getFullYear();
  } else {
    return false;
  }
}

function intlIsSameDay(intl, date1, date2) {
  var date1String = intl.formatDate(date1, {
        weekday: "long",
        month: "short",
        day: "numeric"
      });
  var date2String = intl.formatDate(date2, {
        weekday: "long",
        month: "short",
        day: "numeric"
      });
  return date1String === date2String;
}

function inDates(dates, intl, date) {
  return dates.findIndex(function (d) {
              return intlIsSameDay(intl, d, date);
            }) !== -1;
}

function Calendar(props) {
  var events = props.events;
  use(events);
  var match = usePagination(events);
  var events$1 = getConnectionNodes(match.data.events);
  var match$1 = ReactRouterDom.useSearchParams();
  var setSearchParams = match$1[1];
  var locale = React.useContext(LangProvider.LocaleContext.context);
  var intl = ReactIntl.useIntl();
  var dates = Core__Array.reduce(events$1, [], (function (acc, $$event) {
          var date = $$event.startDate;
          if (date !== undefined) {
            return acc.concat([Util.Datetime.toDate(Caml_option.valFromOption(date))]);
          } else {
            return acc;
          }
        }));
  return JsxRuntime.jsx(ReactCalendar.Calendar, {
              value: new Date(),
              locale: locale.lang,
              className: "w-full",
              onClickDay: (function (date, param) {
                  setSearchParams(function (prevParams) {
                        prevParams.set("selectedDate", date.toISOString());
                        return prevParams;
                      });
                }),
              tileContent: (function (param) {
                  if (param.view === "month") {
                    if (inDates(dates, intl, param.date)) {
                      return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                  children: [
                                    JsxRuntime.jsx("br", {}),
                                    "•"
                                  ]
                                });
                    } else {
                      return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                  children: [
                                    JsxRuntime.jsx("br", {}),
                                    JsxRuntime.jsx("br", {})
                                  ]
                                });
                    }
                  } else {
                    return null;
                  }
                }),
              tileClassName: (function (param) {
                  var date = intl.formatDate(param.date, {
                        weekday: "long",
                        month: "short",
                        day: "numeric"
                      });
                  var today = intl.formatDate(new Date(), {
                        weekday: "long",
                        month: "short",
                        day: "numeric"
                      });
                  if (param.view === "month" && date === today) {
                    return "bg-blue-200 text-black";
                  }
                  
                })
            });
}

var make = Calendar;

export {
  Fragment ,
  isSameDay ,
  intlIsSameDay ,
  inDates ,
  make ,
}
/*  Not a pure module */

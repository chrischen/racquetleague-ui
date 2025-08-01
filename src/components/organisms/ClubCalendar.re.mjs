// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as ReactIntl from "react-intl";
import * as LangProvider from "../shared/LangProvider.re.mjs";
import * as ReactCalendar from "react-calendar";
import * as JsxRuntime from "react/jsx-runtime";

import { t } from '@lingui/macro'
;

import './Calendar.css'
;

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

function ClubCalendar(props) {
  var onDateSelected = props.onDateSelected;
  var dates = props.dates;
  var locale = React.useContext(LangProvider.LocaleContext.context);
  var intl = ReactIntl.useIntl();
  return JsxRuntime.jsx(ReactCalendar.Calendar, {
              value: new Date(),
              locale: locale.lang,
              className: "w-full",
              calendarType: "gregory",
              onClickDay: (function (date, param) {
                  onDateSelected(date);
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

var make = ClubCalendar;

export {
  intlIsSameDay ,
  inDates ,
  make ,
}
/*  Not a pure module */

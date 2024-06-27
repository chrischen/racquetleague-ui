// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Layout from "../shared/Layout.re.mjs";
import * as PageTitle from "../vanillaui/atoms/PageTitle.re.mjs";
import PrizeJpg from "./prize.jpg";
import JplLogoPng from "./jpl-logo.png";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var jplLogo = JplLogoPng;

function LeaguePage(props) {
  ReactRouterDom.useLoaderData();
  var params = ReactRouterDom.useParams();
  JsxRuntime.jsx("a", {
        children: "Racquet League.",
        href: "https://www.racquetleague.com"
      });
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  var match = params.activitySlug;
                  var tmp;
                  var exit = 0;
                  if (match !== undefined) {
                    switch (match) {
                      case "" :
                      case "pickleball" :
                          exit = 1;
                          break;
                      default:
                        tmp = t`Tokyo Badminton League`;
                    }
                  } else {
                    exit = 1;
                  }
                  if (exit === 1) {
                    tmp = JsxRuntime.jsx("img", {
                          className: "mx-auto",
                          alt: t`japan pickle league`,
                          src: jplLogo
                        });
                  }
                  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                              children: [
                                JsxRuntime.jsx("header", {
                                      children: JsxRuntime.jsx("div", {
                                            children: JsxRuntime.jsx(Layout.Container.make, {
                                                  children: JsxRuntime.jsx(PageTitle.make, {
                                                        children: tmp
                                                      })
                                                }),
                                            className: "py-10"
                                          })
                                    }),
                                JsxRuntime.jsx("main", {
                                      children: JsxRuntime.jsx(ReactRouterDom.Outlet, {})
                                    })
                              ]
                            });
                })
            });
}

var make = LeaguePage;

export {
  make ,
}
/*  Not a pure module */

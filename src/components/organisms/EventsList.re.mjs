// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Util from "../shared/Util.re.mjs";
import * as React from "react";
import * as Layout from "../shared/Layout.re.mjs";
import * as PinMap from "./PinMap.re.mjs";
import * as Router from "../shared/Router.re.mjs";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Calendar from "./Calendar.re.mjs";
import * as Caml_obj from "rescript/lib/es6/caml_obj.js";
import * as UiAction from "../atoms/UiAction.re.mjs";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as ReactIntl from "react-intl";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as Core from "@lingui/core";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as LangProvider from "../shared/LangProvider.re.mjs";
import * as WarningAlert from "../molecules/WarningAlert.re.mjs";
import * as Core$1 from "@linaria/core";
import * as React$1 from "@lingui/react";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";
import * as ReactRouterDom from "react-router-dom";
import * as ReactExperimental from "rescript-relay/src/ReactExperimental.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as EventsList_event_graphql from "../../__generated__/EventsList_event_graphql.re.mjs";
import * as Solid from "@heroicons/react/24/solid";
import * as EventsListFragment_graphql from "../../__generated__/EventsListFragment_graphql.re.mjs";
import * as Outline from "@heroicons/react/24/outline";
import * as EventsListText_event_graphql from "../../__generated__/EventsListText_event_graphql.re.mjs";
import * as DifferenceInMinutes from "date-fns/differenceInMinutes";
import * as EventsListRefetchQuery_graphql from "../../__generated__/EventsListRefetchQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

var getConnectionNodes = EventsListFragment_graphql.Utils.getConnectionNodes;

var convertFragment = EventsListFragment_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(EventsListFragment_graphql.node, convertFragment, fRef);
}

var convertRefetchVariables = EventsListRefetchQuery_graphql.Internal.convertVariables;

function usePagination(fRef) {
  return RescriptRelay_Fragment.usePaginationFragment(EventsListFragment_graphql.node, fRef, convertFragment, convertRefetchVariables);
}

var convertFragment$1 = EventsList_event_graphql.Internal.convertFragment;

function use$1(fRef) {
  return RescriptRelay_Fragment.useFragment(EventsList_event_graphql.node, convertFragment$1, fRef);
}

var convertFragment$2 = EventsListText_event_graphql.Internal.convertFragment;

function use$2(fRef) {
  return RescriptRelay_Fragment.useFragment(EventsListText_event_graphql.node, convertFragment$2, fRef);
}

function td(prim) {
  return Core.i18n._(prim);
}

function ts(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

function make($$event) {
  var match = use$2($$event);
  var startDate = match.startDate;
  var maxRsvps = match.maxRsvps;
  var $$location = match.location;
  var endDate = match.endDate;
  var match$1 = React$1.useLingui();
  var intl = ReactIntl.useIntl();
  var playersCount = Core__Option.getOr(Core__Option.flatMap(match.rsvps, (function (rsvps) {
              return Core__Option.map(rsvps.edges, (function (edges) {
                            return edges.filter(function (edge) {
                                        return Core__Option.getOr(Core__Option.flatMap(edge, (function (edge) {
                                                          return Core__Option.map(edge.node, (function (node) {
                                                                        if (Caml_obj.equal(node.listType, 0)) {
                                                                          return true;
                                                                        } else {
                                                                          return node.listType === undefined;
                                                                        }
                                                                      }));
                                                        })), true);
                                      }).length;
                          }));
            })), 0);
  var spaceAvailable = maxRsvps !== undefined && (maxRsvps - playersCount | 0) <= 0 ? "🈵" : "🈳";
  var duration = Core__Option.flatMap(startDate, (function (startDate) {
          return Core__Option.map(endDate, (function (endDate) {
                        return DifferenceInMinutes.differenceInMinutes(Util.Datetime.toDate(endDate), Util.Datetime.toDate(startDate));
                      }));
        }));
  var duration$1 = Core__Option.map(duration, (function (duration) {
          var hours = Math.floor(duration / 60);
          var minutes = (duration | 0) % 60;
          if (minutes === 0) {
            return plural(hours | 0, {
                        one: t`${hours.toString()} hour`,
                        other: t`${hours.toString()} hours`
                      });
          } else {
            return plural(hours | 0, {
                        one: t`${hours.toString()} hour`,
                        other: t`${hours.toString()} hours`
                      }) + " " + plural(minutes, {
                        one: t`${minutes.toString()} minute`,
                        other: t`${minutes.toString()} minutes`
                      });
          }
        }));
  var canceled = Core__Option.isSome(match.deleted) ? " " + t`🚫 CANCELED` : "";
  return "🗓 " + Core__Option.getOr(Core__Option.map(startDate, (function (startDate) {
                    var startDate$1 = Util.Datetime.toDate(startDate);
                    return intl.formatDate(startDate$1, {
                                weekday: "short",
                                month: "numeric",
                                day: "numeric"
                              }) + " " + intl.formatTime(startDate$1);
                  })), "") + "->" + Core__Option.getOr(Core__Option.map(endDate, (function (endDate) {
                    return intl.formatTime(Util.Datetime.toDate(endDate));
                  })), "") + Core__Option.getOr(Core__Option.map(duration$1, (function (duration) {
                    return " (" + duration + ") ";
                  })), "") + spaceAvailable + canceled + "\n📍 " + Core__Option.getOr(Core__Option.flatMap($$location, (function (l) {
                    return Core__Option.map(l.name, (function (name) {
                                  return name;
                                }));
                  })), t`[location missing]`) + Core__Option.getOr(Core__Option.flatMap($$location, (function (l) {
                    return Core__Option.flatMap(l.links, (function (l) {
                                  return Core__Option.map(l[0], (function (mapLink) {
                                                return "\n🧭 " + encodeURI(mapLink);
                                              }));
                                }));
                  })), "") + "\n👉 https://www.pkuru.com/" + match$1.i18n.locale + "/events/" + match.id + "\n-----------------------------";
}

var TextEventItem = {
  td: td,
  ts: ts,
  make: make
};

function toLocalTime(date) {
  return new Date(date.getTime() - date.getTimezoneOffset() * 60 * 1000);
}

function EventsList$TextEventsList(props) {
  ReactExperimental.useTransition();
  var match = usePagination(props.events);
  var events = getConnectionNodes(match.data.events);
  var str = events.map(function (edge) {
          return make(edge.fragmentRefs);
        }).join("\n");
  return JsxRuntime.jsx("textarea", {
              className: "w-full",
              readOnly: true,
              rows: 10,
              value: str
            });
}

var TextEventsList = {
  toLocalTime: toLocalTime,
  make: EventsList$TextEventsList
};

function td$1(prim) {
  return Core.i18n._(prim);
}

function ts$1(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

function EventsList$EventItem(props) {
  var __highlightedLocation = props.highlightedLocation;
  var highlightedLocation = __highlightedLocation !== undefined ? __highlightedLocation : false;
  var match = use$1(props.event);
  var viewerRsvpStatus = match.viewerRsvpStatus;
  var startDate = match.startDate;
  var shadow = match.shadow;
  var endDate = match.endDate;
  var playersCount = Core__Option.getOr(Core__Option.flatMap(match.rsvps, (function (rsvps) {
              return Core__Option.map(rsvps.edges, (function (edges) {
                            return edges.filter(function (edge) {
                                        return Core__Option.getOr(Core__Option.flatMap(edge, (function (edge) {
                                                          return Core__Option.map(edge.node, (function (node) {
                                                                        if (Caml_obj.equal(node.listType, 0)) {
                                                                          return true;
                                                                        } else {
                                                                          return node.listType === undefined;
                                                                        }
                                                                      }));
                                                        })), true);
                                      }).length;
                          }));
            })), 0);
  var duration = Core__Option.flatMap(startDate, (function (startDate) {
          return Core__Option.map(endDate, (function (endDate) {
                        return DifferenceInMinutes.differenceInMinutes(Util.Datetime.toDate(endDate), Util.Datetime.toDate(startDate));
                      }));
        }));
  var duration$1 = Core__Option.map(duration, (function (duration) {
          var hours = Math.floor(duration / 60);
          var minutes = (duration | 0) % 60;
          if (minutes === 0) {
            return plural(hours | 0, {
                        one: t`${hours.toString()} hour`,
                        other: t`${hours.toString()} hours`
                      });
          } else {
            return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                        children: [
                          plural(hours | 0, {
                                one: t`${hours.toString()} hour`,
                                other: t`${hours.toString()} hours`
                              }),
                          " ",
                          plural(minutes, {
                                one: t`${minutes.toString()} minute`,
                                other: t`${minutes.toString()} minutes`
                              })
                        ]
                      });
          }
        }));
  var tmp;
  tmp = viewerRsvpStatus !== undefined && (viewerRsvpStatus === "Joined" || viewerRsvpStatus === "Waitlist") ? (
      viewerRsvpStatus === "Joined" ? JsxRuntime.jsx("div", {
              children: t`joined`,
              className: Core$1.cx("text-green-600 bg-green-400/10 ring-green-400/30", "rounded-full flex-none py-1 px-2 text-xs font-medium ring-1 ring-inset")
            }) : JsxRuntime.jsx("div", {
              children: t`waitlist`,
              className: Core$1.cx("text-yellow-600 bg-yellow-400/10 ring-yellow-400/30", "rounded-full flex-none py-1 px-2 text-xs font-medium ring-1 ring-inset")
            })
    ) : null;
  var tmp$1;
  var exit = 0;
  if (shadow !== undefined && shadow) {
    tmp$1 = JsxRuntime.jsx(Solid.LockClosedIcon, {
          className: "-ml-0.5 h-3 w-3",
          "aria-hidden": "true"
        });
  } else {
    exit = 1;
  }
  if (exit === 1) {
    tmp$1 = Core__Option.getOr(Core__Option.map(match.maxRsvps, (function (maxRsvps) {
                return playersCount.toString() + "/" + maxRsvps.toString() + " " + t`players`;
              })), JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                playersCount.toString() + " ",
                plural(playersCount, {
                      one: "player",
                      other: "players"
                    })
              ]
            }));
  }
  return JsxRuntime.jsxs(Layout.Container.make, {
              children: [
                JsxRuntime.jsxs("div", {
                      children: [
                        JsxRuntime.jsxs("div", {
                              children: [
                                JsxRuntime.jsx("div", {
                                      children: JsxRuntime.jsx("div", {
                                            className: "h-2 w-2 rounded-full bg-current"
                                          }),
                                      className: Core$1.cx("text-green-400 bg-green-400/10", "flex-none rounded-full p-1")
                                    }),
                                JsxRuntime.jsx("h2", {
                                      children: JsxRuntime.jsx(LangProvider.Router.Link.make, {
                                            to: "/events/" + match.id,
                                            children: JsxRuntime.jsxs("div", {
                                                  children: [
                                                    JsxRuntime.jsxs("span", {
                                                          children: [
                                                            Core__Option.getOr(Core__Option.flatMap(match.activity, (function (a) {
                                                                        return Core__Option.map(a.name, (function (name) {
                                                                                      return Core.i18n._(name);
                                                                                    }));
                                                                      })), null),
                                                            " / ",
                                                            Core__Option.getOr(match.title, t`[missing title]`)
                                                          ],
                                                          className: Core$1.cx("truncate", Core__Option.isSome(match.deleted) ? "line-through" : "")
                                                        }),
                                                    JsxRuntime.jsx("span", {
                                                          className: "absolute inset-0"
                                                        })
                                                  ],
                                                  className: "flex gap-x-2"
                                                }),
                                            className: "",
                                            relative: "path"
                                          }),
                                      className: "min-w-0 text-sm font-semibold leading-6 text-black w-full"
                                    })
                              ],
                              className: "flex items-center gap-x-3"
                            }),
                        JsxRuntime.jsx("div", {
                              children: JsxRuntime.jsxs("p", {
                                    children: [
                                      Core__Option.getOr(Core__Option.map(startDate, (function (startDate) {
                                                  return JsxRuntime.jsx(ReactIntl.FormattedTime, {
                                                              value: Util.Datetime.toDate(startDate)
                                                            });
                                                })), null),
                                      " -> ",
                                      Core__Option.getOr(Core__Option.map(endDate, (function (endDate) {
                                                  return JsxRuntime.jsx(ReactIntl.FormattedTime, {
                                                              value: Util.Datetime.toDate(endDate)
                                                            });
                                                })), null),
                                      Core__Option.getOr(Core__Option.map(duration$1, (function (duration) {
                                                  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                                              children: [
                                                                " (",
                                                                duration,
                                                                ") "
                                                              ]
                                                            });
                                                })), null)
                                    ],
                                    className: "whitespace-nowrap"
                                  }),
                              className: "mt-3 flex items-center gap-x-2.5 text-xs leading-5 text-gray-600"
                            }),
                        JsxRuntime.jsx("div", {
                              children: JsxRuntime.jsx("span", {
                                    children: JsxRuntime.jsx("p", {
                                          children: Core__Option.getOr(Core__Option.flatMap(match.location, (function (l) {
                                                      return Core__Option.map(l.name, (function (name) {
                                                                    return name;
                                                                  }));
                                                    })), t`[location missing]`),
                                          className: Core$1.cx("truncate", highlightedLocation ? "font-bold" : "")
                                        }),
                                    className: "whitespace-nowrap"
                                  }),
                              className: "mt-3 flex items-center gap-x-2.5 text-xs leading-5 text-gray-600"
                            })
                      ],
                      className: "min-w-0 flex-auto"
                    }),
                tmp,
                JsxRuntime.jsx("div", {
                      children: tmp$1,
                      className: Core$1.cx("text-indigo-400 bg-indigo-400/10 ring-indigo-400/30", "rounded-full flex-none py-1 px-2 text-xs font-medium ring-1 ring-inset")
                    })
              ],
              className: "relative flex items-center space-x-4 py-4"
            });
}

var EventItem = {
  td: td$1,
  ts: ts$1,
  make: EventsList$EventItem
};

function updateParams(filter, params) {
  switch (filter.TAG) {
    case "ByDate" :
        return params.set("selectedDate", filter._0.toISOString());
    case "ByAfter" :
        return params.set("after", filter._0).delete("before");
    case "ByBefore" :
        return params.set("before", filter._0).delete("after");
    case "ByAfterDate" :
        return params.set("afterDate", filter._0.toISOString());
    
  }
}

function EventsList$Day(props) {
  var highlightedLocation = props.highlightedLocation;
  var events = props.events;
  var match = React.useState(function () {
        return false;
      });
  var setShowShadow = match[1];
  var showShadow = match[0];
  var shadowCount = events.filter(function (edge) {
        return Core__Option.getOr(edge.shadow, false);
      }).length;
  var shadowCountDesc = plural(shadowCount, {
        one: "event",
        other: "events"
      });
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                events.map(function (edge) {
                      var highlighted = Core__Option.getOr(Core__Option.map(edge.location, (function ($$location) {
                                  return highlightedLocation === $$location.id;
                                })), false);
                      var highlightedClass = highlighted ? "bg-yellow-100/35" : "";
                      if (Core__Option.getOr(edge.shadow, false) && !showShadow) {
                        return null;
                      } else {
                        return JsxRuntime.jsx("li", {
                                    children: JsxRuntime.jsx(EventsList$EventItem, {
                                          event: edge.fragmentRefs
                                        }, edge.id),
                                    className: highlightedClass,
                                    id: highlighted ? "highlighted" : ""
                                  }, edge.id);
                      }
                    }),
                shadowCount > 0 && !showShadow ? JsxRuntime.jsx("li", {
                        children: JsxRuntime.jsxs("p", {
                              children: [
                                t`${shadowCount.toString()} private ${shadowCountDesc} hidden`,
                                " ",
                                JsxRuntime.jsx(UiAction.make, {
                                      onClick: (function (param) {
                                          setShowShadow(function (param) {
                                                return true;
                                              });
                                        }),
                                      children: t`show`
                                    })
                              ],
                              className: "text-gray-700 p-3 italic ml-6"
                            })
                      }) : null
              ]
            });
}

function EventsList(props) {
  var events = props.events;
  ReactExperimental.useTransition();
  var match = use(events);
  var match$1 = usePagination(events);
  var data = match$1.data;
  var events$1 = getConnectionNodes(data.events);
  var pageInfo = data.events.pageInfo;
  var hasPrevious = pageInfo.hasPreviousPage;
  var match$2 = React.useState(function () {
        return false;
      });
  var setShareOpen = match$2[1];
  var shareOpen = match$2[0];
  var match$3 = React.useState(function () {
        
      });
  var navigate = ReactRouterDom.useNavigate();
  var match$4 = ReactRouterDom.useSearchParams();
  var setSearchParams = match$4[1];
  var searchParams = Router.ImmSearchParams.fromSearchParams(match$4[0]);
  var filterByDate = Core__Option.map(Router.ImmSearchParams.get(searchParams, "selectedDate"), (function (date) {
          return new Date(date);
        }));
  var clearFilterByDate = function () {
    setSearchParams(function (prevParams) {
          prevParams.delete("selectedDate");
          return prevParams;
        });
  };
  var intl = ReactIntl.useIntl();
  var eventsByDate = Core__Array.reduce(events$1, {}, (function (extra, extra$1) {
          Core__Option.map(extra$1.startDate, (function (startDate) {
                  var startDate$1 = Util.Datetime.toDate(startDate);
                  var startDateString = intl.formatDate(startDate$1, {
                        weekday: "long",
                        month: "short",
                        day: "numeric"
                      });
                  Core__Option.map(filterByDate, (function (filterDate) {
                          if (startDate$1.getTime() <= filterDate.getTime()) {
                            return ;
                          }
                          var events = Js_dict.get(extra, startDateString);
                          if (events !== undefined) {
                            extra[startDateString] = Belt_Array.concatMany([
                                  [extra$1],
                                  events
                                ]);
                          } else {
                            extra[startDateString] = [extra$1];
                          }
                        }));
                  if (filterByDate !== undefined) {
                    return ;
                  }
                  var events = Js_dict.get(extra, startDateString);
                  if (events !== undefined) {
                    extra[startDateString] = Belt_Array.concatMany([
                          [extra$1],
                          events
                        ]);
                  } else {
                    extra[startDateString] = [extra$1];
                  }
                }));
          return extra;
        }));
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsxs("div", {
                      children: [
                        JsxRuntime.jsx(LangProvider.DetectedLang.make, {}),
                        JsxRuntime.jsxs("div", {
                              children: [
                                props.header,
                                JsxRuntime.jsxs(Layout.Container.make, {
                                      children: [
                                        JsxRuntime.jsx(UiAction.make, {
                                              onClick: (function (param) {
                                                  setShareOpen(function (v) {
                                                        return !v;
                                                      });
                                                }),
                                              active: shareOpen,
                                              alt: t`share as text`,
                                              children: JsxRuntime.jsx(Outline.DocumentTextIcon, {
                                                    className: "inline w-6 h-6"
                                                  })
                                            }),
                                        shareOpen ? JsxRuntime.jsx(EventsList$TextEventsList, {
                                                events: events
                                              }) : null
                                      ],
                                      className: "p-2 flex-row flex gap-2"
                                    }),
                                JsxRuntime.jsx("div", {
                                      children: JsxRuntime.jsxs("div", {
                                            children: [
                                              JsxRuntime.jsx(Calendar.make, {
                                                    events: events,
                                                    onDateSelected: (function (date) {
                                                        setSearchParams(function (prevParams) {
                                                              return Router.ImmSearchParams.toSearchParams(updateParams({
                                                                              TAG: "ByDate",
                                                                              _0: date
                                                                            }, Router.ImmSearchParams.fromSearchParams(prevParams)));
                                                            });
                                                      })
                                                  }),
                                              Core__Option.getOr(Core__Option.map(filterByDate, (function (param) {
                                                          return JsxRuntime.jsx(WarningAlert.make, {
                                                                      children: JsxRuntime.jsx(JsxRuntime.Fragment, {
                                                                            children: Caml_option.some(t`filtering by date`)
                                                                          }),
                                                                      cta: Caml_option.some(t`clear filter`),
                                                                      ctaClick: (function () {
                                                                          clearFilterByDate();
                                                                        })
                                                                    });
                                                        })), null),
                                              !match$1.isLoadingPrevious && hasPrevious ? Core__Option.getOr(Core__Option.map(pageInfo.startCursor, (function (startCursor) {
                                                            return JsxRuntime.jsx(LangProvider.Router.LinkWithOpts.make, {
                                                                        to: {
                                                                          pathname: "./",
                                                                          search: updateParams({
                                                                                  TAG: "ByBefore",
                                                                                  _0: startCursor
                                                                                }, searchParams).toString()
                                                                        },
                                                                        children: JsxRuntime.jsx(Solid.ChevronUpIcon, {
                                                                              className: "inline w-7 h-7"
                                                                            }),
                                                                        className: "hover:bg-gray-100 p-3 w-full text-center block"
                                                                      });
                                                          })), JsxRuntime.jsx(LangProvider.Router.LinkWithOpts.make, {
                                                          to: {
                                                            pathname: "./",
                                                            search: updateParams({
                                                                    TAG: "ByAfterDate",
                                                                    _0: new Date("2020-01-01")
                                                                  }, searchParams).toString()
                                                          },
                                                          children: t`...load past events`
                                                        })) : null,
                                              JsxRuntime.jsx("ul", {
                                                    children: Js_dict.entries(eventsByDate).map(function (param) {
                                                          var dateString = param[0];
                                                          return JsxRuntime.jsxs("li", {
                                                                      children: [
                                                                        JsxRuntime.jsx("div", {
                                                                              children: JsxRuntime.jsx(Layout.Container.make, {
                                                                                    children: JsxRuntime.jsx("h3", {
                                                                                          children: dateString
                                                                                        })
                                                                                  }),
                                                                              className: "sticky top-0 z-10 border-y border-b-gray-200 border-t-gray-100 bg-gray-50 px-0 py-1.5 text-sm font-semibold leading-6 text-gray-900"
                                                                            }),
                                                                        JsxRuntime.jsx("ul", {
                                                                              children: JsxRuntime.jsx(EventsList$Day, {
                                                                                    events: param[1],
                                                                                    highlightedLocation: ""
                                                                                  }),
                                                                              className: "divide-y divide-gray-200",
                                                                              role: "list"
                                                                            })
                                                                      ]
                                                                    }, dateString);
                                                        }),
                                                    className: "",
                                                    role: "list"
                                                  }),
                                              match$1.hasNext && !match$1.isLoadingNext ? JsxRuntime.jsx(Layout.Container.make, {
                                                      children: Core__Option.getOr(Core__Option.map(pageInfo.endCursor, (function (endCursor) {
                                                                  return JsxRuntime.jsx(LangProvider.Router.LinkWithOpts.make, {
                                                                              to: {
                                                                                pathname: "./",
                                                                                search: updateParams({
                                                                                        TAG: "ByAfter",
                                                                                        _0: endCursor
                                                                                      }, searchParams).toString()
                                                                              },
                                                                              children: JsxRuntime.jsx(Solid.ChevronDownIcon, {
                                                                                    className: "inline w-7 h-7"
                                                                                  }),
                                                                              className: "hover:bg-gray-100 p-3 w-full text-center block"
                                                                            });
                                                                })), null)
                                                    }) : null
                                            ],
                                            className: "w-full lg:overflow-x-hidden"
                                          }),
                                      className: "mx-auto w-full grow lg:flex"
                                    })
                              ],
                              className: "mx-auto max-w-7xl"
                            })
                      ],
                      className: "grow p-0 z-10 lg:w-1/2 lg:h-[calc(100vh-50px)] lg:overflow-scroll lg:rounded-lg lg:bg-white lg:p-10 lg:shadow-sm lg:ring-1 lg:ring-zinc-950/5 dark:lg:bg-zinc-900 dark:lg:ring-white/10"
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsx("div", {
                                  children: JsxRuntime.jsx("div", {
                                        children: JsxRuntime.jsx(PinMap.make, {
                                              connection: match.events.fragmentRefs,
                                              onLocationClick: (function ($$location) {
                                                  navigate("/locations/" + $$location.id, undefined);
                                                }),
                                              selected: match$3[0]
                                            }),
                                        className: "w-full lg:min-h-96 h-96 lg:h-[calc(100vh-50px)] lg:max-h-screen"
                                      }),
                                  className: "shrink-0 border-t border-gray-200 lg:border-l lg:border-t-0"
                                }),
                            className: "mx-auto"
                          }),
                      className: "grow p-0 lg:w-1/2 lg:-ml-1 lg:shadow-sm lg:ring-1 lg:ring-zinc-950/5 dark:lg:bg-zinc-900 dark:lg:ring-white/10"
                    })
              ]
            });
}

var make$1 = EventsList;

export {
  TextEventItem ,
  TextEventsList ,
  EventItem ,
  make$1 as make,
}
/*  Not a pure module */

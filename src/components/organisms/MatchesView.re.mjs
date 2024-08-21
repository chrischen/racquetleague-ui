// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Rating from "../../lib/Rating.re.mjs";
import * as UiAction from "../atoms/UiAction.re.mjs";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as ModalDrawer from "../ui/ModalDrawer.re.mjs";
import * as SubmitMatch from "./SubmitMatch.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as Core from "@linaria/core";
import * as MatchRsvpUser from "../molecules/MatchRsvpUser.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as EventMatchRsvpUser from "./EventMatchRsvpUser.re.mjs";
import * as Solid from "@heroicons/react/24/solid";

import { t, plural } from '@lingui/macro'
;

function MatchesView$PlayerView(props) {
  var status = props.status;
  var maxRating = props.maxRating;
  var minRating = props.minRating;
  var player = props.player;
  var data = player.data;
  if (data !== undefined) {
    return Core__Option.getOr(Core__Option.map(data.user, (function (user) {
                      return JsxRuntime.jsx(EventMatchRsvpUser.make, {
                                  user: user.fragmentRefs,
                                  highlight: status,
                                  ratingPercent: (player.rating.mu - minRating) / (maxRating - minRating) * 100
                                }, user.id);
                    })), null);
  } else {
    return JsxRuntime.jsx(MatchRsvpUser.make, {
                user: Rating.makeGuest(player.name),
                highlight: status,
                ratingPercent: (player.rating.mu - minRating) / (maxRating - minRating) * 100
              }, player.id);
  }
}

var PlayerView = {
  make: MatchesView$PlayerView
};

function MatchesView$Queue(props) {
  var togglePlayer = props.togglePlayer;
  var queue = props.queue;
  var consumedPlayers = props.consumedPlayers;
  var breakPlayers = props.breakPlayers;
  var players = props.players;
  var maxRating = Core__Array.reduce(players, 0, (function (acc, next) {
          if (next.rating.mu > acc) {
            return next.rating.mu;
          } else {
            return acc;
          }
        }));
  var minRating = Core__Array.reduce(players, maxRating, (function (acc, next) {
          if (next.rating.mu < acc) {
            return next.rating.mu;
          } else {
            return acc;
          }
        }));
  return JsxRuntime.jsx("div", {
              children: players.map(function (player) {
                    var match = queue.has(player.id);
                    var match$1 = breakPlayers.has(player.id);
                    var match$2 = consumedPlayers.has(player.id);
                    var status = match$2 ? "Playing" : (
                        match$1 ? "Break" : (
                            match ? "Queued" : "Available"
                          )
                      );
                    return JsxRuntime.jsx(UiAction.make, {
                                onClick: (function (param) {
                                    togglePlayer(player);
                                  }),
                                onTouchStart: (function (param) {
                                    togglePlayer(player);
                                  }),
                                children: JsxRuntime.jsx(MatchesView$PlayerView, {
                                      player: player,
                                      minRating: minRating,
                                      maxRating: maxRating,
                                      status: status
                                    }, player.id)
                              });
                  }),
              className: "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 mt-3"
            });
}

var Queue = {
  make: MatchesView$Queue
};

function MatchesView$ActionBar(props) {
  var onChangeBreakCount = props.onChangeBreakCount;
  var breakCount = props.breakCount;
  var selectAll = props.selectAll;
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsx(UiAction.make, {
                      onClick: (function (param) {
                          selectAll();
                        }),
                      className: "rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
                      children: t`Toggle All`
                    }),
                JsxRuntime.jsxs("div", {
                      children: [
                        JsxRuntime.jsx(UiAction.make, {
                              onClick: (function (param) {
                                  onChangeBreakCount(breakCount - 1 | 0);
                                }),
                              className: "rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
                              children: "-"
                            }),
                        " " + breakCount.toString() + " ",
                        JsxRuntime.jsx(UiAction.make, {
                              onClick: (function (param) {
                                  onChangeBreakCount(breakCount + 1 | 0);
                                }),
                              className: "rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
                              children: "+"
                            }),
                        " ",
                        t`Players on Break`
                      ]
                    }),
                JsxRuntime.jsxs(UiAction.make, {
                      onClick: props.onChooseMatch,
                      className: "-mr-3 bg-indigo-600 px-3.5 py-5 text-lg font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
                      children: [
                        ">>>>>>>>>>> ",
                        t`CHOOSE MATCH`
                      ]
                    })
              ],
              className: "absolute bottom-0 bg-white w-full flex h-[64px] -ml-3 p-3 justify-between items-center"
            });
}

var ActionBar = {
  make: MatchesView$ActionBar
};

function MatchesView(props) {
  var updateSessionPlayerRatings = props.updateSessionPlayerRatings;
  var updatePlayCounts = props.updatePlayCounts;
  var dequeueMatch = props.dequeueMatch;
  var maxRating = props.maxRating;
  var minRating = props.minRating;
  var activity = props.activity;
  var matches = props.matches;
  var match = React.useState(function () {
        return "Matches";
      });
  var setView = match[1];
  var view = match[0];
  var match$1 = React.useState(function () {
        return false;
      });
  var setShowMatchSelector = match$1[1];
  var tmp;
  tmp = view === "Matches" ? JsxRuntime.jsx("div", {
          children: matches.map(function (match, i) {
                return JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsx(SubmitMatch.make, {
                                  match: match,
                                  activity: activity,
                                  minRating: minRating,
                                  maxRating: maxRating,
                                  onDelete: (function () {
                                      dequeueMatch(i);
                                    }),
                                  onComplete: (function (match) {
                                      dequeueMatch(i);
                                      updatePlayCounts(match);
                                      var match$1 = Rating.Match.rate(match);
                                      updateSessionPlayerRatings(match$1.flatMap(function (x) {
                                                return x;
                                              }));
                                    })
                                }, i.toString()),
                            className: "flex flex-col rounded shadow"
                          });
              }),
          className: "grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 mt-3"
        }) : JsxRuntime.jsx(MatchesView$Queue, {
          players: props.players,
          breakPlayers: props.breakPlayers,
          consumedPlayers: props.consumedPlayers,
          queue: props.queue,
          togglePlayer: props.togglePlayer
        });
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsxs("div", {
                      children: [
                        JsxRuntime.jsxs(UiAction.make, {
                              onClick: props.onClose,
                              className: "inline-flex items-center gap-x-2 rounded-md bg-indigo-600 px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
                              children: [
                                JsxRuntime.jsx(Solid.ChevronLeftIcon, {
                                      className: "-ml-0.5 h-5 w-5",
                                      "aria-hidden": "true"
                                    }),
                                t`Go Back`
                              ]
                            }),
                        JsxRuntime.jsxs(UiAction.make, {
                              onClick: (function (param) {
                                  setView(function (param) {
                                        return "Queue";
                                      });
                                }),
                              className: Core.cx("ml-3 inline-flex flex-grow items-center gap-x-2 rounded-md px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600", view === "Queue" ? "bg-black border-solid border-white border-2" : "bg-indigo-600 hover:bg-indigo-500"),
                              children: [
                                JsxRuntime.jsx(Solid.UsersIcon, {
                                      className: "-ml-0.5 h-5 w-5",
                                      "aria-hidden": "true"
                                    }),
                                t`Queue`
                              ]
                            }),
                        JsxRuntime.jsxs(UiAction.make, {
                              onClick: (function (param) {
                                  setView(function (param) {
                                        return "Matches";
                                      });
                                }),
                              className: Core.cx("ml-3 inline-flex flex-grow items-center gap-x-2 rounded-md px-3.5 py-2.5 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600", view === "Matches" ? "bg-black border-solid border-white border-2" : "bg-indigo-600 hover:bg-indigo-500"),
                              children: [
                                JsxRuntime.jsx(Solid.TableCellsIcon, {
                                      className: "-ml-0.5 h-5 w-5",
                                      "aria-hidden": "true"
                                    }),
                                t`Matches`
                              ]
                            }),
                        JsxRuntime.jsx("input", {
                              className: "w-10",
                              value: matches.map(function (param, i) {
                                      var team1 = param[0].map(function (p) {
                                              return p.name;
                                            }).join(" " + t`and` + " ");
                                      var team2 = param[1].map(function (p) {
                                              return p.name;
                                            }).join(" " + t`and` + " ");
                                      return t`Court ${(i + 1 | 0).toString()}: ${team1} versus ${team2}`;
                                    }).join(", "),
                              onClick: (function (e) {
                                  e.target.select();
                                })
                            })
                      ],
                      className: "flex h-[34px] justify-between items-center"
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsx("main", {
                            children: tmp,
                            className: "w-full h-full",
                            role: "main"
                          }),
                      className: "w-full h-[calc(100vh-34px-70px)]"
                    }),
                JsxRuntime.jsx(MatchesView$ActionBar, {
                      selectAll: props.selectAll,
                      breakCount: props.breakCount,
                      onChangeBreakCount: props.onChangeBreakCount,
                      onChooseMatch: (function (param) {
                          setShowMatchSelector(function (s) {
                                return !s;
                              });
                        })
                    }),
                JsxRuntime.jsx(ModalDrawer.make, {
                      title: t`Choose Match`,
                      children: props.matchSelector,
                      open_: match$1[0],
                      setOpen: setShowMatchSelector
                    })
              ],
              className: "w-full h-full absolute top-0 left-0 bg-black p-3"
            });
}

var make = MatchesView;

export {
  PlayerView ,
  Queue ,
  ActionBar ,
  make ,
}
/*  Not a pure module */

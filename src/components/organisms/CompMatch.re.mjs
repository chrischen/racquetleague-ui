// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Util from "../shared/Util.re.mjs";
import * as React from "react";
import * as Rating from "../../lib/Rating.re.mjs";
import * as Session from "../../lib/Session.re.mjs";
import * as UiAction from "../atoms/UiAction.re.mjs";
import * as ReactIntl from "react-intl";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as Core from "@linaria/core";
import * as FramerMotion from "framer-motion";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";
import * as JsxRuntime from "react/jsx-runtime";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

function CompMatch$PlayerMini(props) {
  var player = props.player;
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsxs("span", {
                      children: [
                        player.name,
                        "(",
                        player.rating.mu.toFixed(2),
                        ")",
                        Core__Option.getOr(Core__Option.map(Core__Option.map(props.session, (function (s) {
                                        return "x" + Session.get(s, player.id).count.toString();
                                      })), (function (prim) {
                                    return prim;
                                  })), null)
                      ],
                      className: "mr-2"
                    }),
                JsxRuntime.jsx("br", {})
              ]
            });
}

var PlayerMini = {
  make: CompMatch$PlayerMini
};

function CompMatch$MatchMini(props) {
  var match = props.match;
  var onSelect = props.onSelect;
  var highlight = props.highlight;
  var session = props.session;
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsxs("div", {
                      children: [
                        JsxRuntime.jsx("div", {
                              children: JsxRuntime.jsx("span", {
                                    children: match[0].map(function (p) {
                                          return JsxRuntime.jsx(CompMatch$PlayerMini, {
                                                      player: p,
                                                      session: session
                                                    }, p.id);
                                        })
                                  }),
                              className: Core.cx("col-span-3 px-2 my-1 ml-1", Core__Option.getOr(Core__Option.map(highlight, (function (h) {
                                              switch (h) {
                                                case "Left" :
                                                case "Both" :
                                                    return "bg-yellow-100";
                                                case "Right" :
                                                case "Right2" :
                                                    return "";
                                                case "Left2" :
                                                case "Both2" :
                                                    return "bg-red-200";
                                                
                                              }
                                            })), ""))
                            }),
                        JsxRuntime.jsx("div", {
                              children: " VS ",
                              className: "col-span-1 text-center text-2xl text-gray-800 font-bold"
                            }),
                        JsxRuntime.jsx("div", {
                              children: JsxRuntime.jsx("span", {
                                    children: match[1].map(function (p) {
                                          return JsxRuntime.jsx(CompMatch$PlayerMini, {
                                                      player: p,
                                                      session: session
                                                    }, p.id);
                                        })
                                  }),
                              className: Core.cx("col-span-3 justify-right text-right my-1 mr-1", Core__Option.getOr(Core__Option.map(highlight, (function (h) {
                                              switch (h) {
                                                case "Right" :
                                                case "Both" :
                                                    return "bg-yellow-100";
                                                case "Left" :
                                                case "Left2" :
                                                    return "";
                                                case "Right2" :
                                                case "Both2" :
                                                    return "bg-red-200";
                                                
                                              }
                                            })), ""))
                            })
                      ],
                      className: Core.cx("flex-1 grid grid-cols-7 items-center place-content-center", Core__Option.getOr(Core__Option.map(props.border, (function (h) {
                                      if (h === "Red") {
                                        return "border-red-200 border-4";
                                      } else {
                                        return "border-yellow-100 border-4";
                                      }
                                    })), ""))
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsx(UiAction.make, {
                            onClick: (function (param) {
                                Core__Option.getOr(Core__Option.map(onSelect, (function (f) {
                                            f(match);
                                          })), undefined);
                              }),
                            className: "ml-3 inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-700 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600",
                            children: t`Select`
                          }),
                      className: "self-center p-3"
                    })
              ],
              className: "flex pt-2 pl-2 pr-2"
            });
}

var MatchMini = {
  make: CompMatch$MatchMini
};

function match_make_naive(players) {
  return Rating.array_split_by_n(players, 4).map(function (p) {
              return [
                      [
                        p[0],
                        p[3]
                      ],
                      [
                        p[1],
                        p[2]
                      ]
                    ];
            });
}

function team_to_players_set(team) {
  return new Set(team.map(function (p) {
                  return p.id;
                }));
}

function match_to_players_set(param) {
  return new Set(param[0].concat(param[1]).map(function (p) {
                  return p.id;
                }));
}

function matches_contains_match(matches, match) {
  return (function (__x) {
                return __x.map(match_to_players_set);
              })(matches).findIndex(function (m) {
              return m.intersection(match).size === 4;
            }) > -1;
}

function contains_match(matches, match) {
  return matches.map(function (param) {
                return match_to_players_set(param[0]);
              }).findIndex(function (m) {
              return m.intersection(match).size === 4;
            }) > -1;
}

function CompMatch$Settings(props) {
  return null;
}

var Settings = {
  make: CompMatch$Settings
};

function ts(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

function CompMatch(props) {
  var onSelectMatch = props.onSelectMatch;
  var avoidAllPlayers = props.avoidAllPlayers;
  var priorityPlayers = props.priorityPlayers;
  var setDefaultStrategy = props.setDefaultStrategy;
  var defaultStrategy = props.defaultStrategy;
  var lastRoundSeenMatches = props.lastRoundSeenMatches;
  var lastRoundSeenTeams = props.lastRoundSeenTeams;
  var seenMatches = props.seenMatches;
  var seenTeams = props.seenTeams;
  var consumedPlayers = props.consumedPlayers;
  var session = props.session;
  var players = props.players;
  var match = React.useState(function () {
        return defaultStrategy;
      });
  var setStrategy = match[1];
  var strategy = match[0];
  var intl = ReactIntl.useIntl();
  var strats = [
    {
      name: t`Competitive`,
      strategy: "CompetitivePlus",
      details: t`Matches are arranged by a maximum skill-spread of +- 1 players.`
    },
    {
      name: t`Mixed`,
      strategy: "Mixed",
      details: t`Matches are arranged by skill while mixing strong and weak players.`
    },
    {
      name: t`Random`,
      strategy: "Random",
      details: t`Totally random teams.`
    },
    {
      name: "DUPR",
      strategy: "DUPR",
      details: t`Optimized for DUPR. Teams created with similar skill level players.`
    }
  ];
  var teamConstraints = Util.NonEmptyArray.map(props.teams, Rating.Team.toSet);
  var matches = Rating.getMatches(players, consumedPlayers, strategy, priorityPlayers, avoidAllPlayers, teamConstraints);
  var matchesCount = matches.length;
  var matches$1 = matchesCount !== 0 ? matches : Rating.getMatches(players, consumedPlayers, strategy, priorityPlayers, avoidAllPlayers, undefined);
  var matches$2 = matches$1.slice(0, 115);
  var maxQuality = Core__Array.reduce(matches$2, 0, (function (acc, param) {
          var quality = param[1];
          if (quality > acc) {
            return quality;
          } else {
            return acc;
          }
        }));
  var minQuality = Core__Array.reduce(matches$2, maxQuality, (function (acc, param) {
          var quality = param[1];
          if (quality < acc) {
            return quality;
          } else {
            return acc;
          }
        }));
  var tab = strats.find(function (tab) {
        return tab.strategy === strategy;
      });
  var updateStrategy = function (strategy) {
    setStrategy(function (param) {
          return strategy;
        });
    setDefaultStrategy(function (param) {
          return strategy;
        });
  };
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsxs("div", {
                      children: [
                        JsxRuntime.jsx("label", {
                              children: t`Select a tab`,
                              className: "sr-only",
                              htmlFor: "tabs"
                            }),
                        JsxRuntime.jsx("select", {
                              children: strats.map(function (tab) {
                                    return JsxRuntime.jsx("option", {
                                                children: tab.name,
                                                value: tab.name
                                              }, tab.name);
                                  }),
                              defaultValue: Core__Option.getOr(Core__Option.map(strats.find(function (tab) {
                                            return tab.strategy === strategy;
                                          }), (function (s) {
                                          return s.name;
                                        })), ""),
                              className: "block w-full rounded-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500",
                              id: "tabs",
                              name: "tabs",
                              onChange: (function (e) {
                                  updateStrategy(Core__Option.getOr(Core__Option.map(strats.find(function (tab) {
                                                    return tab.name === e.target.value;
                                                  }), (function (s) {
                                                  return s.strategy;
                                                })), "Competitive"));
                                })
                            })
                      ],
                      className: "sm:hidden"
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsx("nav", {
                            children: strats.map(function (tab) {
                                  return JsxRuntime.jsx(UiAction.make, {
                                              onClick: (function (param) {
                                                  updateStrategy(tab.strategy);
                                                }),
                                              className: Core.cx(strategy === tab.strategy ? "bg-indigo-100 text-indigo-700" : "text-gray-500 hover:text-gray-700", "rounded-md px-3 py-2 text-sm font-medium"),
                                              children: tab.name
                                            }, tab.name);
                                }),
                            "aria-label": "Tabs",
                            className: "flex space-x-4"
                          }),
                      className: "hidden sm:block"
                    }),
                JsxRuntime.jsxs("p", {
                      children: [
                        t`Analyzed ${intl.formatNumber(matchesCount)} matches.`,
                        " ",
                        Core__Option.getOr(Core__Option.map(tab, (function (tab) {
                                    return tab.details;
                                  })), null)
                      ],
                      className: "mt-2 text-base leading-7 text-gray-600"
                    }),
                JsxRuntime.jsxs("p", {
                      children: [
                        JsxRuntime.jsx("span", {
                              children: "...",
                              className: "px-2 py-1 bg-yellow-100"
                            }),
                        " = ",
                        t`This team has played before`,
                        JsxRuntime.jsx("span", {
                              children: "...",
                              className: "ml-2 px-2 py-1 bg-red-100"
                            }),
                        " = ",
                        t`Played last round`
                      ],
                      className: "mt-2 text-base leading-7 text-gray-600 mb-2"
                    }),
                matches$2.map(function (param, i) {
                      var match = param[0];
                      var team2 = match[1];
                      var team1 = match[0];
                      var match$1 = lastRoundSeenTeams.has(Rating.Team.toStableId(team1));
                      var match$2 = lastRoundSeenTeams.has(Rating.Team.toStableId(team2));
                      var highlight2 = match$1 ? (
                          match$2 ? "Both2" : "Left2"
                        ) : (
                          match$2 ? "Right2" : undefined
                        );
                      var match$3 = seenTeams.has(Rating.Team.toStableId(team1));
                      var match$4 = seenTeams.has(Rating.Team.toStableId(team2));
                      var highlight;
                      var exit = 0;
                      if (highlight2 !== undefined) {
                        var exit$1 = 0;
                        switch (highlight2) {
                          case "Left2" :
                              if (match$3) {
                                if (match$4) {
                                  exit = 1;
                                } else {
                                  highlight = "Left2";
                                }
                              } else {
                                exit$1 = 2;
                              }
                              break;
                          case "Right2" :
                              if (match$3) {
                                exit = 1;
                              } else if (match$4) {
                                highlight = "Right2";
                              } else {
                                exit$1 = 2;
                              }
                              break;
                          case "Both2" :
                              if (match$3) {
                                if (match$4) {
                                  highlight = "Both2";
                                } else {
                                  exit = 1;
                                }
                              } else {
                                exit$1 = 2;
                              }
                              break;
                          default:
                            exit$1 = 2;
                        }
                        if (exit$1 === 2) {
                          if (match$3 || match$4) {
                            exit = 1;
                          } else {
                            highlight = highlight2;
                          }
                        }
                        
                      } else if (match$3 || match$4) {
                        exit = 1;
                      } else {
                        highlight = undefined;
                      }
                      if (exit === 1) {
                        highlight = match$3 ? (
                            match$4 ? "Both" : "Left"
                          ) : "Right";
                      }
                      var match$5 = lastRoundSeenMatches.has(Rating.Match.toStableId(match));
                      var match$6 = seenMatches.has(Rating.Match.toStableId(match));
                      var border = match$5 ? "Red" : (
                          match$6 ? "Yellow" : undefined
                        );
                      var match$7 = maxQuality - minQuality;
                      return JsxRuntime.jsxs("div", {
                                  children: [
                                    JsxRuntime.jsx(CompMatch$MatchMini, {
                                          match: match,
                                          session: session,
                                          highlight: highlight,
                                          border: border,
                                          onSelect: Core__Option.map(onSelectMatch, (function (f) {
                                                  return function (match) {
                                                    var tmp;
                                                    tmp = strategy === "RoundRobin" ? false : true;
                                                    f(match, tmp);
                                                  };
                                                }))
                                        }),
                                    JsxRuntime.jsx("div", {
                                          children: JsxRuntime.jsx(FramerMotion.motion.div, {
                                                className: "h-2 rounded-full bg-red-400",
                                                animate: {
                                                  width: match$7 !== 0 ? ((param[1] - minQuality) / (maxQuality - minQuality) * 100).toFixed(3) + "%" : "0%"
                                                },
                                                initial: {
                                                  width: "0%"
                                                }
                                              }),
                                          className: "overflow-hidden rounded-full bg-gray-200 mt-1"
                                        })
                                  ],
                                  className: "border-zinc-600 rounded ring-1 mb-2"
                                }, i.toString());
                    })
              ]
            });
}

var make = CompMatch;

export {
  PlayerMini ,
  MatchMini ,
  match_make_naive ,
  team_to_players_set ,
  match_to_players_set ,
  matches_contains_match ,
  contains_match ,
  Settings ,
  ts ,
  make ,
}
/*  Not a pure module */

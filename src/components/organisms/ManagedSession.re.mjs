// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as UiAction from "../atoms/UiAction.re.mjs";
import * as Openskill from "openskill";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as Core from "@linaria/core";
import * as JsxRuntime from "react/jsx-runtime";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

function get_rating(t) {
  return t.mu;
}

function make(mu, sigma) {
  return Openskill.rating({
              mu: mu,
              sigma: sigma
            });
}

function makeDefault() {
  return Openskill.rating(undefined);
}

function Rating_predictDraw(prim) {
  return Openskill.predictDraw(prim);
}

function Rating_ordinal(prim) {
  return Openskill.ordinal(prim);
}

var Rating = {
  get_rating: get_rating,
  make: make,
  makeDefault: makeDefault,
  predictDraw: Rating_predictDraw,
  ordinal: Rating_ordinal
};

function ManagedSession$Player(props) {
  var player = props.player;
  return JsxRuntime.jsxs("span", {
              children: [
                player.name,
                "(",
                player.rating.mu.toFixed(2),
                ")"
              ],
              className: "mr-2"
            });
}

var Player = {
  make: ManagedSession$Player
};

function ManagedSession$Match(props) {
  var match = props.match;
  var match$1 = match[1];
  var match$2 = match[0];
  var onSelect = props.onSelect;
  return JsxRuntime.jsx(UiAction.make, {
              onClick: (function () {
                  Core__Option.getOr(Core__Option.map(onSelect, (function (f) {
                              f(match);
                            })), undefined);
                }),
              className: "p-4",
              children: JsxRuntime.jsxs("div", {
                    children: [
                      JsxRuntime.jsxs("span", {
                            children: [
                              JsxRuntime.jsx(ManagedSession$Player, {
                                    player: match$2[0]
                                  }),
                              JsxRuntime.jsx(ManagedSession$Player, {
                                    player: match$2[1]
                                  })
                            ]
                          }),
                      " VS ",
                      JsxRuntime.jsxs("span", {
                            children: [
                              JsxRuntime.jsx(ManagedSession$Player, {
                                    player: match$1[0]
                                  }),
                              JsxRuntime.jsx(ManagedSession$Player, {
                                    player: match$1[1]
                                  })
                            ]
                          })
                    ],
                    className: "mb-2"
                  })
            });
}

var Match = {
  make: ManagedSession$Match
};

function array_get_4_from(from, arr) {
  if (from >= (arr.length - 3 | 0)) {
    return ;
  }
  var arr$1 = arr.slice(from, from + 4 | 0);
  var match = arr$1[0];
  var match$1 = arr$1[1];
  var match$2 = arr$1[2];
  var match$3 = arr$1[3];
  if (match !== undefined && match$1 !== undefined && match$2 !== undefined && match$3 !== undefined) {
    return [
            Caml_option.valFromOption(match),
            Caml_option.valFromOption(match$1),
            Caml_option.valFromOption(match$2),
            Caml_option.valFromOption(match$3)
          ];
  }
  
}

function array_split_by_4(arr) {
  var _from = 0;
  var _acc = [];
  while(true) {
    var acc = _acc;
    var from = _from;
    var next = array_get_4_from(from, arr);
    if (next === undefined) {
      return acc;
    }
    _acc = acc.concat([next]);
    _from = from + 1 | 0;
    continue ;
  };
}

function match_make_naive(players) {
  return array_split_by_4(players).map(function (param) {
              return [
                      [
                        param[0],
                        param[3]
                      ],
                      [
                        param[1],
                        param[2]
                      ]
                    ];
            });
}

function ManagedSession$SelectPlayersList(props) {
  var onClick = props.onClick;
  var selected = props.selected;
  return JsxRuntime.jsx("ul", {
              children: props.players.map(function (player) {
                    return JsxRuntime.jsx("li", {
                                children: JsxRuntime.jsx(UiAction.make, {
                                      onClick: (function () {
                                          onClick(player);
                                        }),
                                      className: "p-4",
                                      children: player.name
                                    }),
                                className: Core.cx(selected.indexOf(player.id) > -1 ? "font-bold" : "", "inline", "mr-2")
                              }, player.id);
                  }),
              className: "w-full mb-4"
            });
}

var SelectPlayersList = {
  make: ManagedSession$SelectPlayersList
};

function contains_player(param, player) {
  if (param[0].id === player.id) {
    return true;
  } else {
    return param[1].id === player.id;
  }
}

var Team = {
  contains_player: contains_player
};

function array_combos(arr) {
  return arr.flatMap(function (v, i) {
              return arr.slice(i + 1 | 0, arr.length).map(function (v2) {
                          return [
                                  v,
                                  v2
                                ];
                        });
            });
}

function combos(arr1, arr2) {
  return arr1.flatMap(function (d) {
              return arr2.map(function (v) {
                          return [
                                  d,
                                  v
                                ];
                        });
            });
}

function match_quality(param) {
  var match = param[1];
  var match$1 = param[0];
  var team1 = [
    match$1[0],
    match$1[1]
  ];
  var team2 = [
    match[0],
    match[1]
  ];
  return Rating_predictDraw([
              team1.map(function (p) {
                    return p.rating;
                  }),
              team2.map(function (p) {
                    return p.rating;
                  })
            ]);
}

function ManagedSession(props) {
  var onSelectMatch = props.onSelectMatch;
  var consumedPlayers = props.consumedPlayers;
  var players = props.players;
  var match = React.useState(function () {
        return [];
      });
  var setActivePlayers = match[1];
  var activePlayers = match[0].filter(function (p) {
          return !consumedPlayers.has(p.id);
        }).toSorted(function (a, b) {
        var userA = a.rating.mu;
        var userB = b.rating.mu;
        if (userA < userB) {
          return 1;
        } else {
          return -1;
        }
      });
  var teams = array_combos(activePlayers);
  var matches = Core__Array.reduce(teams, [], (function (acc, team) {
          var players$p = activePlayers.filter(function (p) {
                return !contains_player(team, p);
              });
          var teams$p = array_combos(players$p);
          return acc.concat(combos([team], teams$p));
        }));
  var matches$1 = matches.map(function (match) {
            var quality = match_quality(match);
            return [
                    match,
                    quality
                  ];
          }).toSorted(function (a, b) {
          if (a[1] < b[1]) {
            return 1;
          } else {
            return -1;
          }
        }).slice(0, 15);
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                JsxRuntime.jsx(UiAction.make, {
                      onClick: (function () {
                          setActivePlayers(function (param) {
                                return players;
                              });
                        }),
                      children: t`select all`
                    }),
                JsxRuntime.jsx(ManagedSession$SelectPlayersList, {
                      players: players,
                      selected: activePlayers.map(function (p) {
                            return p.id;
                          }),
                      onClick: (function (player) {
                          setActivePlayers(function (ps) {
                                var match = Core__Array.findIndexOpt(ps, (function (p) {
                                        return p.id === player.id;
                                      }));
                                if (match !== undefined) {
                                  return ps.filter(function (v) {
                                              return v.id !== player.id;
                                            });
                                } else {
                                  return ps.concat([player]);
                                }
                              });
                        })
                    }),
                matches$1.map(function (param, i) {
                      return JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                  children: [
                                    JsxRuntime.jsx(ManagedSession$Match, {
                                          match: param[0],
                                          onSelect: onSelectMatch
                                        }, i.toString(undefined)),
                                    " - ",
                                    param[1].toString(undefined)
                                  ]
                                });
                    })
              ]
            });
}

var make$1 = ManagedSession;

export {
  Rating ,
  Player ,
  Match ,
  array_get_4_from ,
  array_split_by_4 ,
  match_make_naive ,
  SelectPlayersList ,
  Team ,
  array_combos ,
  combos ,
  match_quality ,
  make$1 as make,
}
/*  Not a pure module */

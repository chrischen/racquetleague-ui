// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Util from "../components/shared/Util.re.mjs";
import * as Js_dict from "rescript/lib/es6/js_dict.js";
import * as Session from "./Session.re.mjs";
import * as Openskill from "openskill";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Caml_int32 from "rescript/lib/es6/caml_int32.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as Core__String from "@rescript/core/src/Core__String.re.mjs";
import * as PlackettLuceTs from "../lib/rating/models/plackettLuce.ts";

var plackettLuce = PlackettLuceTs.plackettLuce;

var RatingModel = {
  plackettLuce: plackettLuce
};

function makeGuest(name) {
  return {
          name: name,
          picture: undefined
        };
}

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

function Rating_rate(prim0, prim1) {
  return Openskill.rate(prim0, prim1 !== undefined ? Caml_option.valFromOption(prim1) : undefined);
}

var Rating = {
  get_rating: get_rating,
  make: make,
  makeDefault: makeDefault,
  predictDraw: Rating_predictDraw,
  ordinal: Rating_ordinal,
  rate: Rating_rate
};

function makeDefaultRatingPlayer(name) {
  var rating = Openskill.rating(undefined);
  return {
          data: undefined,
          id: "guest-" + name,
          name: name,
          rating: rating,
          ratingOrdinal: Rating_ordinal(rating),
          paid: false
        };
}

var Player = {
  makeDefaultRatingPlayer: makeDefaultRatingPlayer
};

function contains_player(players, player) {
  var players$1 = new Set(players.map(function (p) {
            return p.id;
          }));
  return players$1.has(player.id);
}

function toSet(team) {
  return new Set(team.map(function (p) {
                  return p.id;
                }));
}

function is_equal_to(t1, t2) {
  var t1$1 = new Set(t1.map(function (p) {
            return p.id;
          }));
  var t2$1 = new Set(t2.map(function (p) {
            return p.id;
          }));
  return t1$1.intersection(t2$1).size === t1$1.size;
}

function toStableId(t) {
  return t.map(function (p) {
                  return p.id;
                }).toSorted(Core__String.compare).join("-");
}

var Team = {
  contains_player: contains_player,
  toSet: toSet,
  is_equal_to: is_equal_to,
  toStableId: toStableId
};

function is_equal_to$1(t1, t2) {
  return t1.intersection(t2).size === t1.size;
}

function containsAllOf(t1, t2) {
  return t2.intersection(t1).size === t2.size;
}

var TeamSet = {
  is_equal_to: is_equal_to$1,
  containsAllOf: containsAllOf
};

function contains_player$1(param, player) {
  if (contains_player(param[0], player)) {
    return true;
  } else {
    return contains_player(param[1], player);
  }
}

function contains_any_players(param, players) {
  var players$1 = new Set(players.map(function (p) {
            return p.id;
          }));
  var match_players = new Set([
            param[0],
            param[1]
          ].map(function (t) {
              return t.map(function (p) {
                          return p.id;
                        });
            }).flatMap(function (x) {
            return x;
          }));
  return match_players.intersection(players$1).size > 0;
}

function contains_all_players(param, players) {
  var players$1 = new Set(players.map(function (p) {
            return p.id;
          }));
  var match_players = new Set([
            param[0],
            param[1]
          ].map(function (t) {
              return t.map(function (p) {
                          return p.id;
                        });
            }).flatMap(function (x) {
            return x;
          }));
  return players$1.intersection(match_players).size === players$1.size;
}

function rate(param) {
  var losers = param[1];
  var winners = param[0];
  return Belt_Array.zipBy(Rating_rate([
                    winners,
                    losers
                  ].map(function (__x) {
                      return __x.map(function (player) {
                                  return player.rating;
                                });
                    }), Caml_option.some({
                      model: plackettLuce
                    })), [
              winners,
              losers
            ], (function (new_ratings, old_teams) {
                return Belt_Array.zipBy(new_ratings, old_teams, (function (new_rating, old_player) {
                              return {
                                      data: old_player.data,
                                      id: old_player.id,
                                      name: old_player.name,
                                      rating: new_rating,
                                      ratingOrdinal: old_player.ratingOrdinal,
                                      paid: old_player.paid
                                    };
                            }));
              }));
}

function toStableId$1(param) {
  return [
              toStableId(param[0]),
              toStableId(param[1])
            ].toSorted(Core__String.compare).join("-");
}

function players(param) {
  return [
            param[0],
            param[1]
          ].flatMap(function (x) {
              return x;
            });
}

var Match = {
  contains_player: contains_player$1,
  contains_any_players: contains_any_players,
  contains_all_players: contains_all_players,
  rate: rate,
  toStableId: toStableId$1,
  players: players
};

function submit(param, activitySlug, submitMatch) {
  var score = param[1];
  if (score !== undefined) {
    return submitMatch(param[0], [
                score[0],
                score[1]
              ], activitySlug);
  } else {
    return Promise.resolve();
  }
}

function toStableId$2(param) {
  return toStableId$1(param[0]);
}

var CompletedMatch = {
  submit: submit,
  toStableId: toStableId$2
};

function getLastPlayedPlayers(matches, restCount, availablePlayers) {
  var playersCount = availablePlayers - restCount | 0;
  var teams = matches.toReversed().flatMap(function (param) {
        var match = param[0];
        return [
                match[0],
                match[1]
              ];
      });
  return teams.flatMap(function (p) {
                return p;
              }).slice(0, playersCount);
}

function getLastRoundMatches(matches, restCount, availablePlayers, playersPerMatch) {
  var lastPlayedCount = getLastPlayedPlayers(matches, restCount, availablePlayers).length;
  var matchesPlayed = Caml_int32.div(lastPlayedCount, playersPerMatch);
  return matches.toReversed().slice(0, matchesPlayed);
}

function getNumberOfRounds(matches, restCount, availablePlayers, playersPerMatch) {
  var lastPlayedCount = getLastPlayedPlayers(matches, restCount, availablePlayers).length;
  var matchesLastPlayed = Caml_int32.div(lastPlayedCount, playersPerMatch);
  if (matchesLastPlayed !== 0) {
    return Caml_int32.div(matches.length, matchesLastPlayed);
  } else {
    return 0;
  }
}

function saveMatches(t, namespace) {
  var t$1 = t.map(function (param) {
        var match = param[0];
        return [
                [
                  match[0].map(function (p) {
                        return p.id;
                      }),
                  match[1].map(function (p) {
                        return p.id;
                      })
                ],
                param[1]
              ];
      });
  localStorage.setItem(namespace + "-matchesState", Core__Option.getOr(JSON.stringify(t$1), ""));
}

function loadMatches(namespace, players) {
  var players$1 = Core__Array.reduce(players, {}, (function (acc, player) {
          acc[player.id] = player;
          return acc;
        }));
  var state = localStorage.getItem(namespace + "-matchesState");
  return Core__Array.filterMap((
                state !== null ? JSON.parse(state) : []
              ).map(function (param) {
                  var match = param[0];
                  var score = Caml_option.nullable_to_opt(param[1]);
                  return [
                          [
                            Core__Array.reduce(match[0].map(function (p) {
                                      return Js_dict.get(players$1, p);
                                    }), [], (function (acc, player) {
                                    return Core__Option.flatMap(acc, (function (acc) {
                                                  if (player !== undefined) {
                                                    return acc.concat([player]);
                                                  }
                                                  
                                                }));
                                  })),
                            Core__Array.reduce(match[1].map(function (p) {
                                      return Js_dict.get(players$1, p);
                                    }), [], (function (acc, player) {
                                    return Core__Option.flatMap(acc, (function (acc) {
                                                  if (player !== undefined) {
                                                    return acc.concat([player]);
                                                  }
                                                  
                                                }));
                                  }))
                          ],
                          score
                        ];
                }), (function (param) {
                var match = param[0];
                var team2 = match[1];
                var team1 = match[0];
                if (team1 !== undefined && team2 !== undefined) {
                  return [
                          [
                            team1,
                            team2
                          ],
                          param[1]
                        ];
                }
                
              }));
}

var CompletedMatches = {
  getLastPlayedPlayers: getLastPlayedPlayers,
  getLastRoundMatches: getLastRoundMatches,
  getNumberOfRounds: getNumberOfRounds,
  saveMatches: saveMatches,
  loadMatches: loadMatches
};

function fromTeam(team) {
  if (team.length !== 2) {
    return {
            TAG: "Error",
            _0: "TwoPlayersRequired"
          };
  }
  var p1 = team[0];
  var p2 = team[1];
  return {
          TAG: "Ok",
          _0: [
            p1,
            p2
          ]
        };
}

var DoublesTeam = {
  fromTeam: fromTeam
};

function fromMatch(param) {
  var t1 = fromTeam(param[0]);
  var t2 = fromTeam(param[1]);
  if (t1.TAG === "Ok") {
    if (t2.TAG === "Ok") {
      return {
              TAG: "Ok",
              _0: [
                t1._0,
                t2._0
              ]
            };
    } else {
      return {
              TAG: "Error",
              _0: t2._0
            };
    }
  } else {
    return {
            TAG: "Error",
            _0: t1._0
          };
  }
}

var DoublesMatch = {
  fromMatch: fromMatch
};

function sortByRatingDesc(t) {
  return t.toSorted(function (a, b) {
              var userA = a.rating.mu;
              var userB = b.rating.mu;
              if (userA < userB) {
                return 1;
              } else {
                return -1;
              }
            });
}

function sortByPlayCountAsc(t, session) {
  return t.toSorted(function (a, b) {
              if (Session.get(session, a.id).count < Session.get(session, b.id).count) {
                return -1;
              } else {
                return 1;
              }
            });
}

function sortByPlayCountDesc(t, session) {
  return t.toSorted(function (a, b) {
              if (Session.get(session, a.id).count < Session.get(session, b.id).count) {
                return 1;
              } else {
                return -1;
              }
            });
}

function sortByOrdinalDesc(t) {
  return t.toSorted(function (a, b) {
              if (a.ratingOrdinal < b.ratingOrdinal) {
                return 1;
              } else {
                return -1;
              }
            });
}

function filterOut(players, unavailable) {
  return players.filter(function (p) {
              return !unavailable.has(p.id);
            });
}

function addBreakPlayersFrom(breakPlayers, players, breakCount) {
  return filterOut(players, new Set(breakPlayers.map(function (p) {
                          return p.id;
                        }))).slice(0, breakCount - breakPlayers.length | 0).concat(breakPlayers);
}

function savePlayers(t, namespace) {
  var t$1 = t.map(function (p) {
        return {
                data: undefined,
                id: p.id,
                name: p.name,
                rating: p.rating,
                ratingOrdinal: p.ratingOrdinal,
                paid: p.paid
              };
      });
  var t$2 = Core__Array.reduce(t$1, {}, (function (acc, player) {
          acc[player.id] = player;
          return acc;
        }));
  localStorage.setItem(namespace + "-playersState", Core__Option.getOr(JSON.stringify(t$2), ""));
}

function loadPlayers(players, namespace) {
  var state = localStorage.getItem(namespace + "-playersState");
  var storage = state !== null ? JSON.parse(state) : ({});
  return players.map(function (p) {
              return Core__Option.getOr(Core__Option.map(Js_dict.get(storage, p.id), (function (store) {
                                return {
                                        data: p.data,
                                        id: store.id,
                                        name: store.name,
                                        rating: store.rating,
                                        ratingOrdinal: store.ratingOrdinal,
                                        paid: store.paid
                                      };
                              })), p);
            });
}

var Players = {
  sortByRatingDesc: sortByRatingDesc,
  sortByPlayCountAsc: sortByPlayCountAsc,
  sortByPlayCountDesc: sortByPlayCountDesc,
  sortByOrdinalDesc: sortByOrdinalDesc,
  filterOut: filterOut,
  addBreakPlayersFrom: addBreakPlayersFrom,
  savePlayers: savePlayers,
  loadPlayers: loadPlayers
};

function array_get_n_from(from, n, arr) {
  var n$1 = arr.length > 3 && arr.length < n ? arr.length : n;
  if (from >= (arr.length - (n$1 - 1 | 0) | 0)) {
    return ;
  }
  var arr$1 = arr.slice(from, from + n$1 | 0);
  if (n$1 === arr$1.length) {
    return arr$1;
  }
  
}

function array_split_by_n(arr, n) {
  var _from = 0;
  var _acc = [];
  while(true) {
    var acc = _acc;
    var from = _from;
    var next = array_get_n_from(from, n, arr);
    if (next === undefined) {
      return acc;
    }
    _acc = acc.concat([next]);
    _from = from + 1 | 0;
    continue ;
  };
}

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
  return Rating_predictDraw([
              param[0].map(function (p) {
                    return p.rating;
                  }),
              param[1].map(function (p) {
                    return p.rating;
                  })
            ]);
}

function shuffle(arr) {
  return arr.map(function (value) {
                  return {
                          value: value,
                          sort: Math.random()
                        };
                }).toSorted(function (a, b) {
                return a.sort - b.sort;
              }).map(function (param) {
              return param.value;
            });
}

function tuple2array(param) {
  return [
          param[0],
          param[1]
        ];
}

function team_to_players_set(team) {
  return new Set(team.map(function (p) {
                  return p.id;
                }));
}

function find_all_match_combos(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints) {
  var teams = array_combos(availablePlayers).map(tuple2array);
  var teamConstraintsSet = new Set(Util.NonEmptyArray.toArray(teamConstraints).map(function (a) {
              return Array.from(a.values());
            }).flatMap(function (x) {
            return x;
          }));
  var implicitTeam = new Set(availablePlayers.filter(function (p) {
              return !teamConstraintsSet.has(p.id);
            }).map(function (p) {
            return p.id;
          }));
  var result = Core__Array.reduce(teams, {
        seenTeams: [],
        matches: []
      }, (function (param, team) {
          var seenTeams = param.seenTeams;
          var players$p = availablePlayers.filter(function (p) {
                return !contains_player(team, p);
              });
          var teams$p = array_combos(players$p).map(tuple2array);
          var teams$p$1 = teams$p.filter(function (t) {
                return seenTeams.findIndex(function (t$p) {
                            return is_equal_to$1(t$p, team_to_players_set(t));
                          }) === -1;
              });
          return {
                  seenTeams: seenTeams.concat([team_to_players_set(team)]),
                  matches: param.matches.concat(combos([team], teams$p$1))
                };
        }));
  var matches = result.matches.map(function (match) {
        var quality = match_quality(match);
        return [
                match,
                quality
              ];
      });
  var results = priorityPlayers.length === 0 ? matches : matches.filter(function (param) {
          return contains_any_players(param[0], priorityPlayers);
        });
  var results$1 = avoidAllPlayers.length < 2 ? results : results.filter(function (param) {
          return !contains_all_players(param[0], avoidAllPlayers);
        });
  return Core__Option.getOr(Core__Option.map(teamConstraints, (function (teamConstraints) {
                    var teamConstraints$1 = teamConstraints.concat([implicitTeam]);
                    return results$1.filter(function (param) {
                                var match = param[0];
                                var team1 = toSet(match[0]);
                                var team2 = toSet(match[1]);
                                var constr1 = teamConstraints$1.findIndex(function (teamConstraint) {
                                      return containsAllOf(teamConstraint, team1);
                                    }) > -1;
                                var constr2 = teamConstraints$1.findIndex(function (teamConstraint) {
                                      return containsAllOf(teamConstraint, team2);
                                    }) > -1;
                                if (constr1) {
                                  return constr2;
                                } else {
                                  return false;
                                }
                              });
                  })), results$1);
}

function find_skip(n) {
  if (n === 0) {
    return 1;
  } else {
    return (find_skip(n - 1 | 0) + n | 0) + 1 | 0;
  }
}

function pick_every_n_from_array(arr, n, offset) {
  return arr.filter(function (param, i) {
              return Caml_int32.mod_(i - offset | 0, n) === 0;
            });
}

function uniform_shuffle_array(arr, n, offset) {
  if (n === offset) {
    return [];
  }
  var picks = pick_every_n_from_array(arr, n, offset);
  return picks.concat(uniform_shuffle_array(arr, n, offset + 1 | 0));
}

function strategy_by_competitive(players, consumedPlayers, priorityPlayers, avoidAllPlayers, teams) {
  return Core__Array.reduce(array_split_by_n(sortByRatingDesc(players), 8), [], (function (acc, playerSet) {
                var matches = find_all_match_combos(filterOut(playerSet, consumedPlayers), priorityPlayers, avoidAllPlayers, teams).toSorted(function (a, b) {
                      if (a[1] < b[1]) {
                        return 1;
                      } else {
                        return -1;
                      }
                    });
                return acc.concat(matches);
              }));
}

function strategy_by_competitive_plus(players, consumedPlayers, priorityPlayers, avoidAllPlayers, teams) {
  return Core__Array.reduce(array_split_by_n(players.toSorted(function (a, b) {
                      var userA = a.rating.mu;
                      var userB = b.rating.mu;
                      if (userA < userB) {
                        return 1;
                      } else {
                        return -1;
                      }
                    }), 6), [], (function (acc, playerSet) {
                var matches = find_all_match_combos(filterOut(playerSet, consumedPlayers), priorityPlayers, avoidAllPlayers, teams).toSorted(function (a, b) {
                      if (a[1] < b[1]) {
                        return 1;
                      } else {
                        return -1;
                      }
                    });
                return acc.concat(matches);
              }));
}

function strategy_by_mixed(availablePlayers, priorityPlayers, avoidAllPlayers, teams) {
  return find_all_match_combos(availablePlayers, priorityPlayers, avoidAllPlayers, teams).toSorted(function (a, b) {
              if (a[1] < b[1]) {
                return 1;
              } else {
                return -1;
              }
            });
}

function strategy_by_round_robin(availablePlayers, priorityPlayers, avoidAllPlayers, teams) {
  var count = Math.max(4, availablePlayers.length);
  var skip = find_skip(count - 4 | 0);
  var matches = find_all_match_combos(availablePlayers, priorityPlayers, avoidAllPlayers, teams);
  return uniform_shuffle_array(matches, skip, 0);
}

function strategy_by_random(availablePlayers, priorityPlayers, avoidAllPlayers, teams) {
  var matches = find_all_match_combos(availablePlayers, priorityPlayers, avoidAllPlayers, teams);
  return shuffle(matches);
}

function strategy_by_dupr(availablePlayers, priorityPlayers, avoidAllPlayers) {
  var teams = Util.NonEmptyArray.fromArray(array_split_by_n(sortByRatingDesc(availablePlayers), 3).map(function (__x) {
              return __x.map(function (p) {
                          return p.id;
                        });
            }).map(function (prim) {
            return new Set(prim);
          }));
  var matches = find_all_match_combos(availablePlayers, priorityPlayers, avoidAllPlayers, teams);
  return matches.toSorted(function (a, b) {
              if (a[1] < b[1]) {
                return 1;
              } else {
                return -1;
              }
            });
}

function getMatches(players, consumedPlayers, strategy, priorityPlayers, avoidAllPlayers, teamConstraints) {
  var availablePlayers = filterOut(players, consumedPlayers);
  switch (strategy) {
    case "CompetitivePlus" :
        return strategy_by_competitive_plus(players, consumedPlayers, priorityPlayers, avoidAllPlayers, teamConstraints);
    case "Competitive" :
        return strategy_by_competitive(players, consumedPlayers, priorityPlayers, avoidAllPlayers, teamConstraints);
    case "Mixed" :
        return strategy_by_mixed(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints);
    case "RoundRobin" :
        return strategy_by_round_robin(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints);
    case "Random" :
        return strategy_by_random(availablePlayers, priorityPlayers, avoidAllPlayers, teamConstraints);
    case "DUPR" :
        return strategy_by_dupr(availablePlayers, priorityPlayers, avoidAllPlayers);
    
  }
}

function fromPlayers(players) {
  return Js_dict.fromArray(players.map(function (p) {
                  return [
                          p.id,
                          p
                        ];
                }));
}

var get = Js_dict.get;

var PlayersCache = {
  fromPlayers: fromPlayers,
  get: get
};

function toDndItems(t) {
  return Js_dict.fromArray(t.map(function (param, param$1) {
                      return [
                              param[0],
                              param[1]
                            ];
                    }).flatMap(function (x) {
                    return x;
                  }).map(function (team, i) {
                  return [
                          i.toString(),
                          team.map(function (p) {
                                return i.toString() + ":" + p.id;
                              })
                        ];
                }));
}

function fromDndItems(items, playersCache) {
  return Core__Array.reduce(Js_dict.entries(items).map(function (param) {
                    var players = param[1].map(function (p) {
                          var match = p.split(":");
                          var p$1 = match.length !== 2 ? undefined : match[1];
                          return Core__Option.flatMap(p$1, (function (p) {
                                        return Js_dict.get(playersCache, p);
                                      }));
                        });
                    return Core__Array.filterMap(players, (function (x) {
                                  return x;
                                }));
                  }), [
                [],
                [
                  undefined,
                  undefined
                ]
              ], (function (param, team) {
                  var buildingMatch = param[1];
                  var t1 = buildingMatch[0];
                  var matches = param[0];
                  if (t1 !== undefined) {
                    var t2 = buildingMatch[1];
                    if (t2 !== undefined) {
                      return [
                              matches.concat([[
                                      t1,
                                      t2
                                    ]]),
                              [
                                team,
                                undefined
                              ]
                            ];
                    } else {
                      return [
                              matches.concat([[
                                      t1,
                                      team
                                    ]]),
                              [
                                undefined,
                                undefined
                              ]
                            ];
                    }
                  }
                  var t2$1 = buildingMatch[1];
                  if (t2$1 !== undefined) {
                    return [
                            matches.concat([[
                                    team,
                                    t2$1
                                  ]]),
                            [
                              undefined,
                              undefined
                            ]
                          ];
                  } else {
                    return [
                            matches,
                            [
                              team,
                              undefined
                            ]
                          ];
                  }
                }))[0];
}

var Matches = {
  toDndItems: toDndItems,
  fromDndItems: fromDndItems
};

export {
  RatingModel ,
  makeGuest ,
  Rating ,
  Player ,
  Team ,
  TeamSet ,
  Match ,
  CompletedMatch ,
  CompletedMatches ,
  DoublesTeam ,
  DoublesMatch ,
  Players ,
  array_get_n_from ,
  array_split_by_n ,
  array_combos ,
  combos ,
  match_quality ,
  shuffle ,
  tuple2array ,
  team_to_players_set ,
  find_all_match_combos ,
  find_skip ,
  pick_every_n_from_array ,
  uniform_shuffle_array ,
  strategy_by_competitive ,
  strategy_by_competitive_plus ,
  strategy_by_mixed ,
  strategy_by_round_robin ,
  strategy_by_random ,
  strategy_by_dupr ,
  getMatches ,
  PlayersCache ,
  Matches ,
}
/* plackettLuce Not a pure module */

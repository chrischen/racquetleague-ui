// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Zod from "zod";
import * as Form from "../molecules/forms/Form.re.mjs";
import * as React from "react";
import * as Rating from "../../lib/Rating.re.mjs";
import * as Dropdown from "../catalyst/Dropdown.re.mjs";
import * as UiAction from "../atoms/UiAction.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Float from "@rescript/core/src/Core__Float.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as Core__Result from "@rescript/core/src/Core__Result.re.mjs";
import * as LucideReact from "lucide-react";
import * as MatchRsvpUser from "../molecules/MatchRsvpUser.re.mjs";
import * as FramerMotion from "framer-motion";
import * as ReactHookForm from "react-hook-form";
import * as React$1 from "@headlessui/react";
import * as JsxRuntime from "react/jsx-runtime";
import * as EventMatchRsvpUser from "./EventMatchRsvpUser.re.mjs";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as Zod$1 from "@hookform/resolvers/zod";
import * as Solid from "@heroicons/react/24/solid";
import * as SortableSubmitMatchPredictMatchOutcomeQuery_graphql from "../../__generated__/SortableSubmitMatchPredictMatchOutcomeQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

var convertVariables = SortableSubmitMatchPredictMatchOutcomeQuery_graphql.Internal.convertVariables;

var convertResponse = SortableSubmitMatchPredictMatchOutcomeQuery_graphql.Internal.convertResponse;

RescriptRelay_Query.useQuery(convertVariables, SortableSubmitMatchPredictMatchOutcomeQuery_graphql.node, convertResponse);

RescriptRelay_Query.useLoader(convertVariables, SortableSubmitMatchPredictMatchOutcomeQuery_graphql.node, (function (prim) {
        return prim;
      }));

RescriptRelay_Query.usePreloaded(SortableSubmitMatchPredictMatchOutcomeQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

RescriptRelay_Query.$$fetch(SortableSubmitMatchPredictMatchOutcomeQuery_graphql.node, convertResponse, convertVariables);

RescriptRelay_Query.fetchPromised(SortableSubmitMatchPredictMatchOutcomeQuery_graphql.node, convertResponse, convertVariables);

RescriptRelay_Query.retain(SortableSubmitMatchPredictMatchOutcomeQuery_graphql.node, convertVariables);

function SortableSubmitMatch$PredictionBar(props) {
  var match = props.match;
  var team1 = match[0];
  var team2 = match[1];
  var outcome = Rating.Rating.predictWin([
        team1.map(function (node) {
              return node.rating;
            }),
        team2.map(function (node) {
              return node.rating;
            })
      ]);
  var odds_0 = Core__Option.getOr(outcome[0], 0);
  var odds_1 = Core__Option.getOr(outcome[1], 0);
  var odds = odds_1 - odds_0;
  var leftOdds = odds < 0 ? Math.abs(odds * 1000) : 0;
  var rightOdds = odds < 0 ? 0 : odds * 1000;
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsx("div", {
                      children: odds < 0 ? JsxRuntime.jsxs(JsxRuntime.Fragment, {
                              children: [
                                JsxRuntime.jsx(LucideReact.MoveLeft, {
                                      className: "inline",
                                      color: "red"
                                    }),
                                t`predicted winner`,
                                JsxRuntime.jsx(LucideReact.MoveRight, {
                                      className: "inline",
                                      color: "#929292"
                                    })
                              ]
                            }) : JsxRuntime.jsxs(JsxRuntime.Fragment, {
                              children: [
                                JsxRuntime.jsx(LucideReact.MoveLeft, {
                                      className: "inline",
                                      color: "#929292"
                                    }),
                                t`predicted winner`,
                                JsxRuntime.jsx(LucideReact.MoveRight, {
                                      className: "inline",
                                      color: "red"
                                    })
                              ]
                            }),
                      className: "col-span-2 text-center"
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsx(FramerMotion.motion.div, {
                            className: "h-2 rounded-l-full bg-red-400 float-right",
                            animate: {
                              width: leftOdds.toFixed(3) + "%"
                            },
                            initial: {
                              width: "0%"
                            }
                          }),
                      className: "overflow-hidden rounded-l-full bg-gray-200 mt-1 place-content-end border-r-4 border-black"
                    }),
                JsxRuntime.jsx("div", {
                      children: JsxRuntime.jsx(FramerMotion.motion.div, {
                            className: "h-2 rounded-r-full bg-blue-400",
                            animate: {
                              width: rightOdds.toFixed(3) + "%"
                            },
                            initial: {
                              width: "0%"
                            }
                          }),
                      className: "overflow-hidden rounded-r-full bg-gray-200 mt-1 border-l-4 border-black border-l-radius"
                    })
              ],
              className: "grid grid-cols-2 gap-0"
            });
}

var schema = Zod.z.object({
      scoreLeft: Zod.z.preprocess((function (a) {
              return Core__Option.getOr(Core__Float.fromString(a), 0);
            }), Zod.z.number({
                  invalid_type_error: "Enter a number"
                }).gte(0)),
      scoreRight: Zod.z.preprocess((function (a) {
              return Core__Option.getOr(Core__Float.fromString(a), 0);
            }), Zod.z.number({
                  invalid_type_error: "Enter a number"
                }).gte(0))
    });

function SortableSubmitMatch$PlayerView(props) {
  var maxRating = props.maxRating;
  var minRating = props.minRating;
  var player = props.player;
  var data = player.data;
  if (data !== undefined) {
    return Core__Option.getOr(Core__Option.map(data.user, (function (user) {
                      return JsxRuntime.jsx(EventMatchRsvpUser.make, {
                                  user: user.fragmentRefs,
                                  compact: true,
                                  ratingPercent: (player.rating.mu - minRating) / (maxRating - minRating) * 100
                                }, user.id);
                    })), null);
  } else {
    return JsxRuntime.jsx(MatchRsvpUser.make, {
                user: Rating.makeGuest(player.name),
                compact: true,
                ratingPercent: (player.rating.mu - minRating) / (maxRating - minRating) * 100
              }, player.id);
  }
}

var PlayerView = {
  make: SortableSubmitMatch$PlayerView
};

function SortableSubmitMatch(props) {
  var onComplete = props.onComplete;
  var maxRating = props.maxRating;
  var minRating = props.minRating;
  var match = props.match;
  var children = props.children;
  var __defaultView = props.defaultView;
  var defaultView = __defaultView !== undefined ? __defaultView : "Default";
  var match$1 = React.useState(function () {
        return defaultView;
      });
  var setView = match$1[1];
  var match$2 = ReactHookForm.useForm({
        resolver: Caml_option.some(Zod$1.zodResolver(schema)),
        defaultValues: {}
      });
  var setValue = match$2.setValue;
  var register = match$2.register;
  var team1 = match[0];
  var team2 = match[1];
  var doublesMatch = Rating.DoublesMatch.fromMatch(match);
  var match$3 = React.useState(function () {
        return false;
      });
  var setSubmitting = match$3[1];
  var submitting = match$3[0];
  var handleWinner = function (winningSide) {
    Core__Option.map(onComplete, (function (f) {
            var match_0 = winningSide === "Left" ? team1 : team2;
            var match_1 = winningSide === "Left" ? team2 : team1;
            var match = [
              match_0,
              match_1
            ];
            return f([
                        match,
                        undefined
                      ]);
          }));
  };
  var team1El = Core__Option.getOr(children[0], null);
  var team2El = Core__Option.getOr(children[1], null);
  var defaultView$1 = JsxRuntime.jsxs("div", {
        children: [
          JsxRuntime.jsx("div", {
                children: team1El,
                className: "grid grid-cols-1 gap-0 p-0 bg-white rounded-tl-lg rounded-tr-lg shadow truncate border-bottom border-solid border-b-black border-b-4"
              }),
          JsxRuntime.jsx("div", {
                children: team2El,
                className: "grid grid-cols-1 gap-0 p-0 bg-white shadow truncate"
              }),
          JsxRuntime.jsxs("div", {
                children: [
                  JsxRuntime.jsxs(React$1.Menu, {
                        children: [
                          JsxRuntime.jsxs(Dropdown.DropdownButton.make, {
                                children: [
                                  "...",
                                  JsxRuntime.jsx(Solid.ChevronDownIcon, {})
                                ],
                                outline: true
                              }),
                          JsxRuntime.jsx(Dropdown.DropdownMenu.make, {
                                children: Core__Option.getOr(Core__Option.map(props.onDelete, (function (onDelete) {
                                            return JsxRuntime.jsx(Dropdown.DropdownItem.make, {
                                                        children: t`Cancel`,
                                                        onClick: (function (e) {
                                                            e.stopPropagation();
                                                            onDelete();
                                                          })
                                                      });
                                          })), null)
                              })
                        ]
                      }),
                  JsxRuntime.jsx(UiAction.make, {
                        onClick: (function (e) {
                            e.stopPropagation();
                            setView(function (param) {
                                  return "SubmitMatch";
                                });
                          }),
                        className: "ml-3 flex-grow text-center mr-3 items-center text-3xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded",
                        children: t`Finished`
                      })
                ],
                className: "flex md:top-3 md:mt-0 justify-center"
              })
        ],
        className: "grid grid-cols-1 gap-2 p-0 border bg-white border-gray-200 rounded-lg shadow-sm"
      });
  var unratedMatch = Core__Result.flatMap(doublesMatch, (function (param) {
          var match = param[1];
          var match$1 = param[0];
          var match$2 = match$1[0].data;
          var match$3 = match$1[1].data;
          var match$4 = match[0].data;
          var match$5 = match[1].data;
          if (match$2 !== undefined && match$3 !== undefined && match$4 !== undefined && match$5 !== undefined) {
            return {
                    TAG: "Ok",
                    _0: undefined
                  };
          } else {
            return {
                    TAG: "Error",
                    _0: "TwoPlayersRequired"
                  };
          }
        }));
  var submitMatch = JsxRuntime.jsx("div", {
        children: JsxRuntime.jsx(JsxRuntime.Fragment, {
              children: Caml_option.some(JsxRuntime.jsxs("div", {
                        children: [
                          JsxRuntime.jsxs("div", {
                                children: [
                                  JsxRuntime.jsx("div", {
                                        children: team1.map(function (player) {
                                              return JsxRuntime.jsx(SortableSubmitMatch$PlayerView, {
                                                          player: player,
                                                          minRating: minRating,
                                                          maxRating: maxRating
                                                        }, player.id);
                                            }),
                                        className: "grid grid-cols-1 gap-0"
                                      }),
                                  JsxRuntime.jsx("div", {
                                        children: Core__Result.getOr(Core__Result.map(unratedMatch, (function () {
                                                    return JsxRuntime.jsx(Form.Input.make, {
                                                                onClick: (function (e) {
                                                                    e.stopPropagation();
                                                                    e.preventDefault();
                                                                  }),
                                                                className: "w-24 sm:w-32 md:w-48 flex-1 border-0 bg-transparent py-3.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-4xl sm:leading-6",
                                                                id: "scoreLeft",
                                                                type_: "text",
                                                                placeholder: t`Points`,
                                                                register: register("scoreLeft", undefined)
                                                              });
                                                  })), JsxRuntime.jsx(UiAction.make, {
                                                  onClick: (function (e) {
                                                      e.stopPropagation();
                                                      e.preventDefault();
                                                      handleWinner("Left");
                                                    }),
                                                  className: "ml-3 inline-flex items-center text-3xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded",
                                                  children: t`Winner`
                                                })),
                                        className: "flex bg-white z-10"
                                      })
                                ],
                                className: "flex relative p-0 justify-between rounded-tl-lg rounded-tr-lg bg-white shadow truncate",
                                onClick: (function (param) {
                                    setView(function (param) {
                                          return "Default";
                                        });
                                  })
                              }),
                          JsxRuntime.jsxs("div", {
                                children: [
                                  JsxRuntime.jsx("div", {
                                        children: team2.map(function (player) {
                                              return JsxRuntime.jsx(SortableSubmitMatch$PlayerView, {
                                                          player: player,
                                                          minRating: minRating,
                                                          maxRating: maxRating
                                                        }, player.id);
                                            }),
                                        className: "grid grid-cols-1 gap-0 truncate"
                                      }),
                                  JsxRuntime.jsx("div", {
                                        children: Core__Result.getOr(Core__Result.map(unratedMatch, (function () {
                                                    return JsxRuntime.jsx(Form.Input.make, {
                                                                onClick: (function (e) {
                                                                    e.stopPropagation();
                                                                    e.preventDefault();
                                                                  }),
                                                                className: "w-24 sm:w-32 md:w-48 flex-1 border-0 bg-transparent py-3.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-4xl sm:leading-6",
                                                                id: "scoreRight",
                                                                type_: "text",
                                                                placeholder: t`Points`,
                                                                register: register("scoreRight", undefined)
                                                              });
                                                  })), JsxRuntime.jsx(UiAction.make, {
                                                  onClick: (function (e) {
                                                      e.stopPropagation();
                                                      e.preventDefault();
                                                      handleWinner("Right");
                                                    }),
                                                  className: "ml-3 inline-flex items-center text-3xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded",
                                                  children: t`Winner`
                                                })),
                                        className: "flex bg-white z-10"
                                      })
                                ],
                                className: "flex relative p-0 justify-between bg-white shadow truncate",
                                onClick: (function (param) {
                                    setView(function (param) {
                                          return "Default";
                                        });
                                  })
                              }),
                          JsxRuntime.jsxs("div", {
                                children: [
                                  JsxRuntime.jsx(UiAction.make, {
                                        onClick: (function (param) {
                                            setView(function (param) {
                                                  return "Default";
                                                });
                                          }),
                                        className: "inline-flex items-center text-2xl bg-red-500 hover:bg-red-400 text-white font-bold py-2 px-4 border-b-4 border-red-700 hover:border-red-500 rounded",
                                        children: t`Go Back`
                                      }),
                                  Core__Result.getOr(Core__Result.map(unratedMatch, (function () {
                                              return JsxRuntime.jsx("input", {
                                                          className: "ml-3 inline-flex items-center text-2xl bg-blue-500 hover:bg-blue-400 text-white font-bold py-2 px-4 border-b-4 border-blue-700 hover:border-blue-500 rounded",
                                                          disabled: submitting,
                                                          type: "submit",
                                                          value: t`Submit Rated`
                                                        });
                                            })), null)
                                ],
                                className: "mt-3 flex md:top-3 md:mt-0 justify-center"
                              }),
                          JsxRuntime.jsx("div", {
                                children: JsxRuntime.jsx(React.Suspense, {
                                      children: Caml_option.some(JsxRuntime.jsx(SortableSubmitMatch$PredictionBar, {
                                                match: match
                                              })),
                                      fallback: Caml_option.some(JsxRuntime.jsx("div", {
                                                children: t`Loading`
                                              }))
                                    }),
                                className: "grid gap-0 col-span-1"
                              })
                        ],
                        className: "grid col-span-1 items-start gap-2 p-0 border bg-white border-gray-200 rounded-lg shadow-sm"
                      }))
            }),
        className: "grid col-span-1 items-start gap-2 md:gap-4"
      });
  var tmp;
  tmp = match$1[0] === "Default" ? defaultView$1 : submitMatch;
  return JsxRuntime.jsx("form", {
              children: JsxRuntime.jsx("div", {
                    children: tmp,
                    className: "grid grid-cols-1"
                  }),
              onSubmit: match$2.handleSubmit(function (extra) {
                    setSubmitting(function (param) {
                          return true;
                        });
                    if (extra.scoreLeft === extra.scoreRight) {
                      alert("No ties allowed");
                      return setSubmitting(function (param) {
                                  return false;
                                });
                    } else {
                      Core__Option.map(onComplete, (function (f) {
                              var winningSide = extra.scoreLeft > extra.scoreRight ? "Left" : "Right";
                              var score = winningSide === "Left" ? [
                                  extra.scoreLeft,
                                  extra.scoreRight
                                ] : [
                                  extra.scoreRight,
                                  extra.scoreLeft
                                ];
                              var match_0 = winningSide === "Left" ? team1 : team2;
                              var match_1 = winningSide === "Left" ? team2 : team1;
                              var match = [
                                match_0,
                                match_1
                              ];
                              var x = f([
                                    match,
                                    score
                                  ]);
                              return x.then(function () {
                                          setValue("scoreLeft", 0, undefined);
                                          setValue("scoreRight", 0, undefined);
                                          return Promise.resolve(setSubmitting(function (param) {
                                                          return false;
                                                        }));
                                        });
                            }));
                      return ;
                    }
                  })
            });
}

var make = SortableSubmitMatch;

export {
  PlayerView ,
  make ,
}
/*  Not a pure module */

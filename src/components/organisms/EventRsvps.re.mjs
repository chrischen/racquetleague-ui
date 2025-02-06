// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Caml_obj from "rescript/lib/es6/caml_obj.js";
import * as UiAction from "../atoms/UiAction.re.mjs";
import * as EventRsvp from "./EventRsvp.re.mjs";
import * as LoginLink from "../molecules/LoginLink.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as WarningAlert from "../molecules/WarningAlert.re.mjs";
import * as Core from "@linaria/core";
import * as FramerMotion from "framer-motion";
import * as RelayRuntime from "relay-runtime";
import * as ViewerRsvpStatus from "./ViewerRsvpStatus.re.mjs";
import * as ReactExperimental from "rescript-relay/src/ReactExperimental.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as AppContext from "../layouts/appContext";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as RescriptRelay_Mutation from "rescript-relay/src/RescriptRelay_Mutation.re.mjs";
import * as EventRsvps_user_graphql from "../../__generated__/EventRsvps_user_graphql.re.mjs";
import * as EventRsvps_event_graphql from "../../__generated__/EventRsvps_event_graphql.re.mjs";
import * as Solid from "@heroicons/react/24/solid";
import * as EventRsvpsJoinMutation_graphql from "../../__generated__/EventRsvpsJoinMutation_graphql.re.mjs";
import * as EventRsvpsRefetchQuery_graphql from "../../__generated__/EventRsvpsRefetchQuery_graphql.re.mjs";
import * as EventRsvpsLeaveMutation_graphql from "../../__generated__/EventRsvpsLeaveMutation_graphql.re.mjs";
import * as EventRsvpsCreateRatingMutation_graphql from "../../__generated__/EventRsvpsCreateRatingMutation_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

var getConnectionNodes = EventRsvps_event_graphql.Utils.getConnectionNodes;

var convertFragment = EventRsvps_event_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(EventRsvps_event_graphql.node, convertFragment, fRef);
}

var convertRefetchVariables = EventRsvpsRefetchQuery_graphql.Internal.convertVariables;

function usePagination(fRef) {
  return RescriptRelay_Fragment.usePaginationFragment(EventRsvps_event_graphql.node, fRef, convertFragment, convertRefetchVariables);
}

var convertFragment$1 = EventRsvps_user_graphql.Internal.convertFragment;

var convertVariables = EventRsvpsJoinMutation_graphql.Internal.convertVariables;

var convertResponse = EventRsvpsJoinMutation_graphql.Internal.convertResponse;

var convertWrapRawResponse = EventRsvpsJoinMutation_graphql.Internal.convertWrapRawResponse;

RescriptRelay_Mutation.commitMutation(convertVariables, EventRsvpsJoinMutation_graphql.node, convertResponse, convertWrapRawResponse);

var use$1 = RescriptRelay_Mutation.useMutation(convertVariables, EventRsvpsJoinMutation_graphql.node, convertResponse, convertWrapRawResponse);

var convertVariables$1 = EventRsvpsCreateRatingMutation_graphql.Internal.convertVariables;

var convertResponse$1 = EventRsvpsCreateRatingMutation_graphql.Internal.convertResponse;

var convertWrapRawResponse$1 = EventRsvpsCreateRatingMutation_graphql.Internal.convertWrapRawResponse;

RescriptRelay_Mutation.commitMutation(convertVariables$1, EventRsvpsCreateRatingMutation_graphql.node, convertResponse$1, convertWrapRawResponse$1);

var use$2 = RescriptRelay_Mutation.useMutation(convertVariables$1, EventRsvpsCreateRatingMutation_graphql.node, convertResponse$1, convertWrapRawResponse$1);

var convertVariables$2 = EventRsvpsLeaveMutation_graphql.Internal.convertVariables;

var convertResponse$2 = EventRsvpsLeaveMutation_graphql.Internal.convertResponse;

var convertWrapRawResponse$2 = EventRsvpsLeaveMutation_graphql.Internal.convertWrapRawResponse;

RescriptRelay_Mutation.commitMutation(convertVariables$2, EventRsvpsLeaveMutation_graphql.node, convertResponse$2, convertWrapRawResponse$2);

var use$3 = RescriptRelay_Mutation.useMutation(convertVariables$2, EventRsvpsLeaveMutation_graphql.node, convertResponse$2, convertWrapRawResponse$2);

function EventRsvps(props) {
  var $$event = props.event;
  var match = ReactExperimental.useTransition();
  var startTransition = match[1];
  var match$1 = usePagination($$event);
  var isLoadingNext = match$1.isLoadingNext;
  var hasNext = match$1.hasNext;
  var loadNext = match$1.loadNext;
  var match$2 = use($$event);
  var minRating = match$2.minRating;
  var maxRsvps = match$2.maxRsvps;
  var __id = match$2.__id;
  var viewer = Core__Option.map(props.user, (function (user) {
          return RescriptRelay_Fragment.useFragment(EventRsvps_user_graphql.node, convertFragment$1, user);
        }));
  var rsvps = getConnectionNodes(match$1.data.rsvps);
  var isWaitlist = function (count) {
    return Core__Option.isSome(Core__Option.flatMap(maxRsvps, (function (max) {
                      if (count >= max) {
                        return Caml_option.some(undefined);
                      }
                      
                    })));
  };
  var mainList = rsvps.filter(function (edge) {
        if (edge.listType === undefined) {
          return true;
        } else {
          return Caml_obj.equal(edge.listType, 0);
        }
      });
  var confirmedRsvps = mainList.filter(function (param, i) {
          return !isWaitlist(i);
        }).toSorted(function (a, b) {
        var userA = Core__Option.getOr(Core__Option.flatMap(a.rating, (function (rating) {
                    return rating.mu;
                  })), 0);
        var userB = Core__Option.getOr(Core__Option.flatMap(b.rating, (function (rating) {
                    return rating.mu;
                  })), 0);
        if (userA < userB) {
          return 1;
        } else {
          return -1;
        }
      });
  var waitlistRsvps = rsvps.filter(function (edge) {
          if (Caml_obj.notequal(edge.listType, 0)) {
            return edge.listType !== undefined;
          } else {
            return false;
          }
        }).concat(mainList.filter(function (param, i) {
            return isWaitlist(i);
          }));
  var onLoadMore = function (param) {
    startTransition(function () {
          loadNext(1, undefined);
        });
  };
  var match$3 = use$3();
  var commitMutationLeave = match$3[0];
  var match$4 = use$1();
  var commitMutationJoin = match$4[0];
  var match$5 = use$2();
  var commitMutationCreateRating = match$5[0];
  var match$6 = React.useState(function () {
        return false;
      });
  var setExpanded = match$6[1];
  var expanded = match$6[0];
  var viewerHasRsvp = Core__Option.getOr(Core__Option.flatMap(viewer, (function (viewer) {
              return Core__Option.map(rsvps.find(function (edge) {
                              return Core__Option.getOr(Core__Option.map(edge.user, (function (user) {
                                                return viewer.id === user.id;
                                              })), false);
                            }), (function (param) {
                            return true;
                          }));
            })), false);
  var viewerIsInEvent = Core__Option.getOr(Core__Option.flatMap(viewer, (function (viewer) {
              return Core__Option.map(Core__Array.findIndexOpt(confirmedRsvps, (function (edge) {
                                return Core__Option.getOr(Core__Option.map(edge.user, (function (user) {
                                                  return viewer.id === user.id;
                                                })), false);
                              })), (function (param) {
                            return true;
                          }));
            })), false);
  var viewerCanJoin = Core__Option.map(minRating, (function (minRating) {
          var rating = Core__Option.getOr(Core__Option.flatMap(viewer, (function (viewer) {
                      return Core__Option.flatMap(viewer.eventRating, (function (r) {
                                    return r.ordinal;
                                  }));
                    })), 0.0);
          return rating >= minRating;
        }));
  var onJoin = function (param) {
    var connectionId = RelayRuntime.ConnectionHandler.getConnectionID(__id, "EventRsvps_event_rsvps", undefined);
    commitMutationCreateRating(undefined, undefined, undefined, undefined, undefined, undefined, undefined);
    commitMutationJoin({
          connections: [connectionId],
          id: __id
        }, undefined, undefined, undefined, undefined, undefined, undefined);
  };
  var onLeave = function (param) {
    var connectionId = RelayRuntime.ConnectionHandler.getConnectionID(__id, "EventRsvps_event_rsvps", undefined);
    commitMutationLeave({
          connections: [connectionId],
          id: __id
        }, undefined, undefined, undefined, undefined, undefined, undefined);
  };
  var activitySlug = Core__Option.flatMap(match$2.activity, (function (a) {
          return a.slug;
        }));
  var spotsAvailable = Core__Option.map(maxRsvps, (function (max) {
          return Math.max(max - confirmedRsvps.length, 0) | 0;
        }));
  var waitlistCount = waitlistRsvps.length;
  var maxRating = Core__Array.reduce(rsvps, 0, (function (acc, next) {
          if (Core__Option.getOr(Core__Option.flatMap(next.rating, (function (r) {
                        return r.mu;
                      })), 0) > acc) {
            return Core__Option.getOr(Core__Option.flatMap(next.rating, (function (r) {
                              return r.mu;
                            })), 0);
          } else {
            return acc;
          }
        }));
  var joinButton;
  if (viewer !== undefined) {
    var exit = 0;
    if (viewerCanJoin !== undefined && !viewerCanJoin) {
      joinButton = JsxRuntime.jsxs("div", {
            children: [
              JsxRuntime.jsxs(WarningAlert.make, {
                    children: [
                      t`Required rating: ${Core__Option.getOr(minRating, 0.0).toFixed(2)}`,
                      JsxRuntime.jsx("br", {}),
                      t`Your rating ${Core__Option.getOr(Core__Option.flatMap(viewer, (function (viewer) {
                                    return Core__Option.flatMap(viewer.eventRating, (function (r) {
                                                  return r.ordinal;
                                                }));
                                  })), 0.0).toFixed(2)} is too low. You will be placed in the waitlist until the rating limit is lowered. Please join a JPL open event to boost your rating.`
                    ],
                    cta: "",
                    ctaClick: (function () {
                        
                      })
                  }),
              JsxRuntime.jsx("button", {
                    children: t`join event`,
                    className: "mt-2 w-full items-center justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600",
                    onClick: onJoin
                  })
            ],
            className: "text-center"
          });
    } else {
      exit = 1;
    }
    if (exit === 1) {
      joinButton = JsxRuntime.jsx("button", {
            children: t`join event`,
            className: "w-full items-center justify-center rounded-md bg-red-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-red-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600",
            onClick: onJoin
          });
    }
    
  } else {
    joinButton = JsxRuntime.jsxs("div", {
          children: [
            JsxRuntime.jsx("p", {
                  children: JsxRuntime.jsx("em", {
                        children: t`login to join the event`
                      })
                }),
            JsxRuntime.jsx(LoginLink.make, {
                  className: "mt-2 inline-block"
                }),
            JsxRuntime.jsx("button", {
                  children: t`join event`,
                  className: "mt-2 w-full items-center justify-center rounded-md bg-red-200 px-3 py-2 text-sm font-semibold text-white shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-red-600",
                  disabled: true
                })
          ],
          className: "text-center"
        });
  }
  var leaveButton = JsxRuntime.jsx("button", {
        children: t`leave event`,
        className: "inline-flex w-full items-center justify-center rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
        onClick: onLeave
      });
  var tmp;
  var exit$1 = 0;
  if (viewerCanJoin !== undefined && !viewerCanJoin) {
    tmp = null;
  } else {
    exit$1 = 1;
  }
  if (exit$1 === 1) {
    tmp = JsxRuntime.jsx(FramerMotion.motion.li, {
          className: "mt-4 flex w-full flex-none gap-x-4 px-6",
          style: {
            originX: 0.05,
            originY: 0.05
          },
          animate: {
            opacity: 1,
            scale: 1
          },
          initial: {
            opacity: 0,
            scale: 1.15
          },
          exit: {
            opacity: 0,
            scale: 1.15
          },
          children: Caml_option.some(JsxRuntime.jsx(ViewerRsvpStatus.make, {
                    onJoin: onJoin,
                    onLeave: onLeave,
                    joined: viewerHasRsvp
                  }))
        }, "viewer");
  }
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsx("h2", {
                      children: t`attendees`,
                      className: "sr-only"
                    }),
                JsxRuntime.jsxs("div", {
                      children: [
                        viewerHasRsvp ? (
                            viewerIsInEvent ? JsxRuntime.jsx("div", {
                                    children: JsxRuntime.jsxs("div", {
                                          children: [
                                            JsxRuntime.jsx("div", {
                                                  children: JsxRuntime.jsx(Solid.ExclamationTriangleIcon, {
                                                        className: "h-5 w-5 text-green-400",
                                                        "aria-hidden": "true"
                                                      }),
                                                  className: "flex-shrink-0"
                                                }),
                                            JsxRuntime.jsx("div", {
                                                  children: JsxRuntime.jsx("p", {
                                                        children: t`you're going :)`,
                                                        className: "text-sm text-green-700"
                                                      }),
                                                  className: "ml-3"
                                                })
                                          ],
                                          className: "flex"
                                        }),
                                    className: "border-l-4 border-green-400 bg-green-50 p-4 mb-2"
                                  }) : JsxRuntime.jsx("div", {
                                    children: JsxRuntime.jsxs("div", {
                                          children: [
                                            JsxRuntime.jsx("div", {
                                                  children: JsxRuntime.jsx(Solid.ExclamationTriangleIcon, {
                                                        className: "h-5 w-5 text-yellow-400",
                                                        "aria-hidden": "true"
                                                      }),
                                                  className: "flex-shrink-0"
                                                }),
                                            JsxRuntime.jsx("div", {
                                                  children: JsxRuntime.jsx("p", {
                                                        children: t`you're waitlisted :(`,
                                                        className: "text-sm text-yellow-700"
                                                      }),
                                                  className: "ml-3"
                                                })
                                          ],
                                          className: "flex"
                                        }),
                                    className: "border-l-4 border-yellow-400 bg-yellow-50 p-4 mb-2"
                                  })
                          ) : null,
                        Core__Option.getOr(Core__Option.map(spotsAvailable, (function (count) {
                                    if (count !== 0) {
                                      if (viewerHasRsvp) {
                                        return leaveButton;
                                      } else {
                                        return joinButton;
                                      }
                                    } else if (viewerHasRsvp) {
                                      return leaveButton;
                                    } else {
                                      return joinButton;
                                    }
                                  })), viewerHasRsvp ? leaveButton : joinButton)
                      ],
                      className: "flex-auto p-6 pt-4"
                    }),
                JsxRuntime.jsxs("dl", {
                      children: [
                        JsxRuntime.jsxs("div", {
                              children: [
                                JsxRuntime.jsx("dt", {
                                      children: t`confirmed`,
                                      className: "text-sm font-semibold leading-6 text-gray-900"
                                    }),
                                JsxRuntime.jsx("dd", {
                                      children: maxRsvps !== undefined ? JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                              children: [
                                                Math.min(confirmedRsvps.length, maxRsvps).toString() + " / " + maxRsvps.toString() + " ",
                                                plural(maxRsvps, {
                                                      one: "player",
                                                      other: "players"
                                                    })
                                              ]
                                            }) : JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                              children: [
                                                confirmedRsvps.length.toString() + " ",
                                                plural(confirmedRsvps.length, {
                                                      one: "player",
                                                      other: "players"
                                                    })
                                              ]
                                            }),
                                      className: "mt-1 text-base font-semibold leading-6 text-gray-900"
                                    })
                              ],
                              className: "flex-auto pl-6"
                            }),
                        JsxRuntime.jsxs("div", {
                              children: [
                                JsxRuntime.jsx("dt", {
                                      children: "Status",
                                      className: "sr-only"
                                    }),
                                Core__Option.getOr(Core__Option.map(spotsAvailable, (function (count) {
                                            if (count !== 0) {
                                              return JsxRuntime.jsx("dd", {
                                                          children: t`spots available`,
                                                          className: "rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-600 ring-1 ring-inset ring-green-600/20"
                                                        });
                                            } else {
                                              return JsxRuntime.jsx("dd", {
                                                          children: t`waitlist`,
                                                          className: "rounded-md bg-yellow-50 px-2 py-1 text-xs font-medium text-yellow-600 ring-1 ring-inset ring-yellow-600/20"
                                                        });
                                            }
                                          })), JsxRuntime.jsx("dd", {
                                          children: t`spots available`,
                                          className: "rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-600 ring-1 ring-inset ring-green-600/20"
                                        }))
                              ],
                              className: "flex-none self-end px-6 pt-4"
                            }),
                        JsxRuntime.jsx("div", {
                              children: JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                    children: [
                                      JsxRuntime.jsxs("ul", {
                                            children: [
                                              JsxRuntime.jsx(FramerMotion.AnimatePresence, {
                                                    children: confirmedRsvps.length !== 0 ? confirmedRsvps.map(function (edge) {
                                                            return JsxRuntime.jsx(EventRsvp.make, {
                                                                        rsvp: edge.fragmentRefs,
                                                                        viewer: viewer,
                                                                        activitySlug: activitySlug,
                                                                        maxRating: maxRating
                                                                      });
                                                          }) : t`no players yet`
                                                  }),
                                              tmp
                                            ],
                                            className: Core.cx(expanded ? "" : "hidden sm:block")
                                          }),
                                      JsxRuntime.jsx("em", {
                                            children: isLoadingNext ? "..." : (
                                                hasNext ? JsxRuntime.jsx("a", {
                                                        children: t`load More`,
                                                        onClick: onLoadMore
                                                      }) : null
                                              )
                                          })
                                    ]
                                  }),
                              className: "mt-4 w-full flex flex-col gap-x-4 border-t border-gray-900/5 px-6 pt-4"
                            }),
                        JsxRuntime.jsxs("div", {
                              children: [
                                JsxRuntime.jsx("div", {
                                      children: JsxRuntime.jsxs("div", {
                                            children: [
                                              JsxRuntime.jsx("dt", {
                                                    children: t`waitlist`,
                                                    className: "text-sm font-semibold leading-6 text-gray-900"
                                                  }),
                                              JsxRuntime.jsxs("dd", {
                                                    children: [
                                                      waitlistCount.toString() + " ",
                                                      plural(waitlistCount, {
                                                            one: "player",
                                                            other: "players"
                                                          })
                                                    ],
                                                    className: "mt-1 text-base font-semibold leading-6 text-gray-900"
                                                  })
                                            ],
                                            className: "flex-auto"
                                          }),
                                      className: "mt-4 border-t border-gray-900/5 pl-6 pt-4"
                                    }),
                                JsxRuntime.jsx("div", {
                                      children: JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                            children: [
                                              JsxRuntime.jsx("ul", {
                                                    children: JsxRuntime.jsx(FramerMotion.AnimatePresence, {
                                                          children: waitlistRsvps.length !== 0 ? waitlistRsvps.map(function (edge) {
                                                                  return JsxRuntime.jsx(EventRsvp.make, {
                                                                              rsvp: edge.fragmentRefs,
                                                                              viewer: viewer,
                                                                              activitySlug: activitySlug,
                                                                              maxRating: maxRating
                                                                            });
                                                                }) : t`no players yet`
                                                        }),
                                                    className: ""
                                                  }),
                                              JsxRuntime.jsx("em", {
                                                    children: isLoadingNext ? "..." : (
                                                        hasNext ? JsxRuntime.jsx("a", {
                                                                children: t`load More`,
                                                                onClick: onLoadMore
                                                              }) : null
                                                      )
                                                  })
                                            ]
                                          }),
                                      className: "mt-4 flex w-full flex-none gap-x-4 border-t border-gray-900/5 px-6 py-4"
                                    })
                              ],
                              className: Core.cx(expanded ? "" : "hidden sm:block")
                            })
                      ],
                      className: "flex flex-wrap"
                    }),
                JsxRuntime.jsxs(UiAction.make, {
                      onClick: (function (param) {
                          setExpanded(function (expanded) {
                                return !expanded;
                              });
                        }),
                      className: "sm:hidden p-3 w-full flex flex-col items-center hover:bg-gray-100",
                      children: [
                        expanded ? null : JsxRuntime.jsx(Solid.UsersIcon, {
                                className: "inline w-5 h-5"
                              }),
                        expanded ? JsxRuntime.jsx(Solid.ChevronUpIcon, {
                                className: "inline w-5 h-5"
                              }) : JsxRuntime.jsx(Solid.ChevronDownIcon, {
                                className: "inline w-5 h-5"
                              })
                      ]
                    })
              ],
              className: "rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5 flex flex-col"
            });
}

var make = EventRsvps;

export {
  make ,
}
/*  Not a pure module */

// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as GlobalQuery from "../shared/GlobalQuery.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as EventRsvpUser from "./EventRsvpUser.re.mjs";
import * as FramerMotion from "framer-motion";
import * as RelayRuntime from "relay-runtime";
import * as ViewerRsvpStatus from "./ViewerRsvpStatus.re.mjs";
import * as ReactExperimental from "rescript-relay/src/ReactExperimental.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as AppContext from "../layouts/appContext";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as RescriptRelay_Mutation from "rescript-relay/src/RescriptRelay_Mutation.re.mjs";
import * as EventRsvps_event_graphql from "../../__generated__/EventRsvps_event_graphql.re.mjs";
import * as EventRsvpsJoinMutation_graphql from "../../__generated__/EventRsvpsJoinMutation_graphql.re.mjs";
import * as EventRsvpsRefetchQuery_graphql from "../../__generated__/EventRsvpsRefetchQuery_graphql.re.mjs";
import * as EventRsvpsLeaveMutation_graphql from "../../__generated__/EventRsvpsLeaveMutation_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

var getConnectionNodes = EventRsvps_event_graphql.Utils.getConnectionNodes;

var convertFragment = EventRsvps_event_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(EventRsvps_event_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, EventRsvps_event_graphql.node, convertFragment);
}

var makeRefetchVariables = EventRsvpsRefetchQuery_graphql.Types.makeRefetchVariables;

var convertRefetchVariables = EventRsvpsRefetchQuery_graphql.Internal.convertVariables;

function useRefetchable(fRef) {
  return RescriptRelay_Fragment.useRefetchableFragment(EventRsvps_event_graphql.node, convertFragment, convertRefetchVariables, fRef);
}

function usePagination(fRef) {
  return RescriptRelay_Fragment.usePaginationFragment(EventRsvps_event_graphql.node, fRef, convertFragment, convertRefetchVariables);
}

function useBlockingPagination(fRef) {
  return RescriptRelay_Fragment.useBlockingPaginationFragment(EventRsvps_event_graphql.node, fRef, convertFragment, convertRefetchVariables);
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

var convertVariables = EventRsvpsJoinMutation_graphql.Internal.convertVariables;

var convertResponse = EventRsvpsJoinMutation_graphql.Internal.convertResponse;

var convertWrapRawResponse = EventRsvpsJoinMutation_graphql.Internal.convertWrapRawResponse;

var commitMutation = RescriptRelay_Mutation.commitMutation(convertVariables, EventRsvpsJoinMutation_graphql.node, convertResponse, convertWrapRawResponse);

var use$1 = RescriptRelay_Mutation.useMutation(convertVariables, EventRsvpsJoinMutation_graphql.node, convertResponse, convertWrapRawResponse);

var EventRsvpsJoinMutation = {
  Operation: undefined,
  Types: undefined,
  convertVariables: convertVariables,
  convertResponse: convertResponse,
  convertWrapRawResponse: convertWrapRawResponse,
  commitMutation: commitMutation,
  use: use$1
};

var convertVariables$1 = EventRsvpsLeaveMutation_graphql.Internal.convertVariables;

var convertResponse$1 = EventRsvpsLeaveMutation_graphql.Internal.convertResponse;

var convertWrapRawResponse$1 = EventRsvpsLeaveMutation_graphql.Internal.convertWrapRawResponse;

var commitMutation$1 = RescriptRelay_Mutation.commitMutation(convertVariables$1, EventRsvpsLeaveMutation_graphql.node, convertResponse$1, convertWrapRawResponse$1);

var use$2 = RescriptRelay_Mutation.useMutation(convertVariables$1, EventRsvpsLeaveMutation_graphql.node, convertResponse$1, convertWrapRawResponse$1);

var EventRsvpsLeaveMutation = {
  Operation: undefined,
  Types: undefined,
  convertVariables: convertVariables$1,
  convertResponse: convertResponse$1,
  convertWrapRawResponse: convertWrapRawResponse$1,
  commitMutation: commitMutation$1,
  use: use$2
};

var sessionContext = AppContext.SessionContext;

function EventRsvps(props) {
  var $$event = props.event;
  var match = ReactExperimental.useTransition();
  var startTransition = match[1];
  var match$1 = usePagination($$event);
  var isLoadingNext = match$1.isLoadingNext;
  var hasNext = match$1.hasNext;
  var loadNext = match$1.loadNext;
  var rsvps = getConnectionNodes(match$1.data.rsvps);
  var onLoadMore = function (param) {
    startTransition(function () {
          loadNext(1, undefined);
        });
  };
  var match$2 = use($$event);
  var maxRsvps = match$2.maxRsvps;
  var __id = match$2.__id;
  var match$3 = use$2();
  var commitMutationLeave = match$3[0];
  var match$4 = use$1();
  var commitMutationJoin = match$4[0];
  var viewer = GlobalQuery.useViewer();
  var viewerHasRsvp = Core__Option.getOr(Core__Option.flatMap(viewer.user, (function (viewer) {
              return Core__Option.map(rsvps.find(function (edge) {
                              return Core__Option.getOr(Core__Option.map(edge.user, (function (user) {
                                                return viewer.id === user.id;
                                              })), false);
                            }), (function (param) {
                            return true;
                          }));
            })), false);
  var onJoin = function (param) {
    var connectionId = RelayRuntime.ConnectionHandler.getConnectionID(__id, "EventRsvps_event_rsvps", undefined);
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
  var spotsAvailable = Core__Option.map(maxRsvps, (function (max) {
          return Math.max(max - rsvps.length, 0) | 0;
        }));
  var isWaitlist = function (count) {
    return Core__Option.isSome(Core__Option.flatMap(maxRsvps, (function (max) {
                      if (count > max) {
                        return Caml_option.some(undefined);
                      }
                      
                    })));
  };
  var waitlistCount = Math.max(rsvps.length - Core__Option.getOr(Core__Option.map(maxRsvps, (function (prim) {
                  return prim;
                })), 0), 0) | 0;
  return JsxRuntime.jsx("div", {
              children: JsxRuntime.jsxs("dl", {
                    children: [
                      JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsx("dt", {
                                    children: t`confirmed`,
                                    className: "text-sm font-semibold leading-6 text-gray-900"
                                  }),
                              JsxRuntime.jsxs("dd", {
                                    children: [
                                      rsvps.length.toString(undefined) + " ",
                                      plural(rsvps.length, {
                                            one: "player",
                                            other: "players"
                                          })
                                    ],
                                    className: "mt-1 text-base font-semibold leading-6 text-gray-900"
                                  })
                            ],
                            className: "flex-auto pl-6 pt-6"
                          }),
                      JsxRuntime.jsxs("div", {
                            children: [
                              JsxRuntime.jsx("dt", {
                                    children: "Status",
                                    className: "sr-only"
                                  }),
                              Core__Option.getOr(Core__Option.map(spotsAvailable, (function (count) {
                                          if (count !== 0) {
                                            return JsxRuntime.jsxs("dd", {
                                                        children: [
                                                          count.toString(undefined),
                                                          " ",
                                                          plural(waitlistCount, {
                                                                one: "spot available",
                                                                other: "spots available"
                                                              })
                                                        ],
                                                        className: "rounded-md bg-green-50 px-2 py-1 text-xs font-medium text-green-600 ring-1 ring-inset ring-green-600/20"
                                                      });
                                          } else {
                                            return JsxRuntime.jsx("dd", {
                                                        children: t`join waitlist`,
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
                                                  children: rsvps.length !== 0 ? rsvps.map(function (edge, i) {
                                                          return Core__Option.getOr(Core__Option.map(edge.user, (function (user) {
                                                                            if (isWaitlist(i)) {
                                                                              return null;
                                                                            } else {
                                                                              return JsxRuntime.jsxs(FramerMotion.motion.li, {
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
                                                                                          children: [
                                                                                            JsxRuntime.jsx("div", {
                                                                                                  children: JsxRuntime.jsx("span", {
                                                                                                        children: t`Player`,
                                                                                                        className: "sr-only"
                                                                                                      }),
                                                                                                  className: "flex-none"
                                                                                                }),
                                                                                            JsxRuntime.jsx("div", {
                                                                                                  children: JsxRuntime.jsx(EventRsvpUser.make, {
                                                                                                        user: user.fragmentRefs,
                                                                                                        highlight: Core__Option.getOr(Core__Option.map(viewer.user, (function (viewer) {
                                                                                                                    return viewer.id === user.id;
                                                                                                                  })), false)
                                                                                                      }),
                                                                                                  className: "text-sm font-medium leading-6 text-gray-900"
                                                                                                })
                                                                                          ]
                                                                                        }, user.id);
                                                                            }
                                                                          })), null);
                                                        }) : t`no players yet`
                                                }),
                                            JsxRuntime.jsx(FramerMotion.motion.li, {
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
                                                }, "viewer")
                                          ],
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
                            className: "mt-6 flex w-full flex-none gap-x-4 border-t border-gray-900/5 px-6 pt-6"
                          }),
                      JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsxs("div", {
                                  children: [
                                    JsxRuntime.jsx("dt", {
                                          children: t`waitlist`,
                                          className: "text-sm font-semibold leading-6 text-gray-900"
                                        }),
                                    JsxRuntime.jsxs("dd", {
                                          children: [
                                            waitlistCount.toString(undefined) + " ",
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
                            className: "mt-6 border-t border-gray-900/5 pl-6 pt-6"
                          }),
                      JsxRuntime.jsx("div", {
                            children: JsxRuntime.jsxs(JsxRuntime.Fragment, {
                                  children: [
                                    JsxRuntime.jsx("ul", {
                                          children: JsxRuntime.jsx(FramerMotion.AnimatePresence, {
                                                children: rsvps.length !== 0 ? rsvps.map(function (edge, i) {
                                                        return Core__Option.getOr(Core__Option.map(edge.user, (function (user) {
                                                                          if (isWaitlist(i)) {
                                                                            return JsxRuntime.jsxs(FramerMotion.motion.li, {
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
                                                                                        children: [
                                                                                          JsxRuntime.jsx("div", {
                                                                                                children: JsxRuntime.jsx("span", {
                                                                                                      children: t`Player`,
                                                                                                      className: "sr-only"
                                                                                                    }),
                                                                                                className: "flex-none"
                                                                                              }),
                                                                                          JsxRuntime.jsx("div", {
                                                                                                children: JsxRuntime.jsx(EventRsvpUser.make, {
                                                                                                      user: user.fragmentRefs,
                                                                                                      highlight: Core__Option.getOr(Core__Option.map(viewer.user, (function (viewer) {
                                                                                                                  return viewer.id === user.id;
                                                                                                                })), false)
                                                                                                    }),
                                                                                                className: "text-sm font-medium leading-6 text-gray-900"
                                                                                              })
                                                                                        ]
                                                                                      }, user.id);
                                                                          } else {
                                                                            return null;
                                                                          }
                                                                        })), null);
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
                            className: "mt-6 flex w-full flex-none gap-x-4 border-t border-gray-900/5 p-6"
                          })
                    ],
                    className: "flex flex-wrap"
                  }),
              className: "rounded-lg bg-gray-50 shadow-sm ring-1 ring-gray-900/5"
            });
}

var make = EventRsvps;

var $$default = EventRsvps;

export {
  Fragment ,
  EventRsvpsJoinMutation ,
  EventRsvpsLeaveMutation ,
  sessionContext ,
  make ,
  $$default as default,
}
/*  Not a pure module */

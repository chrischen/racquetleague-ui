// Generated by ReScript, PLEASE EDIT WITH CARE

import Zod from "zod";
import * as Form from "../molecules/forms/Form.re.mjs";
import * as Grid from "../vanillaui/atoms/Grid.re.mjs";
import * as React from "react";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as FormSection from "../molecules/forms/FormSection.re.mjs";
import * as Core from "@lingui/core";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as Core$1 from "@linaria/core";
import * as FramerMotion from "framer-motion";
import * as RelayRuntime from "relay-runtime";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactHookForm from "react-hook-form";
import * as ReactRouterDom from "react-router-dom";
import * as React$1 from "@headlessui/react";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as AppContext from "../layouts/appContext";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as RescriptRelay_Mutation from "rescript-relay/src/RescriptRelay_Mutation.re.mjs";
import * as Zod$1 from "@hookform/resolvers/zod";
import * as CreateClubEventsForm_club_graphql from "../../__generated__/CreateClubEventsForm_club_graphql.re.mjs";
import * as CreateClubEventsForm_query_graphql from "../../__generated__/CreateClubEventsForm_query_graphql.re.mjs";
import * as CreateClubEventsFormMutation_graphql from "../../__generated__/CreateClubEventsFormMutation_graphql.re.mjs";
import * as CreateClubEventsFormPreviewQuery_graphql from "../../__generated__/CreateClubEventsFormPreviewQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var convertVariables = CreateClubEventsFormMutation_graphql.Internal.convertVariables;

var convertResponse = CreateClubEventsFormMutation_graphql.Internal.convertResponse;

var convertWrapRawResponse = CreateClubEventsFormMutation_graphql.Internal.convertWrapRawResponse;

RescriptRelay_Mutation.commitMutation(convertVariables, CreateClubEventsFormMutation_graphql.node, convertResponse, convertWrapRawResponse);

var use = RescriptRelay_Mutation.useMutation(convertVariables, CreateClubEventsFormMutation_graphql.node, convertResponse, convertWrapRawResponse);

var convertFragment = CreateClubEventsForm_club_graphql.Internal.convertFragment;

function use$1(fRef) {
  return RescriptRelay_Fragment.useFragment(CreateClubEventsForm_club_graphql.node, convertFragment, fRef);
}

var convertFragment$1 = CreateClubEventsForm_query_graphql.Internal.convertFragment;

function use$2(fRef) {
  return RescriptRelay_Fragment.useFragment(CreateClubEventsForm_query_graphql.node, convertFragment$1, fRef);
}

var schema = Zod.object({
      input: Zod.string({
              required_error: t`input is required`
            }).min(1),
      activity: Zod.string({
            required_error: t`activity is required`
          }),
      listed: Zod.boolean({})
    });

var convertVariables$1 = CreateClubEventsFormPreviewQuery_graphql.Internal.convertVariables;

var convertResponse$1 = CreateClubEventsFormPreviewQuery_graphql.Internal.convertResponse;

var use$3 = RescriptRelay_Query.useQuery(convertVariables$1, CreateClubEventsFormPreviewQuery_graphql.node, convertResponse$1);

RescriptRelay_Query.useLoader(convertVariables$1, CreateClubEventsFormPreviewQuery_graphql.node, (function (prim) {
        return prim;
      }));

RescriptRelay_Query.usePreloaded(CreateClubEventsFormPreviewQuery_graphql.node, convertResponse$1, (function (prim) {
        return prim;
      }));

RescriptRelay_Query.$$fetch(CreateClubEventsFormPreviewQuery_graphql.node, convertResponse$1, convertVariables$1);

RescriptRelay_Query.fetchPromised(CreateClubEventsFormPreviewQuery_graphql.node, convertResponse$1, convertVariables$1);

RescriptRelay_Query.retain(CreateClubEventsFormPreviewQuery_graphql.node, convertVariables$1);

function CreateClubEventsForm$ParseEventsPreview(props) {
  var preview = use$3({
        input: props.input
      }, undefined, undefined, undefined);
  return JsxRuntime.jsx(Form.TextArea.make, {
              label: t`events preview`,
              id: "eventsPreview",
              rows: 10,
              value: preview.parseBulkEvents,
              disabled: true
            });
}

function CreateClubEventsForm(props) {
  var match = React.useState(function () {
        
      });
  var setQueryPreview = match[1];
  var queryPreview = match[0];
  var query = use$2(props.query);
  var club = use$1(props.club);
  var match$1 = use();
  var commitMutationCreate = match$1[0];
  var navigate = ReactRouterDom.useNavigate();
  var match$2 = ReactHookForm.useForm({
        resolver: Caml_option.some(Zod$1.zodResolver(schema)),
        defaultValues: {
          listed: false
        }
      });
  var setValue = match$2.setValue;
  var formState = match$2.formState;
  var watch = match$2.watch;
  var handleSubmit = match$2.handleSubmit;
  var register = match$2.register;
  var listed = Core__Option.getOr(Core__Option.map(watch("listed"), (function (listed) {
              if (!Array.isArray(listed) && (listed === null || typeof listed !== "object") && typeof listed !== "string" && typeof listed !== "number" && typeof listed !== "boolean" || typeof listed !== "boolean") {
                return false;
              } else {
                return listed;
              }
            })), false);
  var eventsInput = Core__Option.getOr(Core__Option.map(watch("input"), (function (input) {
              if (!Array.isArray(input) && (input === null || typeof input !== "object") && typeof input !== "string" && typeof input !== "number" && typeof input !== "boolean" || typeof input !== "string") {
                return "";
              } else {
                return input;
              }
            })), "");
  var onSubmit = function (data) {
    var connectionId = RelayRuntime.ConnectionHandler.getConnectionID("client:root", "EventsListFragment_events", undefined);
    commitMutationCreate({
          connections: [connectionId],
          input: {
            activityId: data.activity,
            clubId: club.id,
            input: data.input,
            listed: data.listed
          }
        }, undefined, undefined, undefined, (function (response, _errors) {
            Core__Option.map(response.createEvents.events, (function (param) {
                    navigate(Core__Option.getOr(Core__Option.map(club.slug, (function (slug) {
                                    return "/clubs/" + slug;
                                  })), "/"), undefined);
                  }));
          }), undefined, undefined);
  };
  return JsxRuntime.jsx(FramerMotion.motion.div, {
              style: {
                opacity: 0,
                y: -50
              },
              animate: {
                opacity: 1,
                scale: 1,
                y: 0.00
              },
              initial: {
                opacity: 0,
                scale: 1,
                y: -50
              },
              exit: {
                opacity: 0,
                scale: 1,
                y: -50
              },
              children: Caml_option.some(JsxRuntime.jsx(WaitForMessages.make, {
                        children: (function () {
                            var match = formState.errors.input;
                            var tmp;
                            if (match !== undefined) {
                              var message = match.message;
                              tmp = message !== undefined ? message : "";
                            } else {
                              tmp = "";
                            }
                            var match$1 = formState.errors.activity;
                            var tmp$1;
                            if (match$1 !== undefined) {
                              var message$1 = match$1.message;
                              tmp$1 = message$1 !== undefined ? message$1 : "";
                            } else {
                              tmp$1 = "";
                            }
                            return JsxRuntime.jsx(JsxRuntime.Fragment, {
                                        children: Caml_option.some(JsxRuntime.jsx(Grid.make, {
                                                  className: "grid-cols-1",
                                                  children: JsxRuntime.jsxs("form", {
                                                        children: [
                                                          JsxRuntime.jsx(FormSection.make, {
                                                                title: t`${Core__Option.getOr(club.name, "?")} event details`,
                                                                description: Caml_option.some(t`create multiple events at one time`),
                                                                children: JsxRuntime.jsxs("div", {
                                                                      children: [
                                                                        JsxRuntime.jsxs("div", {
                                                                              children: [
                                                                                JsxRuntime.jsx(Form.TextArea.make, {
                                                                                      label: t`events`,
                                                                                      name: "input",
                                                                                      id: "input",
                                                                                      hint: Caml_option.some(t`type your events here`),
                                                                                      rows: 10,
                                                                                      register: register("input", undefined)
                                                                                    }),
                                                                                JsxRuntime.jsx("p", {
                                                                                      children: tmp
                                                                                    }),
                                                                                JsxRuntime.jsx("button", {
                                                                                      children: t`preview events`,
                                                                                      className: "rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
                                                                                      type: "button",
                                                                                      onClick: (function (e) {
                                                                                          e.preventDefault();
                                                                                          setQueryPreview(function (param) {
                                                                                                return eventsInput;
                                                                                              });
                                                                                        })
                                                                                    }),
                                                                                Core__Option.getOr(Core__Option.map(queryPreview, (function (preview) {
                                                                                            return JsxRuntime.jsx(CreateClubEventsForm$ParseEventsPreview, {
                                                                                                        input: preview
                                                                                                      });
                                                                                          })), null)
                                                                              ],
                                                                              className: "sm:col-span-4 md:col-span-3"
                                                                            }),
                                                                        JsxRuntime.jsxs("div", {
                                                                              children: [
                                                                                JsxRuntime.jsx(Form.Select.make, {
                                                                                      label: t`activity`,
                                                                                      name: "activity",
                                                                                      id: "activity",
                                                                                      options: query.activities.map(function (activity) {
                                                                                            return [
                                                                                                    Core.i18n._(Core__Option.getOr(activity.name, "---")),
                                                                                                    activity.id
                                                                                                  ];
                                                                                          }),
                                                                                      register: register("activity", undefined)
                                                                                    }),
                                                                                JsxRuntime.jsx("p", {
                                                                                      children: tmp$1
                                                                                    })
                                                                              ],
                                                                              className: "sm:col-span-2 md:col-span-3 lg:col-span-2 lg:max-w-lg"
                                                                            }),
                                                                        JsxRuntime.jsx("div", {
                                                                              children: JsxRuntime.jsxs(React$1.Switch.Group, {
                                                                                    as: "div",
                                                                                    className: "flex items-center",
                                                                                    children: [
                                                                                      JsxRuntime.jsx(React$1.Switch, {
                                                                                            className: Core$1.cx(listed ? "bg-indigo-600" : "bg-gray-200", "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2"),
                                                                                            children: JsxRuntime.jsx("span", {
                                                                                                  "aria-hidden": true,
                                                                                                  className: Core$1.cx(listed ? "translate-x-5" : "translate-x-0", "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out")
                                                                                                }),
                                                                                            checked: listed,
                                                                                            onChange: (function (param) {
                                                                                                setValue("listed", !listed, undefined);
                                                                                              })
                                                                                          }),
                                                                                      JsxRuntime.jsxs(React$1.Switch.Label, {
                                                                                            as: "span",
                                                                                            className: "ml-3 text-sm",
                                                                                            children: [
                                                                                              JsxRuntime.jsx("span", {
                                                                                                    children: t`list publicly`,
                                                                                                    className: "font-medium text-gray-900"
                                                                                                  }),
                                                                                              " ",
                                                                                              JsxRuntime.jsx("span", {
                                                                                                    children: t`show your event publicly on our home page. Otherwise, only people with a link to your event will be able to find it.`,
                                                                                                    className: "text-gray-500"
                                                                                                  })
                                                                                            ]
                                                                                          })
                                                                                    ]
                                                                                  }),
                                                                              className: "col-span-full"
                                                                            })
                                                                      ],
                                                                      className: "mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6"
                                                                    })
                                                              }),
                                                          JsxRuntime.jsx(Form.Footer.make, {})
                                                        ],
                                                        onSubmit: handleSubmit(onSubmit)
                                                      })
                                                }))
                                      });
                          })
                      }))
            });
}

t({
      id: "Badminton"
    });

t({
      id: "Table Tennis"
    });

t({
      id: "Pickleball"
    });

t({
      id: "Futsal"
    });

t({
      id: "Basketball"
    });

t({
      id: "Volleyball"
    });

var make = CreateClubEventsForm;

export {
  make ,
}
/*  Not a pure module */

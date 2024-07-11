// Generated by ReScript, PLEASE EDIT WITH CARE

import Zod from "zod";
import * as Form from "../molecules/forms/Form.re.mjs";
import * as Grid from "../vanillaui/atoms/Grid.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as FormSection from "../molecules/forms/FormSection.re.mjs";
import * as Core from "@lingui/core";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as RelayRuntime from "relay-runtime";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactHookForm from "react-hook-form";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";
import * as JsxRuntime from "react/jsx-runtime";
import * as AppContext from "../layouts/appContext";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as RescriptRelay_Mutation from "rescript-relay/src/RescriptRelay_Mutation.re.mjs";
import * as Zod$1 from "@hookform/resolvers/zod";
import * as CreateClubFormMutation_graphql from "../../__generated__/CreateClubFormMutation_graphql.re.mjs";
import * as CreateClubForm_activities_graphql from "../../__generated__/CreateClubForm_activities_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

function ts(prim0, prim1) {
  return Caml_splice_call.spliceApply(t, [
              prim0,
              prim1
            ]);
}

var convertFragment = CreateClubForm_activities_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(CreateClubForm_activities_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, CreateClubForm_activities_graphql.node, convertFragment);
}

var ActivitiesFragment = {
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment,
  use: use,
  useOpt: useOpt
};

var convertVariables = CreateClubFormMutation_graphql.Internal.convertVariables;

var convertResponse = CreateClubFormMutation_graphql.Internal.convertResponse;

var convertWrapRawResponse = CreateClubFormMutation_graphql.Internal.convertWrapRawResponse;

var commitMutation = RescriptRelay_Mutation.commitMutation(convertVariables, CreateClubFormMutation_graphql.node, convertResponse, convertWrapRawResponse);

var use$1 = RescriptRelay_Mutation.useMutation(convertVariables, CreateClubFormMutation_graphql.node, convertResponse, convertWrapRawResponse);

var Mutation = {
  Operation: undefined,
  Types: undefined,
  convertVariables: convertVariables,
  convertResponse: convertResponse,
  convertWrapRawResponse: convertWrapRawResponse,
  commitMutation: commitMutation,
  use: use$1
};

var sessionContext = AppContext.SessionContext;

var ControllerOfInputs = {};

var schema = Zod.object({
      name: Zod.string({
              required_error: t`name is required`
            }).min(1),
      slug: Zod.string({
              required_error: t`url slug is required`
            }).min(1),
      activity: Zod.string({
              required_error: t`main activity is required`
            }).min(1),
      description: Zod.string({}).optional()
    });

function CreateClubForm(props) {
  var onCreated = props.onCreated;
  var onCancel = props.onCancel;
  var connectionId = props.connectionId;
  var match = use$1();
  var commitMutationCreate = match[0];
  var match$1 = use(props.query);
  var activities = match$1.activities;
  var match$2 = ReactHookForm.useForm({
        resolver: Caml_option.some(Zod$1.zodResolver(schema)),
        defaultValues: {}
      });
  var errors = match$2.formState.errors;
  var reset = match$2.reset;
  var handleSubmit = match$2.handleSubmit;
  var register = match$2.register;
  var onSubmit = function (data) {
    var connections = Core__Option.getOr(Core__Option.map(connectionId, (function (connectionId) {
                return [RelayRuntime.ConnectionHandler.getConnectionID(connectionId, "SelectClub_adminClubs", undefined)];
              })), []);
    commitMutationCreate({
          connections: connections,
          input: {
            activity: data.activity,
            description: data.description,
            name: data.name,
            slug: data.slug
          }
        }, undefined, undefined, undefined, (function (response, _errors) {
            Core__Option.map(response.createClub.club, (function (club) {
                    reset(undefined);
                    return onCreated(club);
                  }));
          }), undefined, undefined);
  };
  return JsxRuntime.jsx(WaitForMessages.make, {
              children: (function () {
                  var match = errors.name;
                  var tmp;
                  if (match !== undefined) {
                    var message = match.message;
                    tmp = message !== undefined ? message : "";
                  } else {
                    tmp = "";
                  }
                  var match$1 = errors.slug;
                  var tmp$1;
                  if (match$1 !== undefined) {
                    var message$1 = match$1.message;
                    tmp$1 = message$1 !== undefined ? message$1 : "";
                  } else {
                    tmp$1 = "";
                  }
                  var match$2 = errors.activity;
                  var tmp$2;
                  if (match$2 !== undefined) {
                    var message$2 = match$2.message;
                    tmp$2 = message$2 !== undefined ? message$2 : "";
                  } else {
                    tmp$2 = "";
                  }
                  return JsxRuntime.jsx("form", {
                              children: JsxRuntime.jsxs(Grid.make, {
                                    className: "grid-cols-1",
                                    children: [
                                      JsxRuntime.jsx(FormSection.make, {
                                            title: t`club`,
                                            children: JsxRuntime.jsxs("div", {
                                                  children: [
                                                    JsxRuntime.jsxs("div", {
                                                          children: [
                                                            JsxRuntime.jsx(Form.Input.make, {
                                                                  label: t`name`,
                                                                  name: "name",
                                                                  id: "name",
                                                                  placeholder: t`ゆびバド`,
                                                                  register: register("name", undefined)
                                                                }),
                                                            JsxRuntime.jsx("p", {
                                                                  children: tmp
                                                                })
                                                          ],
                                                          className: "col-span-full"
                                                        }),
                                                    JsxRuntime.jsxs("div", {
                                                          children: [
                                                            JsxRuntime.jsx(Form.PrefixedInput.make, {
                                                                  label: t`slug`,
                                                                  prefix: "www.racquetleague.com/clubs/",
                                                                  className: "block flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm sm:leading-6",
                                                                  name: "slug",
                                                                  id: "slug",
                                                                  placeholder: t`yubibado`,
                                                                  register: register("slug", undefined)
                                                                }),
                                                            JsxRuntime.jsx("p", {
                                                                  children: tmp$1
                                                                })
                                                          ],
                                                          className: "sm:col-span-2 md:col-span-3 lg:col-span-2 lg:max-w-lg"
                                                        }),
                                                    JsxRuntime.jsxs("div", {
                                                          children: [
                                                            JsxRuntime.jsx(Form.Select.make, {
                                                                  label: t`main activity`,
                                                                  name: "activity",
                                                                  id: "activity",
                                                                  options: activities.map(function (activity) {
                                                                        return [
                                                                                Core.i18n._(Core__Option.getOr(activity.name, "---")),
                                                                                activity.id
                                                                              ];
                                                                      }),
                                                                  register: register("activity", undefined)
                                                                }),
                                                            JsxRuntime.jsx("p", {
                                                                  children: tmp$2
                                                                })
                                                          ],
                                                          className: "sm:col-span-2 md:col-span-3 lg:col-span-2 lg:max-w-lg"
                                                        }),
                                                    JsxRuntime.jsx("div", {
                                                          children: JsxRuntime.jsx(Form.TextArea.make, {
                                                                label: t`about`,
                                                                name: "description",
                                                                id: "description",
                                                                hint: Caml_option.some(t`tell people about your club`),
                                                                register: register("description", undefined)
                                                              }),
                                                          className: "col-span-full"
                                                        })
                                                  ],
                                                  className: "mt-10 grid grid-cols-1 gap-x-6 gap-y-8 sm:grid-cols-6"
                                                })
                                          }),
                                      JsxRuntime.jsx(Form.Footer.make, {
                                            onCancel: onCancel
                                          })
                                    ]
                                  }),
                              onSubmit: handleSubmit(onSubmit)
                            });
                })
            });
}

var make = CreateClubForm;

export {
  ts ,
  ActivitiesFragment ,
  Mutation ,
  sessionContext ,
  ControllerOfInputs ,
  schema ,
  make ,
}
/*  Not a pure module */
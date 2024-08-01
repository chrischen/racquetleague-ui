// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Zod from "zod";
import * as Form from "../molecules/forms/Form.re.mjs";
import * as Grid from "../vanillaui/atoms/Grid.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Array from "@rescript/core/src/Core__Array.re.mjs";
import * as FormSection from "../molecules/forms/FormSection.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as RelayRuntime from "relay-runtime";
import * as WaitForMessages from "../shared/i18n/WaitForMessages.re.mjs";
import * as ReactHookForm from "react-hook-form";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as AppContext from "../layouts/appContext";
import * as RescriptRelay_Mutation from "rescript-relay/src/RescriptRelay_Mutation.re.mjs";
import * as Zod$1 from "@hookform/resolvers/zod";
import * as CreateLocationFormMutation_graphql from "../../__generated__/CreateLocationFormMutation_graphql.re.mjs";

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

var isEmptyObj = (obj => Object.keys(obj).length === 0 && obj.constructor === Object);

function parseData(json) {
  if (isEmptyObj(json)) {
    return "Empty";
  } else {
    return {
            TAG: "Promise",
            _0: json
          };
  }
}

var convertVariables = CreateLocationFormMutation_graphql.Internal.convertVariables;

var convertResponse = CreateLocationFormMutation_graphql.Internal.convertResponse;

var convertWrapRawResponse = CreateLocationFormMutation_graphql.Internal.convertWrapRawResponse;

var commitMutation = RescriptRelay_Mutation.commitMutation(convertVariables, CreateLocationFormMutation_graphql.node, convertResponse, convertWrapRawResponse);

var use = RescriptRelay_Mutation.useMutation(convertVariables, CreateLocationFormMutation_graphql.node, convertResponse, convertWrapRawResponse);

var CreateLocationMutation = {
  Operation: undefined,
  Types: undefined,
  convertVariables: convertVariables,
  convertResponse: convertResponse,
  convertWrapRawResponse: convertWrapRawResponse,
  commitMutation: commitMutation,
  use: use
};

var sessionContext = AppContext.SessionContext;

var ControllerOfInputs = {};

var schema = Zod.z.object({
      name: Zod.z.string({
              required_error: t`name is required`
            }).min(1),
      address: Zod.z.string({
              required_error: t`address is required`
            }).min(1),
      links: Zod.z.string({}).optional(),
      details: Zod.z.string({}).optional()
    });

function CreateLocationForm(props) {
  var onClose = props.onClose;
  var onCancel = props.onCancel;
  var match = use();
  var commitMutationCreate = match[0];
  var navigate = ReactRouterDom.useNavigate();
  var match$1 = ReactHookForm.useForm({
        resolver: Caml_option.some(Zod$1.zodResolver(schema)),
        defaultValues: {}
      });
  var errors = match$1.formState.errors;
  var reset = match$1.reset;
  var handleSubmit = match$1.handleSubmit;
  var register = match$1.register;
  var onSubmit = function (data) {
    var connectionId = RelayRuntime.ConnectionHandler.getConnectionID("client:root", "SelectLocation_locations", undefined);
    var links = Core__Option.map(data.links, (function (link) {
            return Core__Array.reduce(link.split(/,[ ]+/), [], (function (acc, link) {
                          if (link !== undefined) {
                            return acc.concat([link]);
                          } else {
                            return acc;
                          }
                        }));
          }));
    commitMutationCreate({
          connections: [connectionId],
          input: {
            address: data.address,
            details: data.details,
            links: links,
            name: data.name
          }
        }, undefined, undefined, undefined, (function (response, _errors) {
            Core__Option.map(response.createLocation.location, (function ($$location) {
                    navigate($$location.id, undefined);
                  }));
            reset(undefined);
            onClose();
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
                  return JsxRuntime.jsx("form", {
                              children: JsxRuntime.jsxs(Grid.make, {
                                    className: "grid-cols-1",
                                    children: [
                                      JsxRuntime.jsx(FormSection.make, {
                                            title: t`location`,
                                            children: JsxRuntime.jsxs("div", {
                                                  children: [
                                                    JsxRuntime.jsxs("div", {
                                                          children: [
                                                            JsxRuntime.jsx(Form.Input.make, {
                                                                  label: t`name`,
                                                                  name: "name",
                                                                  id: "name",
                                                                  placeholder: t`Akabane Elementary School`,
                                                                  register: register("name", undefined)
                                                                }),
                                                            JsxRuntime.jsx("p", {
                                                                  children: tmp
                                                                })
                                                          ],
                                                          className: "col-span-full"
                                                        }),
                                                    JsxRuntime.jsx("div", {
                                                          children: JsxRuntime.jsx(Form.Input.make, {
                                                                label: t`address`,
                                                                name: "address",
                                                                id: "address",
                                                                register: register("address", undefined)
                                                              }),
                                                          className: "sm:col-span-3"
                                                        }),
                                                    JsxRuntime.jsx("div", {
                                                          children: JsxRuntime.jsx(Form.Input.make, {
                                                                label: t`maps link`,
                                                                name: "links",
                                                                id: "links",
                                                                placeholder: "https://maps.app.goo.gl/77FBSgrFRFAQrPrM8",
                                                                register: register("links", undefined)
                                                              }),
                                                          className: "sm:col-span-2"
                                                        }),
                                                    JsxRuntime.jsx("div", {
                                                          children: JsxRuntime.jsx(Form.TextArea.make, {
                                                                label: t`details`,
                                                                name: "details",
                                                                id: "details",
                                                                hint: Caml_option.some(t`Instructions or information that will apply to all events held at this location.`),
                                                                register: register("details", undefined)
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

var make = CreateLocationForm;

export {
  ts ,
  isEmptyObj ,
  parseData ,
  CreateLocationMutation ,
  sessionContext ,
  ControllerOfInputs ,
  schema ,
  make ,
}
/*  Not a pure module */

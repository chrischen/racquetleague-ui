// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Zod from "zod";
import * as Form from "../molecules/forms/Form.re.mjs";
import * as Rating from "../../lib/Rating.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as EventRsvpUser from "./EventRsvpUser.re.mjs";
import ReactQrCode from "react-qr-code";
import * as ReactHookForm from "react-hook-form";
import * as JsxRuntime from "react/jsx-runtime";
import * as Zod$1 from "@hookform/resolvers/zod";

import { css, cx } from '@linaria/core'
;

import { t, plural } from '@lingui/macro'
;

var ControllerOfInputsUser = {};

var schema = Zod.z.object({
      name: Zod.z.string({}).min(1)
    });

function toEventRsvpUser(data) {
  return EventRsvpUser.makeGuest(data.name);
}

function toRatingPlayer(data) {
  var rating = Rating.Rating.makeDefault();
  return {
          data: undefined,
          id: "guest-" + data.name,
          name: data.name,
          rating: rating,
          ratingOrdinal: Rating.Rating.ordinal(rating)
        };
}

function SessionAddPlayer(props) {
  var onPlayerAdd = props.onPlayerAdd;
  var match = ReactHookForm.useForm({
        resolver: Caml_option.some(Zod$1.zodResolver(schema)),
        defaultValues: {}
      });
  var setValue = match.setValue;
  var onSubmit = function (data) {
    onPlayerAdd(data);
    setValue("name", "", undefined);
  };
  return JsxRuntime.jsxs("div", {
              children: [
                JsxRuntime.jsx(ReactQrCode, {
                      value: "https://www.racquetleague.com/events/" + props.eventId
                    }),
                JsxRuntime.jsxs("form", {
                      children: [
                        JsxRuntime.jsx(Form.Input.make, {
                              label: t`Player Name`,
                              className: "w-24 sm:w-32 md:w-48  flex-1 border-0 bg-transparent py-1.5 pl-1 text-gray-900 placeholder:text-gray-400 focus:ring-0 text-2xl sm:text-5xl sm:leading-6",
                              id: "name",
                              type_: "text",
                              register: match.register("name", undefined)
                            }),
                        JsxRuntime.jsx(Form.Footer.make, {
                              onCancel: props.onCancel
                            })
                      ],
                      onSubmit: match.handleSubmit(onSubmit)
                    })
              ],
              className: "grid grid-cols-1 items-start gap-4 md:grid-cols-2 md:gap-8"
            });
}

var make = SessionAddPlayer;

export {
  ControllerOfInputsUser ,
  schema ,
  toEventRsvpUser ,
  toRatingPlayer ,
  make ,
}
/*  Not a pure module */
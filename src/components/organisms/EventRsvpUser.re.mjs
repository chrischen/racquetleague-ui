// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_obj from "rescript/lib/es6/caml_obj.js";
import * as RsvpUser from "./RsvpUser.re.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as EventRsvpUser_user_graphql from "../../__generated__/EventRsvpUser_user_graphql.re.mjs";

var convertFragment = EventRsvpUser_user_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(EventRsvpUser_user_graphql.node, convertFragment, fRef);
}

function fromRegisteredUser(user) {
  return {
          name: Core__Option.getOr(user.lineUsername, "[Line username missing]"),
          picture: user.picture
        };
}

function make(props) {
  var user = fromRegisteredUser(use(props.user));
  var newrecord = Caml_obj.obj_dup(props);
  return JsxRuntime.jsx(RsvpUser.make, (newrecord.user = user, newrecord));
}

export {
  make ,
}
/* RsvpUser Not a pure module */

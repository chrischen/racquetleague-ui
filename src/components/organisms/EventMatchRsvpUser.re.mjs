// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_obj from "rescript/lib/es6/caml_obj.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as MatchRsvpUser from "../molecules/MatchRsvpUser.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as EventMatchRsvpUser_user_graphql from "../../__generated__/EventMatchRsvpUser_user_graphql.re.mjs";

var convertFragment = EventMatchRsvpUser_user_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(EventMatchRsvpUser_user_graphql.node, convertFragment, fRef);
}

function make(props) {
  var user = use(props.user);
  var newrecord = Caml_obj.obj_dup(props);
  return JsxRuntime.jsx(MatchRsvpUser.make, (newrecord.user = {
                name: Core__Option.getOr(user.lineUsername, "[Line username missing]"),
                picture: user.picture
              }, newrecord));
}

export {
  make ,
}
/* MatchRsvpUser Not a pure module */

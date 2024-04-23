// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as EventLocation_location_graphql from "../../__generated__/EventLocation_location_graphql.re.mjs";

var convertFragment = EventLocation_location_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(EventLocation_location_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, EventLocation_location_graphql.node, convertFragment);
}

var Fragment = {
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment,
  use: use,
  useOpt: useOpt
};

function EventLocation(props) {
  var $$location = use(props.location);
  var defaultLink = Core__Option.flatMap($$location.links, (function (links) {
          return links[0];
        }));
  return JsxRuntime.jsxs(JsxRuntime.Fragment, {
              children: [
                Core__Option.getOr(Core__Option.map($$location.address, (function (address) {
                            return JsxRuntime.jsx("p", {
                                        children: Core__Option.getOr(Core__Option.map(defaultLink, (function (link) {
                                                    return JsxRuntime.jsx("a", {
                                                                children: address,
                                                                href: link,
                                                                rel: "noopener noreferrer",
                                                                target: "_blank"
                                                              });
                                                  })), address),
                                        className: "mt-4 lg:text-xl leading-8 text-gray-700"
                                      });
                          })), ""),
                Core__Option.getOr(Core__Option.map($$location.links, (function (links) {
                            return links.map(function (link) {
                                        return JsxRuntime.jsx("a", {
                                                    children: link,
                                                    className: "mt-4 lg:text-sm leading-8 italic text-gray-700",
                                                    href: link,
                                                    rel: "noopener noreferrer",
                                                    target: "_blank"
                                                  }, link);
                                      });
                          })), null)
              ]
            });
}

var make = EventLocation;

export {
  Fragment ,
  make ,
}
/* react/jsx-runtime Not a pure module */
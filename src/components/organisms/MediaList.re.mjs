// Generated by ReScript, PLEASE EDIT WITH CARE

import * as React from "react";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as Core__Option from "@rescript/core/src/Core__Option.re.mjs";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Fragment from "rescript-relay/src/RescriptRelay_Fragment.re.mjs";
import * as IframeJsx from "../molecules/iframe.jsx";
import * as MediaList_location_graphql from "../../__generated__/MediaList_location_graphql.re.mjs";

var convertFragment = MediaList_location_graphql.Internal.convertFragment;

function use(fRef) {
  return RescriptRelay_Fragment.useFragment(MediaList_location_graphql.node, convertFragment, fRef);
}

function useOpt(fRef) {
  return RescriptRelay_Fragment.useFragmentOpt(fRef !== undefined ? Caml_option.some(Caml_option.valFromOption(fRef)) : undefined, MediaList_location_graphql.node, convertFragment);
}

var Fragment = {
  Types: undefined,
  Operation: undefined,
  convertFragment: convertFragment,
  use: use,
  useOpt: useOpt
};

var make = IframeJsx.YouTube;

var YouTube = {
  make: make
};

function $$MediaList(props) {
  var $$location = use(props.media);
  var media = Core__Option.getOr($$location.media, []);
  return media.map(function (media) {
              return Core__Option.getOr(Core__Option.map(media.url, (function (url) {
                                return JsxRuntime.jsxs(React.Fragment, {
                                            children: [
                                              JsxRuntime.jsx("p", {
                                                    children: Core__Option.getOr((function (__x) {
                                                              return Core__Option.map(__x, (function (prim) {
                                                                            return prim;
                                                                          }));
                                                            })(media.title), null)
                                                  }),
                                              JsxRuntime.jsx(make, {
                                                    url: url
                                                  })
                                            ]
                                          }, media.id);
                              })), null);
            });
}

var make$1 = $$MediaList;

export {
  Fragment ,
  YouTube ,
  make$1 as make,
}
/* make Not a pure module */

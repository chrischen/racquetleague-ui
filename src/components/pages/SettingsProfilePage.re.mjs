// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Layout from "../shared/Layout.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as SettingsProfileForm from "../organisms/SettingsProfileForm.re.mjs";
import * as SettingsProfilePageQuery_graphql from "../../__generated__/SettingsProfilePageQuery_graphql.re.mjs";

import { t } from '@lingui/macro'
;

var convertVariables = SettingsProfilePageQuery_graphql.Internal.convertVariables;

var convertResponse = SettingsProfilePageQuery_graphql.Internal.convertResponse;

var convertWrapRawResponse = SettingsProfilePageQuery_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, SettingsProfilePageQuery_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, SettingsProfilePageQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(SettingsProfilePageQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(SettingsProfilePageQuery_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(SettingsProfilePageQuery_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(SettingsProfilePageQuery_graphql.node, convertVariables);

var Query = {
  Operation: undefined,
  Types: undefined,
  convertVariables: convertVariables,
  convertResponse: convertResponse,
  convertWrapRawResponse: convertWrapRawResponse,
  use: use,
  useLoader: useLoader,
  usePreloaded: usePreloaded,
  $$fetch: $$fetch,
  fetchPromised: fetchPromised,
  retain: retain
};

function SettingsProfilePage(props) {
  var data = ReactRouterDom.useLoaderData();
  var query = usePreloaded(data.data);
  return JsxRuntime.jsx(Layout.Container.make, {
              children: JsxRuntime.jsx(SettingsProfileForm.make, {
                    query: query.fragmentRefs
                  })
            });
}

var make = SettingsProfilePage;

export {
  Query ,
  make ,
}
/*  Not a pure module */

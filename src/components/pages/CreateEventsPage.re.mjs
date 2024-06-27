// Generated by ReScript, PLEASE EDIT WITH CARE

import * as SelectClub from "../organisms/SelectClub.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as RescriptRelay_Query from "rescript-relay/src/RescriptRelay_Query.re.mjs";
import * as CreateEventsPageQuery_graphql from "../../__generated__/CreateEventsPageQuery_graphql.re.mjs";

import { t } from '@lingui/macro'
;

var convertVariables = CreateEventsPageQuery_graphql.Internal.convertVariables;

var convertResponse = CreateEventsPageQuery_graphql.Internal.convertResponse;

var convertWrapRawResponse = CreateEventsPageQuery_graphql.Internal.convertWrapRawResponse;

var use = RescriptRelay_Query.useQuery(convertVariables, CreateEventsPageQuery_graphql.node, convertResponse);

var useLoader = RescriptRelay_Query.useLoader(convertVariables, CreateEventsPageQuery_graphql.node, (function (prim) {
        return prim;
      }));

var usePreloaded = RescriptRelay_Query.usePreloaded(CreateEventsPageQuery_graphql.node, convertResponse, (function (prim) {
        return prim;
      }));

var $$fetch = RescriptRelay_Query.$$fetch(CreateEventsPageQuery_graphql.node, convertResponse, convertVariables);

var fetchPromised = RescriptRelay_Query.fetchPromised(CreateEventsPageQuery_graphql.node, convertResponse, convertVariables);

var retain = RescriptRelay_Query.retain(CreateEventsPageQuery_graphql.node, convertVariables);

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

function CreateEventsPage(props) {
  var data = ReactRouterDom.useLoaderData();
  var query = usePreloaded(data.data);
  return JsxRuntime.jsx(SelectClub.make, {
              clubs: query.fragmentRefs
            });
}

var make = CreateEventsPage;

export {
  Query ,
  make ,
}
/*  Not a pure module */

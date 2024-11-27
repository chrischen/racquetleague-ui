// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Layout from "../shared/Layout.re.mjs";
import * as Lingui from "../../locales/Lingui.re.mjs";
import * as RelayEnv from "../../entry/RelayEnv.re.mjs";
import * as Localized from "../shared/i18n/Localized.re.mjs";
import * as Caml_option from "rescript/lib/es6/caml_option.js";
import * as DefaultLayoutMap from "../pages/DefaultLayoutMap.re.mjs";
import * as ReactRouterDom from "react-router-dom";
import * as JsxRuntime from "react/jsx-runtime";
import * as DefaultLayoutMapQuery_graphql from "../../__generated__/DefaultLayoutMapQuery_graphql.re.mjs";

import { css, cx } from '@linaria/core'
;

import { t } from '@lingui/macro'
;

var loadMessages = Lingui.loadMessages({
      ja: import("../../locales/src/components/pages/DefaultLayoutMap.re/ja"),
      en: import("../../locales/src/components/pages/DefaultLayoutMap.re/en")
    });

var LoaderArgs = {};

async function loader(param) {
  return ReactRouterDom.defer({
              data: DefaultLayoutMapQuery_graphql.load(RelayEnv.getRelayEnv(param.context, import.meta.env.SSR), undefined, "store-or-network", undefined, undefined),
              i18nLoaders: Caml_option.some(Localized.loadMessages(param.params.lang, loadMessages))
            });
}

var HydrateFallbackElement = JsxRuntime.jsx(Layout.Container.make, {
      children: "Loading fallback..."
    });

var Component = DefaultLayoutMap.make;

export {
  Component ,
  loadMessages ,
  LoaderArgs ,
  loader ,
  HydrateFallbackElement ,
}
/*  Not a pure module */
import type { RouteObject } from "react-router-dom";
import type { HelmetServerState } from "react-helmet-async";
import type { RecordMap } from "./RelayEnvironment";
import { StrictMode } from "react";
import { HelmetProvider } from "react-helmet-async";
import { i18n } from "@lingui/core";
import { I18nProvider } from "@lingui/react";
import { RelayEnvironmentProvider } from "react-relay";
import { environment } from "./RelayEnv.re.mjs";
import { createBrowserRouter } from "react-router-dom";
import { matchRoutes } from "react-router";
import { bootOnClient } from "../../server/RelaySSRUtils.re.mjs";
// import { routes } from "../routes";
// import { routes as routesJpl } from "../routes-jpl";
import { Wrapper } from "../wrapper.tsx";
import { wrapRoutesWithErrorBoundary } from "../routesWrapper";

const helmetContext: { helmet: HelmetServerState | undefined } = {
  helmet: undefined,
};
const app = document.getElementById("root");

declare global {
  interface Window {
    updateRelayStore: (relayData: RecordMap) => void | undefined;
    __RELAY_DATA: RecordMap[];
    __READY_TO_BOOT__: boolean;
  }
}

export const renderApp = (routes: RouteObject[]) => () => {
  const routesWithErrorBoundary = wrapRoutesWithErrorBoundary(routes);
  const router = createBrowserRouter(routesWithErrorBoundary, { future: { v7_partialHydration: true } });

  const jsx = (
    <StrictMode>
      <RelayEnvironmentProvider environment={environment}>
        <HelmetProvider context={helmetContext}>
          <Wrapper router={router} />
        </HelmetProvider>
      </RelayEnvironmentProvider>
    </StrictMode>
  );
  return jsx;
}

async function hydrate(app: HTMLElement) {
  let routes: RouteObject[];
  if (window.location.hostname == "www.japanpickleleague.com"
    || window.location.hostname == "local.japanpickleleague.com") {
    routes = (await import("../routes-jpl.tsx")).routes;
  } else {
    routes = (await import("../routes.tsx")).routes;
  }

  // Determine if any of the initial routes are lazy
  const lazyMatches = matchRoutes(routes, window.location)?.filter(
    (m) => m.route.lazy
  );

  // Load the lazy matches and update the routes before creating your router
  // so we can hydrate the SSR-rendered content synchronously
  if (lazyMatches && lazyMatches?.length > 0) {
    await Promise.all(
      lazyMatches.map(async (m) => {
        const routeModule = await m.route.lazy!();
        Object.assign(m.route, { ...routeModule, lazy: undefined });
      })
    );
  }


  await bootOnClient(app, renderApp(routes));
}

if (app) {
  hydrate(app);
}

import type { RouteObject } from "react-router-dom";
import { make as NotFound } from "./components/pages/NotFound.gen";
export const routes: RouteObject[] = [
  {
    path: "/:lang?",
    lazy: () =>
      import("./components/shared/Lang.gen"),
    // Component: (await import("./components/shared/LangProvider.gen")).make,

    handle: "src/components/shared/Lang.gen.tsx",
    HydrateFallbackElement: <>Loading Fallback...</>,
    children: [
      {
        path: "",
        // Declaring handle allows the server to pull the scripts needed based on
        // the entrypoint to avoid waterfall loading of dependencies
        lazy: () => import("./components/routes/LeagueLayoutRoute.gen"),
        handle: "src/components/routes/LeagueLayoutRoute.gen.tsx",
        HydrateFallbackElement: <>Loading Fallback...</>,
        children: [
          {
            path: "oauth-login",
            lazy: () => import("./components/routes/LoginRoute.gen"),
            handle: "src/components/routes/LoginRoute.gen.tsx",
          },
          {
            path: "oauth/line/error",
            lazy: () => import("./components/routes/LoginLineErrorRoute.gen"),
            handle: "src/components/routes/LoginLineErrorRoute.gen.tsx",
          },
          {
            path: "league",
            lazy: () => import("./components/routes/LeagueRoute.gen"),
            handle: "src/components/routes/LeagueRoute.gen.tsx",
          },
          {
            path: "*",
            lazy: () => import("./components/routes/NotFoundRoute.gen"),
            handle: "src/components/routes/NotFoundRoute.gen.tsx",
          }

        ]
      },
    ]
  }
];

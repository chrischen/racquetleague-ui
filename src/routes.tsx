import type { RouteObject } from "react-router-dom";
import { make as NotFound } from "./components/pages/NotFound.gen";
export const routes: RouteObject[] = [
  {
    path: "/defertest",
    lazy: () => import("./components/routes/DeferTestRoute.re.mjs"),
    handle: "src/components/routes/DeferTestRoute.re.mjs",
    HydrateFallbackElement: <>Loading Fallback...</>,
  },
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
        lazy: () => import("./components/routes/DefaultLayoutRoute.gen"),
        handle: "src/components/routes/DefaultLayoutRoute.gen.tsx",
        HydrateFallbackElement: <>Loading Fallback...</>,
        children: [
          {
            path: "",
            index: true,
            lazy: () => import("./components/pages/Events.gen"),
            handle: "src/components/pages/Events.gen.tsx",
            HydrateFallbackElement: <>Loading Fallback...</>,
          },
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
            path: "locations/:locationId",
            lazy: () => import("./components/routes/LocationRoute.gen"),
            handle: "src/components/routes/LocationRoute.gen.tsx",
          },
          // {
          //   path: "",
          //   lazy: () => import("./components/pages/Events.gen"),
          //   handle: "src/components/pages/Events.gen.tsx",
          // },
          // {
          //   path: "members",
          //   lazy: () => import("./components/routes/UsersRoute.jsx"),
          //   // Declaring handle allows the server to pull the scripts needed based on
          //   // the entrypoint to avoid waterfall loading of dependencies
          //   handle: "src/components/routes/UsersRoute.tsx",
          //
          // },
          {
            path: "events",
            lazy: () => import("./components/routes/ViewerEventsRoute.gen"),
            handle: "src/components/routes/ViewerEventsRoute.gen.tsx",
          },
          {
            path: "events/create",
            lazy: () => import("./components/routes/CreateEventRoute.gen"),
            handle: "src/components/routes/CreateEventRoute.gen.tsx",
            children: [
              {
                path: ":locationId",
                lazy: () => import("./components/routes/CreateLocationEventRoute.gen"),
                handle: "src/components/routes/CreateLocationEventRoute.gen.tsx",
              },

            ]

          },
          {
            path: "events/:eventId",
            lazy: () => import("./components/pages/Event.gen"),
            handle: "src/components/pages/Event.gen.tsx",

          },
          {
            path: "locations/create",
            lazy: () => import("./components/routes/CreateLocationRoute.gen"),
            handle: "src/components/routes/CreateLocationRoute.gen.tsx",

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

import type { RouteObject } from "react-router-dom";
import { RootErrorBoundary } from "./components/shared/RootErrorBoundary";

export const routes: RouteObject[] = [
  {
    path: "/defertest",
    lazy: () => import("./components/routes/DeferTestRoute.re.mjs"),
    handle: "src/components/routes/DeferTestRoute.re.mjs",
    // HydrateFallbackElement: <>Loading Fallback...</>,
  },
  {
    path: "/:lang?",
    lazy: () => import("./components/shared/Lang.gen"),
    // Component: (await import("./components/shared/LangProvider.gen")).make,

    handle: "src/components/shared/Lang.gen.tsx",
    // HydrateFallbackElement: <>Loading Fallback...</>,
    // errorElement: <RootErrorBoundary/>,
    children: [
      {
        // path: ":activitySlug",
        path: "",
        // Declaring handle allows the server to pull the scripts needed based on
        // the entrypoint to avoid waterfall loading of dependencies
        lazy: () => import("./components/routes/DefaultLayoutRoute.gen"),
        handle: "src/components/routes/DefaultLayoutRoute.gen.tsx",
        // HydrateFallbackElement: <>Loading Fallback...</>,
        children: [
          {
            index: true,
            lazy: () => import("./components/pages/Events.gen"),
            handle: "src/components/pages/Events.gen.tsx",
            // HydrateFallbackElement: <>Loading Fallback...</>
          },
          {
            path: "events",
            lazy: () => import("./components/routes/ViewerEventsRoute.gen"),
            handle: "src/components/routes/ViewerEventsRoute.gen.tsx",
          },
          {
            path: "locations/:locationId",
            lazy: () => import("./components/routes/LocationRoute.gen"),
            handle: "src/components/routes/LocationRoute.gen.tsx"
          },
          // {
          //   path: "locations",
          //   // Declaring handle allows the server to pull the scripts needed based on
          //   // the entrypoint to avoid waterfall loading of dependencies
          //   lazy: () => import("./components/routes/DefaultLayoutContentRoute.gen"),
          //   handle: "src/components/routes/DefaultLayoutContentRoute.gen.tsx",
          //   children: []
          // },
          {
            path: "clubs",
            lazy: () => import("./components/routes/ClubsRoute.gen"),
            handle: "src/components/routes/ClubsRoute.gen.tsx",
            children: [
              {
                index: true,
                lazy: () => import("./components/routes/ViewerClubsRoute.gen"),
                handle: "src/components/routes/ViewerClubsRoute.gen.tsx",
              },
              {
                path: ":slug",
                lazy: () => import("./components/routes/ClubRoute.gen"),
                handle: "src/components/routes/ClubRoute.gen.tsx",
              },
              {
                path: ":slug/members",
                lazy: () => import("./components/routes/ClubMembersRoute.gen"),
                handle: "src/components/routes/ClubMembersRoute.gen.tsx",
              },
            ],
          },
          {
            // Declaring handle allows the server to pull the scripts needed based on
            // the entrypoint to avoid waterfall loading of dependencies
            lazy: () => import("./components/routes/DefaultLayoutContentRoute.gen"),
            handle: "src/components/routes/DefaultLayoutContentRoute.gen.tsx",
            children: [
              {
                path: "oauth/line/error",
                lazy: () => import("./components/routes/LoginLineErrorRoute.gen"),
                handle: "src/components/routes/LoginLineErrorRoute.gen.tsx",
              },
              {
                path: "locations/create",
                lazy: () => import("./components/routes/CreateLocationRoute.gen"),
                handle: "src/components/routes/CreateLocationRoute.gen.tsx",

              },
              {
                path: "pickleball-tokyo-guide",
                lazy: () => import("./components/routes/PickleballTokyoRoute.gen"),
                handle: "src/components/routes/PickleballTokyoRoute.gen.tsx",
              },
              {
                path: "fairplay-guide",
                lazy: () => import("./components/routes/FairPlayGuideRoute.gen"),
                handle: "src/components/routes/FairPlayGuideRoute.gen.tsx",
              },
            ]
          },
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
            // Declaring handle allows the server to pull the scripts needed based on
            // the entrypoint to avoid waterfall loading of dependencies
            lazy: () => import("./components/routes/DefaultLayoutContentRoute.gen"),
            handle: "src/components/routes/DefaultLayoutContentRoute.gen.tsx",
            children: [
              {
                path: "create-bulk",
                lazy: () => import("./components/routes/CreateEventsRoute.gen"),
                handle: "src/components/routes/CreateEventsRoute.gen.tsx",
                children: [
                  {
                    path: ":clubId",
                    lazy: () => import("./components/routes/CreateClubEventsRoute.gen"),
                    handle: "src/components/routes/CreateClubEventsRoute.gen.tsx",
                  },

                ]
              },
              {
                path: "create",
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
                path: "update/:eventId/:locationId",
                lazy: () => import("./components/routes/UpdateEventRoute.gen"),
                handle: "src/components/routes/UpdateEventRoute.gen.tsx",
                // children: [
                //   {
                //     path: ":locationId",
                //     lazy: () => import("./components/routes/UpdateLocationEventRoute.gen"),
                //     handle: "src/components/routes/UpdateLocationEventRoute.gen.tsx",
                //   },
                //
                // ]

              },
              {
                path: ":eventId",
                lazy: () => import("./components/pages/Event.gen"),
                handle: "src/components/pages/Event.gen.tsx",
                HydrateFallbackElement: <>Loading Fallback...</>
              },
            ]
          },
          {
            path: "league",
            lazy: () => import("./components/routes/DefaultLayoutContentRoute.gen"),
            handle: "src/components/routes/DefaultLayoutContentRoute.gen.tsx",
            children: [
              {
                path: ":activitySlug",
                lazy: () => import("./components/routes/LeagueRoute.gen"),
                handle: "src/components/routes/LeagueRoute.gen.tsx",
                children: [
                  {
                    path: "",
                    lazy: () => import("./components/routes/LeagueRankingsRoute.gen"),
                    handle: "src/components/routes/LeagueRankingsRoute.gen.tsx",
                  },
                  {
                    path: ":ns",
                    lazy: () => import("./components/routes/LeagueRankingsRoute.gen"),
                    handle: "src/components/routes/LeagueRankingsRoute.gen.tsx",
                  },
                  {
                    path: "p/:userId",
                    lazy: () => import("./components/routes/LeaguePlayerRoute.gen"),
                    handle: "src/components/routes/LeaguePlayerRoute.gen.tsx",
                  },
                  {
                    path: "games",
                    lazy: () => import("./components/routes/FindGamesRoute.gen"),
                    handle: "src/components/routes/FindGamesRoute.gen.tsx",
                  },
                  {
                    path: "about",
                    lazy: () => import("./components/routes/LeagueAboutRoute.gen"),
                    handle: "src/components/routes/LeagueAboutRoute.gen.tsx",
                  },
                ]
              },
              {
                path: "events/:eventId/:activitySlug",
                lazy: () => import("./components/routes/LeagueEventRoute.gen"),
                handle: "src/components/routes/LeagueEventRoute.gen.tsx",
              },
            ]
          },
          {
            path: "settings",
            // Declaring handle allows the server to pull the scripts needed based on
            // the entrypoint to avoid waterfall loading of dependencies
            lazy: () => import("./components/routes/DefaultLayoutContentRoute.gen"),
            handle: "src/components/routes/DefaultLayoutContentRoute.gen.tsx",
            children: [
              {
                path: "profile",
                lazy: () => import("./components/routes/SettingsProfileRoute.gen"),
                handle: "src/components/routes/SettingsProfileRoute.gen.tsx",

              },
            ]
          },
          {
            path: "*",
            lazy: () => import("./components/routes/NotFoundRoute.gen"),
            handle: "src/components/routes/NotFoundRoute.gen.tsx",
          },
        ]
      },
      {
        path: "oauth-login",
        lazy: () => import("./components/routes/LoginRoute.gen"),
        handle: "src/components/routes/LoginRoute.gen.tsx",
      },
      {
        path: "league",
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
            path: "*",
            lazy: () => import("./components/routes/NotFoundRoute.gen"),
            handle: "src/components/routes/NotFoundRoute.gen.tsx",
          }
        ]
      }
    ]
  },
  {
    path: "*",
    lazy: () => import("./components/routes/NotFoundRoute.gen"),
    handle: "src/components/routes/NotFoundRoute.gen.tsx",
  }
];

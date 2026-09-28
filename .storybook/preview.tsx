/// <reference types="vite/client" />
import * as React from "react";
import type { Decorator, Preview } from "@storybook/react-vite";
import { HelmetProvider } from "react-helmet-async";
import { RouterProvider, createMemoryRouter } from "react-router-dom";
import { i18n, type Messages } from "@lingui/core";
import { make as LangProvider } from "../src/components/shared/LangProvider.gen";
import { relayLoader, withRelay } from "./relay";
import "../src/global/static.css";

// English messages from every per-module catalog. Development builds would
// fall back to the source text anyway, but `build-storybook` compiles the
// Lingui macros for production, which drops that text and leaves only ids.
const catalogs = import.meta.glob<{ messages: Messages }>("../src/locales/src/**/en.ts", { eager: true });
i18n.loadAndActivate({
  locale: "en",
  messages: Object.assign({}, ...Object.values(catalogs).map((c) => c.messages)),
});

// What the app's /:lang? route loader returns for English (src/components/shared/Lang.res).
const LOCALE = { locale: "us", lang: "en", timezone: "Asia/Tokyo" };

/**
 * `parameters.router` for components that read the URL (useParams,
 * useLocation, search params) or their route's loader data. The story renders
 * at `path`, the router starts at `url`, and useLoaderData() returns
 * `loaderData`:
 *
 *   parameters: { router: { path: "events/:eventId", url: "/events/evt-1?tab=rsvps" } }
 *
 * Without it the story renders at "/" with no loader data.
 */
export type RouterParameters = { path?: string; url?: string; loaderData?: unknown };

// The router is built once per story and the story reaches its route through
// context, so a Controls change re-renders the story without rebuilding the
// router (which would reset its state).
const StorySlot = React.createContext<React.ReactNode>(null);
const StoryOutlet = () => <>{React.useContext(StorySlot)}</>;

function AppShell({ route, children }: { route: RouterParameters; children: React.ReactNode }) {
  const { path, url, loaderData } = route;
  const router = React.useMemo(
    () =>
      createMemoryRouter(
        [
          {
            id: "lang",
            path: "/",
            element: <LangProvider />,
            loader: () => LOCALE,
            children: [
              path
                ? { id: "story", path, element: <StoryOutlet />, loader: () => loaderData ?? null }
                : { id: "story", index: true, element: <StoryOutlet />, loader: () => loaderData ?? null },
            ],
          },
        ],
        // Seeded as already-loaded data so the first render is synchronous.
        { initialEntries: [url ?? "/"], hydrationData: { loaderData: { lang: LOCALE, story: loaderData ?? null } } },
      ),
    [path, url, loaderData],
  );
  return (
    <HelmetProvider>
      <StorySlot.Provider value={children}>
        <RouterProvider router={router} />
      </StorySlot.Provider>
    </HelmetProvider>
  );
}

// PkuruLayout sets the sans font on its container; <html> itself is monospace.
// Dialogs portalled to <body> stay outside this wrapper, as they do in the app.
const withApp: Decorator = (Story, context) => (
  <AppShell route={(context.parameters.router as RouterParameters | undefined) ?? {}}>
    <div className="font-sans">
      <Story />
    </div>
  </AppShell>
);

// The app switches themes with a `dark` class (Tailwind's class strategy) on
// a wrapper in PkuruLayout. Here it goes on <html>, so dialogs and drawers
// portalled to <body> are themed too. Backgrounds match PkuruLayout.
function ThemeScope({ theme, children }: { theme: string; children: React.ReactNode }) {
  React.useLayoutEffect(() => {
    const dark = theme === "dark";
    document.documentElement.classList.toggle("dark", dark);
    document.body.style.background = dark ? "#1a1a1e" : "#ffffff";
    document.body.style.color = dark ? "#f3f4f6" : "#111827";
  }, [theme]);
  return <>{children}</>;
}

const withTheme: Decorator = (Story, context) => (
  <ThemeScope theme={String(context.globals.theme ?? "light")}>
    <Story />
  </ThemeScope>
);

const preview: Preview = {
  // Earlier decorators wrap the story more closely: Relay sits inside the app shell.
  decorators: [withRelay, withApp, withTheme],
  loaders: [relayLoader],
  globalTypes: {
    theme: {
      description: "Light or dark theme",
      toolbar: {
        title: "Theme",
        icon: "mirror",
        items: [
          { value: "light", title: "Light", icon: "sun" },
          { value: "dark", title: "Dark", icon: "moon" },
        ],
        dynamicTitle: true,
      },
    },
  },
  initialGlobals: { theme: "light" },
  parameters: {
    layout: "padded",
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },
  },
};

export default preview;

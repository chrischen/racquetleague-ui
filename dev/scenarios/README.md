# Mocked UI states: dev scenarios and Storybook

Some UI only appears under conditions that are tedious to create for real: a
signed-in player whose profile is incomplete, a full event with a saved card, a
club admin. Two tools reach those states, and both are fed by the same mock
data, so a state described once can be used in either:

- **Dev scenarios** put the running dev server into a named state for your
  browser only. You get the real app: routing, SSR, hydration, layout.
- **Storybook** shows one component at a time, in as many states as you like,
  with controls, an accessibility panel and play-function tests.

Both execute the component's real GraphQL operation against
`data/schema.graphql` with the mock engine in `dev/scenario/engine.mjs`. You
only state the fields that matter; every other selected field gets a
well-formed default.

## Dev scenarios

### Using one

Start the dev server as usual (`yarn start`, or `NODE_ENV=development node server`), then open:

| URL | Effect |
| --- | --- |
| `/__dev/scenario` | Lists the scenarios and shows the active one. |
| `/__dev/scenario/new-user?to=/availability` | Activates `new-user` for this browser, then goes to `/availability`. |
| `/__dev/scenario/off?to=/` | Back to the real backend. |

While a scenario is active a red badge sits in the bottom-left corner, with an
**exit** link. The selection is a cookie (`pkuru_scenario`), so it only affects
the browser that set it. Other browsers, other Playwright contexts and other
people on the same dev server keep seeing real data. The backend on :4555 is
never replaced.

Scripts can skip the cookie and send a header instead:

```sh
curl -s http://localhost:3000/graphql -H 'content-type: application/json' \
  -H 'x-pkuru-scenario: new-user' \
  -d '{"query":"{ viewer { user { id } profile { email } } }"}'
```

In Playwright, set either one on the context:

```ts
await context.addCookies([{ name: "pkuru_scenario", value: "new-user", url: "http://localhost:3000" }]);
// or
await context.setExtraHTTPHeaders({ "x-pkuru-scenario": "new-user" });
```

The page is server-rendered before React hydrates it, so a click that lands
before hydration does nothing. Wait for
`typeof window.__RELAY_DATA?.push === "function"`, and retry the first click
until it has an effect.

### Scenarios included

| Name | Mode | State |
| --- | --- | --- |
| `new-user` | mock | Signed in, profile incomplete. Gated actions (saving availability, joining an event) open the profile modal. |
| `signed-out` | mock | No session. |
| `me-incomplete-profile` | overlay | Your real session and data, but your own profile reads as empty everywhere: name, email, bio, gender and rating. Sign in first. Saving a profile writes to your dev account. |
| `me-no-saved-card` | overlay | Your real session and data, but no card on file: joining a priced event opens the Stripe card form, and a joined-but-unpaid spot offers "Save card" instead of "Join with saved card". Saving uses Stripe test mode (card 4242 4242 4242 4242) on your dev account. |

### Writing one

A scenario is a file `dev/scenarios/<name>.mjs` (lowercase letters, digits,
`-` and `_`). Files starting with `_` are helpers, not scenarios.

```js
import { signedInViewer } from "./_shared.mjs";

export default {
  description: "One line for the index page.",
  mode: "mock", // "mock" (default) or "overlay"
  mocks: {
    Query: { viewer: {} },
    Viewer: signedInViewer(),
    User: { lineUsername: "Aki", email: null },
  },
  // Optional. Runs on every response's data; required for overlay mode.
  // context: { operation: "query" | "mutation", viewerId } where viewerId is
  // the signed-in user's id (from the response, or looked up once per session).
  patch: (operationName, data, variables, context) => data,
};
```

Edits to a scenario file apply on the next request; no restart. Edits to
`_shared.mjs` or `dev/scenario/*` need a dev server restart.

**mock** mode answers `/graphql` without the backend. **overlay** mode sends
the request to the real backend with your real cookie, then passes the response
through `patch`. Use overlay when the state you want is "my account, but with
one thing different". A streamed (`@defer`) response is passed through
unpatched; only `/defertest` uses `@defer`.

In overlay mode, patch records by id, not by path. The app keeps one record
per id, and the same user or event usually arrives under several paths:
`viewer.user` and `viewer.profile`, RSVP lists, mutation payloads. Blanking
one path loses to any unpatched copy in the same or a later response.
`patchRecords` from `_shared.mjs` changes every object with a given id,
touching only fields the query selected:

```js
import { patchRecords } from "./_shared.mjs";

patch: (_op, data, _vars, { operation, viewerId }) =>
  operation === "mutation" ? data : patchRecords(data, viewerId, { email: null, lineUsername: "" }),
```

Leaving mutation responses alone lets a flow finish naturally: save the
profile and the page shows what you saved until the next reload. Overlay
mutations are real writes to the local dev database.

### The mock vocabulary

`mocks` is keyed by GraphQL type name. Each entry is either an object of field
values or a function that returns one. The function form runs once per object
of that type, with the parent object as its argument. A field value may itself
be a function `(source, args, info) => value`, for fields whose answer depends
on arguments, such as `User.rating(activitySlug:)`.

For each field the engine uses the first of:

1. a value already on the object, including an explicit `null`, such as
   `Viewer: { user: { id: "user-1" } }` giving the user its id;
2. the mock for the object's type, then for the interfaces it implements;
3. a default.

| Field type | Default |
| --- | --- |
| nullable object or scalar | `null`. So `Query.viewer` is signed out unless a scenario says otherwise. |
| any list | `[]` |
| non-null object, interface or union | `{}`, filled in field by field |
| `ID!` | `"<Type>:<path>"`, unique per object |
| `String!` / `Int!`, `Float!` / `Boolean!` | `""` / `0` / `false` |
| enum | its first value |
| `Datetime!` | `2026-01-01T00:00:00.000Z` |

A field called with an `id` argument (`node(id:)`, `event(id:)`) returns an
object with that id unless the scenario gives it another. Root fields like
`event`, `user`, `club` and `location` are nullable, so by the rule above they
are null until a mock supplies an object: `Query: { event: {} }` (the id is
filled in from the argument), or a function such as
`Query: { user: (_, args) => ({ id: args.id }) }`. Abstract types
resolve to `__typename` when the mock sets one, otherwise to the type named in
a default id, otherwise to the first possible type.

Rules that keep Relay happy:

- **The session user and the profile are one record.** `viewer.user` and
  `viewer.profile` must have the same `id` (`signedInViewer()` does this). If
  they differ, Relay stores two users and the fields selected under one never
  reach the other.
- **Never give two objects the same id** unless they really are the same
  record. Relay merges records by id, so list items sharing an id collapse into
  one. The defaults are already unique.
- **Keep `User.locale` matching the URL's language** (`"en"` for unprefixed
  paths). The app redirects when they differ.

GraphQL errors from a mock, such as a string where an object was selected or
`null` on a non-null field, are logged in the dev server console with the
scenario's name.

### How it works

`server.js` mounts `dev/scenario/middleware.mjs` ahead of Vite in development
only. With no scenario selected, `/graphql` passes through to Vite's proxy
untouched. That middleware must not read the request body before calling
`next()`, or the proxied request hangs. In development the server render also
fetches from this server (`SSR_API_ENDPOINT`, read in
`server/NetworkUtils.res`), so SSR and the browser always see the same backend,
real or mocked. As a side effect SSR now follows `API_PROXY_TARGET` like the
browser does.

`/api/auth` is not intercepted, so better-auth screens (login, email
verification) still reflect your real session.

## Storybook

```sh
nvm use                 # Node 22, from .nvmrc
yarn storybook          # http://localhost:6006
yarn storybook:smoke    # with Storybook running: render every story, fail on errors
yarn build-storybook    # static build in storybook-static/
```

Storybook 10 needs Node 20.19+ or 22.12+. The repo's `.nvmrc` pins Node 22,
the same major as the production image. nvm's global default is left alone,
so run `nvm use` in each new terminal; on an older Node, Storybook exits with a
message saying so. `yarn lint` needs it too: the Storybook lint plugin is
ESM-only, and Node 20 fails to load it with `ERR_REQUIRE_ESM`.

Stories live in `src/stories/<level>/`, one `<Component>.stories.tsx` per
component beside the ReScript wrapper it renders, `<Component>Story.res`.
Keeping them out of `src/components` keeps the component folders readable.
`.storybook/preview.tsx` wraps every story in what the app provides: Tailwind,
the English catalogs, the language provider, a router, and a Relay environment.

- **Theme:** the toolbar's Theme switch renders the story in light or dark
  mode. It sets the same `dark` class the app's layout does, on `<html>`, so
  dialogs and drawers are themed too.
- **Router:** components that read the URL or their route's loader data take
  `parameters.router`, e.g.
  `{ path: "events/:eventId", url: "/events/evt-1", loaderData: {...} }`.
  Without it the story renders at `/`.
- **Smoke test:** `yarn storybook:smoke [words...] [--dark] [--mobile] [--shots=dir]`
  renders every story, or those whose id contains a word, in Chrome. A story
  fails when it doesn't finish rendering, its play function throws, or the
  page logs an error. Mock warnings, meaning a mock of the wrong shape, are
  listed too. A failed story is retried once and listed as flaky if it then
  passes. `--mobile` renders at 390px and reports play functions that expect
  the desktop layout as notes instead of failures. It drives the
  preview directly because Storybook's own test runner needs vitest 3+.
- **Story helpers:** `src/stories/support.ts` has `must(value, what)` in place
  of `!` assertions and `pending()` for a request that never answers.

### The organism collection

`src/stories/organisms/` has stories for 96 of the 113 organisms, 563 in all.
They cover each component's real states, and every one passes
`yarn storybook:smoke` in light and dark. The rest are unused, or render no UI
of their own.

Shared fixtures live beside the stories. Import them rather than building new
rosters:

| Module | What it gives you |
| --- | --- |
| `StoryFixturesEvent` | A 14-player Tokyo roster with initials avatars, plus builders for RSVP, user, payment and connection mocks. |
| `StoryFixturesEventPage` | Activity feeds, invite candidates, recommendations and availability days for the event page sections. |
| `StoryFixturesDiscovery` | A fortnight of events, venues and court openings seen from Wed 14 Oct 2026, and `shiftClock` to pin "today" for date-grouped lists. |
| `StoryFixturesProfile` | A 22-player roster with generated portraits for ratings, match history and member search. |
| `StoryFixturesMatch` | A 20-player roster, `eventMock`, and hooks that turn RSVPs into `Rating.Player.t` with real avatar fragment refs. |
| `StoryFixturesSession` | Check-ins, guests, seed adjustments, recorded rounds and a sample event-state export. |
| `StoryFixturesTools` | Saved evenings for EventManager and the wait for its storage to load. |
| `StoryFixturesServices` | Stand-ins for the kiosk camera and analysis sidecar, Google Places, Stripe and the AI assistant. Nothing reaches a real service. |

When a component logs a genuine React error, a story may mute exactly that
message with a decorator, as `EventFullNames.stories.tsx` does. Record the bug
instead of hiding it silently.

### A story with Relay data

A component that takes a fragment ref needs a query to get one. Add a small
ReScript wrapper next to the component that runs a query spreading the
fragment and renders the component. `@genType` gives the story typed props and
the operation to hand to Storybook:

```rescript
// src/stories/organisms/ProfileModalStory.res
module Query = %relay(`
  query ProfileModalStoryQuery {
    ...ProfileModal_viewer
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

@genType
let query: concreteRequest = ProfileModalStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~isOpen=true) => {
  let data = Query.use(~variables=())
  <ProfileModal isOpen onClose={() => ()} query=data.fragmentRefs />
}
```

Then run `yarn rescript-relay-compiler` and `yarn res:build`, and write the
story against the generated `ProfileModalStory.gen.tsx`:

```tsx
import { make as ProfileModalStory, query } from "./ProfileModalStory.gen";

export default {
  component: ProfileModalStory,
  parameters: { relay: { query, scenario: "new-user" } },
};

export const EmailOnFile = {
  parameters: {
    relay: { query, scenario: "new-user", mocks: { User: { email: "player@example.com" } } },
  },
};
```

`parameters.relay` takes:

- `query`: the operation to load before the story renders.
- `variables`: optional.
- `scenario`: optional. Starts from that dev scenario's `mocks`.
- `mocks`: optional, merged over the scenario type by type and field by field.

Storybook deep-merges a story's parameters into its component's, so a story
can override single fields: `parameters: { relay: { mocks: { Event: { price: 1500 } } } }`
keeps the component-level query and every other mock.

A component without Relay data still gets a small wrapper when its props are
ReScript records or variants: build the fixtures in ReScript, where the types
are checked, and expose a `~state` poly-variant prop that picks one, so each
story is one preset.

The query result is in the store before the first render, so the component
never suspends and a play function can assert immediately. Later requests from
the story, such as refetches and mutations, are answered from the same mocks.
See `ProfileModal.stories.tsx` and `DuprConnectCard.stories.tsx`.

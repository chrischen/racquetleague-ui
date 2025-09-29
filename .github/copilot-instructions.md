# AI Coding Agent Instructions for Racquet League UI

## Project Overview

This is a **ReScript + React + GraphQL Relay** racquet sports league management application with **server-side rendering (SSR)**, **streaming**, and **internationalization**. The stack combines modern web technologies: React 18 SSR, Relay Modern, ReScript, Vite, Tailwind CSS, and Lingui i18n.

## Architecture Patterns

### Component Organization (Atomic Design)

- `src/components/atoms/` - Basic UI primitives (buttons, inputs, typography)
- `src/components/molecules/` - Simple combinations (form groups, tooltips, navigation items)
- `src/components/organisms/` - Complex components (event headers, RSVP sections, forms)
- `src/components/pages/` - Full page layouts and content
- `src/components/routes/` - Route-specific loaders and components
- `src/components/shared/` - Cross-cutting utilities and providers

### GraphQL Relay Integration

**Every component with data needs follows this pattern:**

1. **Fragment Definition:** Define GraphQL fragments in each component

```rescript
module Fragment = %relay(`
  fragment EventHeader_event on Event {
    title
    startDate
    endDate
    club { name slug }
  }
`)
```

2. **Fragment Usage:** Use fragments in components

```rescript
@react.component
let make = (~event: RescriptRelay.fragmentRefs<[> #EventHeader_event]>) => {
  let data = Fragment.use(event)
  // Component logic using data.title, data.club, etc.
}
```

3. **Query Preloading in Routes:** Route loaders preload queries for SSR

```rescript
@genType
let loader = async ({context}: LoaderArgs.t) => {
  Router.defer({
    WaitForMessages.data: EventQuery_graphql.load(
      ~environment=RelayEnv.getRelayEnv(context, RelaySSRUtils.ssr),
      ~variables={eventId},
      ~fetchPolicy=RescriptRelay.StoreOrNetwork,
    ),
    i18nLoaders: Localized.loadMessages(params.lang, loadMessages),
  })
}
```

### Critical Build Commands

```bash
npm run rescript-relay-compiler    # Regenerate GraphQL types after schema changes
npm run res:build          # Compile ReScript to JavaScript
npm run rescript-relay-compiler              # Compile Relay queries. Use this instead of the standard `npm run relay` command.
npm run build              # Full production build: rescript-relay-compiler + vite builds
npm run lingui:extract     # Extract i18n strings for translation
npm run lingui:compile     # Compile translations for runtime
```

**Always run `npm run graphql:generate` before `npm run res:build` when GraphQL fragments change.**

### ReScript Patterns

#### Component Definition

```rescript
%%raw("import { t } from '@lingui/macro'")  // Import macros at top
open LangProvider.Router                    // Open common modules

@react.component
let make = (~prop: string, ~optionalProp: option<int>=?) => {
  let ts = Lingui.UtilString.t  // Translation function shorthand
  // Component logic
}
```

#### Styling Integration

- **Tailwind CSS:** Primary styling system - use className strings
- **Linaria CSS-in-JS:** For dynamic/conditional styles - import `%%raw("import { css, cx } from '@linaria/core'")`
- **Shared Layout:** Use `Layout.Container` for consistent responsive containers

#### Option Handling Patterns

```rescript
data.field
->Option.map(value => /* transform */)
->Option.getOr(fallback)

// Chain operations with flatMap
data.user
->Option.flatMap(user => user.profile)
->Option.map(profile => profile.name)
->Option.getOr("Unknown")
```

### Internationalization with Lingui

1. **Wrap pages in `<WaitForMessages>`** for i18n support
2. **Use translation macros:** `t\`Text to translate\``for static text,`ts\`${variable} text\`` for interpolation
3. **Route loaders handle i18n:** Each route loads message catalogs via `Localized.loadMessages`

### Common Integration Patterns

#### Form Handling

- Use **React Hook Form** with ReScript bindings (`@greenlabs/ppx-rhf`)
- Forms typically in `organisms/` directory with validation schemas

#### Date/Time Operations

- **DateFns:** Primary date library (`@dck/rescript-date-fns`)
- **ReactIntl:** For date/time formatting with timezone support

```rescript
<ReactIntl.FormattedTime
  value={date->Util.Datetime.toDate}
  timeZone={timezone->Option.getOr("Asia/Tokyo")}
/>
```

#### Responsive Design

- **Mobile-first approach:** Use `flex-col sm:flex-row` pattern
- **Conditional rendering:** Check screen size with custom hooks like `useMobileDetection()`

### Development Workflow Issues

- **Relay compiler:** `npm run relay` often fails - use `npm run graphql:generate` instead
- **Type regeneration:** Always regenerate types after GraphQL changes before ReScript compilation
- **SSR:** Components must handle both server and client rendering (check for `window` availability)
- **Build order:** ReScript compilation must happen after GraphQL type generation

### File Naming Conventions

- **ReScript files:** `.res` extension, compile to `.re.mjs`
- **TypeScript compatibility:** Use `@genType` for TypeScript interop
- **Generated files:** `src/__generated__/` contains Relay-generated types
- **Route exports:** Routes export `Component`, `loader`, and optionally `HydrateFallbackElement`

This codebase prioritizes **type safety**, **performance** (SSR + streaming), and **developer experience** through strong tooling integration. Focus on maintaining these patterns when making changes.

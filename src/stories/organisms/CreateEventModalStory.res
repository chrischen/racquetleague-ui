// Storybook support for CreateEventModal.stories.tsx; the app never imports
// this. CreateEventModal is a thin shell: when the URL carries `create`, it
// opens a RouteModal around CreateEventPage.Body (the AI assistant band, the
// club and activity selector and the event form), with any prefill read from
// the same query string. The stories set that URL with `parameters.router`
// and hand the body's page query to .storybook/relay.tsx.

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** CreateEventPage's operation, for the story's `parameters.relay.query`.
    Its variables are the `locationId` from the URL ("" without one). */
@genType
let query: concreteRequest =
  CreateEventPageQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => <CreateEventModal />

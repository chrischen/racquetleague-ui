// Storybook support for NewPlanChooserModal.stories.tsx; the app never
// imports this. The modal fetches the viewer's booking-email addresses itself
// (NewPlanChooserModalQuery); the story hands that same operation to
// .storybook/relay.tsx so they are in the store before it opens.

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The modal's own operation, for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = NewPlanChooserModalQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~onClose=() => (), ~onCreateEvent=() => ()) =>
  <NewPlanChooserModal onClose onCreateEvent />

// Storybook support for EventFullNames.stories.tsx; the app never imports
// this. The collapsible guest list of players' full names.
module Query = %relay(`
  query EventFullNamesStoryQuery {
    event(id: "evt-story-1") {
      ...EventFullNames_event
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventFullNamesStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    <div className="max-w-sm font-sans">
      <EventFullNames event=event.fragmentRefs />
    </div>
  | None => React.null
  }
}

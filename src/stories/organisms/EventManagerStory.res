// Storybook support for EventManager.stories.tsx; the app never imports this.
// EventManager restores the whole evening (check-ins, payments, walk-ins,
// rounds, scores, seed adjustments) from its TinyBase store on mount, so the
// wrapper writes the chosen state into that store first (StoryFixturesTools)
// and remounts the manager whenever the state changes. The event and its RSVPs
// come from the shared match roster (StoryFixturesMatch.eventMock).
module Query = %relay(`
  query EventManagerStoryQuery {
    event(id: "evt-story-manager") {
      id
      ...EventManager_event
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventManagerStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~state: StoryFixturesTools.managerState=#roundInProgress, ~debug=false) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    let key = (state :> string) ++ (debug ? "-debug" : "")
    <StoryFixturesTools.Manager.Storage
      key seed={() => StoryFixturesTools.Manager.seed(event.id, state)}>
      <EventManager event=event.fragmentRefs eventId=event.id debug />
    </StoryFixturesTools.Manager.Storage>
  | None => React.null
  }
}

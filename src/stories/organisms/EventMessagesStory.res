// Storybook support for EventMessages.stories.tsx; the app never imports
// this. The classic event page's activity card, a fragment on Query (the
// event's topic in messagesByTopic) spread with the story event's topic.
module Query = %relay(`
  query EventMessagesStoryQuery {
    ...EventMessages_query @arguments(topic: "evt-story-1.updated")
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventMessagesStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  // The event's start, which colours late cancellations (red within 24
  // hours of it, amber within 48).
  ~eventStartDate="2026-10-15T10:00:00.000Z",
  // None: signed out. Some(true) adds the status-message box.
  ~viewerHasRsvp: option<bool>=?,
) => {
  let data = Query.use(~variables=())
  <div className="max-w-xl bg-gray-50 p-4">
    <EventMessages
      queryRef=data.fragmentRefs
      eventStartDate={Date.fromString(eventStartDate)}
      eventId=StoryFixturesEventPage.eventId
      ?viewerHasRsvp
    />
  </div>
}

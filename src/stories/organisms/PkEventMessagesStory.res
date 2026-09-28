// Storybook support for PkEventMessages.stories.tsx; the app never imports
// this. The activity feed is a fragment on Query (the event's topic in
// messagesByTopic), spread here with the story event's topic, as PkEventPage
// spreads it with its own.
module Query = %relay(`
  query PkEventMessagesStoryQuery {
    ...PkEventMessages_query @arguments(topic: "evt-story-1.updated")
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PkEventMessagesStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  // `card`: the in-page activity card viewers who haven't joined see.
  // `footer`: the one-line chat row joined viewers get in the sticky footer.
  ~variant: [#card | #footer]=#card,
  // On the card, whether the viewer may post (joined the event).
  ~isJoined=false,
) => {
  let data = Query.use(~variables=())
  let eventId = StoryFixturesEventPage.eventId
  switch variant {
  | #card =>
    // The page's card column on its grey ground.
    <div className="mx-auto max-w-2xl bg-gray-50 py-3 dark:bg-[#18191c]">
      <PkEventMessages queryRef=data.fragmentRefs eventId isJoined />
    </div>
  | #footer =>
    <div className="flex min-h-screen flex-col justify-end bg-gray-50 dark:bg-[#18191c]">
      <div className="border-t border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#1e1f23]">
        <PkEventMessages.FooterChat queryRef=data.fragmentRefs eventId />
      </div>
    </div>
  }
}

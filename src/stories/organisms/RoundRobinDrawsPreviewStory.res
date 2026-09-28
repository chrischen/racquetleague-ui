// Storybook support for RoundRobinDrawsPreview.stories.tsx; the app never
// imports this. The preview runs its own query for the event, so the story
// loads that same operation (with `variables: { eventId }`) and the wrapper
// renders the component as PkEventPage does.

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The component's own operation, for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = RoundRobinDrawsPreviewQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~activitySlug: [#pickleball | #badminton]=#pickleball) => {
  let eventId = StoryFixturesEventPage.eventId
  <div className="mx-auto max-w-2xl bg-gray-50 py-3 dark:bg-[#18191c]">
    <RoundRobinDrawsPreview
      eventId
      managerHref={"/league/events/" ++ eventId ++ "/" ++ (activitySlug :> string) ++ "/manager"}
      className="mx-3"
    />
  </div>
}

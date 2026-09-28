// Storybook support for PkRSVPSection.stories.tsx; the app never imports
// this. The query mirrors PkEventPage: the section's fragment on the event,
// and the signed-in viewer's (their rating for this event, for the level
// restriction notice). Signed out, `viewer` is null and the section gets no
// user. The wrapper sets the section in the page's card column.
module Query = %relay(`
  query PkRSVPSectionStoryQuery {
    event(id: "evt-story-1") {
      ...PkRSVPSection_event
    }
    viewer {
      user {
        ...PkRSVPSection_user @arguments(eventId: "evt-story-1")
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PkRSVPSectionStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = () => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    <div className="mx-auto max-w-2xl bg-gray-50 py-3 dark:bg-[#18191c]">
      <PkRSVPSection
        event=event.fragmentRefs
        user=?{data.viewer->Option.flatMap(v => v.user)->Option.map(u => u.fragmentRefs)}
      />
    </div>
  | None => React.null
  }
}

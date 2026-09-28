// Storybook support for RSVPSection.stories.tsx; the app never imports this.
// The classic event page's RSVP card. The query mirrors that page: the
// section's paginated fragment on the event, and the signed-in viewer's
// (their rating for this event). Signed out, `viewer` is null.
module Query = %relay(`
  query RSVPSectionStoryQuery {
    event(id: "evt-story-1") {
      ...RSVPSection_event
    }
    viewer {
      user {
        ...RSVPSection_user @arguments(eventId: "evt-story-1")
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = RSVPSectionStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~onBeforeJoin: option<(unit => unit) => unit>=?) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    // The page's sidebar column. Below the md breakpoint the card becomes a
    // bar fixed to the bottom of the window.
    <div className="max-w-md">
      <RSVPSection
        event=event.fragmentRefs
        user={data.viewer->Option.flatMap(v => v.user)->Option.map(u => u.fragmentRefs)}
        ?onBeforeJoin
      />
    </div>
  | None => React.null
  }
}

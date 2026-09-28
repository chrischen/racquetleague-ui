// Storybook support for EventLocationAvailability.stories.tsx; the app never
// imports this. On the event page the panel sits at the bottom of the
// expanded location card, for the event's owner and club admins only (the
// server returns no availability to anyone else, and the panel then renders
// nothing). The wrapper draws that card around it.
module Query = %relay(`
  query EventLocationAvailabilityStoryQuery {
    event(id: "evt-story-1") {
      ...EventLocationAvailability_event
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = EventLocationAvailabilityStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  // The name used for courts the scraper didn't name.
  ~genericCourtName="Courts",
) => {
  let data = Query.use(~variables=())
  switch data.event {
  | Some(event) =>
    <div className="mx-auto max-w-2xl bg-gray-50 py-3 dark:bg-[#18191c]">
      <div
        className="mx-3 rounded-xl border border-gray-200 bg-white px-4 pb-4 pt-3 dark:border-[#2a2b30] dark:bg-[#1e1f23]">
        <p className="font-mono text-xs text-gray-500 dark:text-gray-400">
          {"Ariake Tennis Forest Park"->React.string}
        </p>
        <p className="mt-0.5 font-mono text-xs text-gray-500 dark:text-gray-400">
          {"2-2-22 Ariake, Koto-ku, Tokyo"->React.string}
        </p>
        <EventLocationAvailability event=event.fragmentRefs genericCourtName />
      </div>
    </div>
  | None => React.null
  }
}

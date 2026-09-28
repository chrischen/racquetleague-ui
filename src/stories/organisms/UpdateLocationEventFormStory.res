// Storybook support for UpdateLocationEventForm.stories.tsx; the app never
// imports this. The query mirrors UpdateEventPage and CopyEventPage: the
// venue, the event being edited or copied, and the club/activity choices at
// the root. The wrapper draws those pages' column around the form.
module Query = %relay(`
  query UpdateLocationEventFormStoryQuery {
    location(id: "loc-ariake") {
      ...CreateLocationEventForm_location
    }
    event(id: "evt-story-1") {
      ...UpdateLocationEventForm_event
    }
    ...ClubActivitySelector_query
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = UpdateLocationEventFormStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  // CopyEventPage: a new event from this one, on today's date.
  ~isCopy=false,
  // Copying uses the viewer's own Stripe account rather than the event's.
  ~viewerStripeChargesEnabled=false,
) => {
  let data = Query.use(~variables=())
  switch (data.event, data.location) {
  | (Some(event), Some(location)) =>
    <div className="min-h-screen w-full bg-gray-50 text-gray-900 dark:bg-[#111111] dark:text-gray-100">
      <div className="mx-auto max-w-2xl space-y-6 px-4 py-8">
        <UpdateLocationEventForm
          event=event.fragmentRefs
          location=location.fragmentRefs
          query=data.fragmentRefs
          isCopy
          viewerStripeChargesEnabled
        />
      </div>
    </div>
  | _ => React.null
  }
}

// Storybook support for CreateLocationEventForm.stories.tsx; the app never
// imports this. Drawn as CreateEventPage draws it: the "Club & Activity"
// selector above the form, reporting the organiser's club, activity and
// whether the inline new-club form is open, which the form needs for the
// event's club and to block submitting while a club is half made. The query
// holds the venue and the selector's clubs and activities.
module Query = %relay(`
  query CreateLocationEventFormStoryQuery {
    location(id: "loc-ariake") {
      ...CreateLocationEventForm_location
    }
    ...ClubActivitySelector_query
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = CreateLocationEventFormStoryQuery_graphql.node->Obj.magic

// What arrives with the form besides the venue.
//  #none:  a blank new event.
//  #draft: the event assistant's draft of a club's weekly session, marking the
//          sections it filled in.
//  #paidDraft: the same draft with a ¥1,500 fee, so the paid section is open.
@genType
type prefill = [#none | #draft | #paidDraft]

let draft = (~price=?): CreateLocationEventForm.prefilledValues => {
  title: "Thursday Night Doubles",
  details: "Courts 3 and 4 on the second floor. Indoor shoes only.\nBalls provided (Franklin X-40).",
  startDate: "2026-10-15T19:00",
  endDate: "21:30",
  timezone: "Asia/Tokyo",
  maxRsvps: 16,
  listed: true,
  tags: ["comp", "dupr", "3.5+"],
  cancelDeadline: 43200000,
  // Smart RSVP on: the form's default threshold (not exported by the form).
  smartRsvpThreshold: 0.005,
  ?price,
}

@genType @react.component
let make = (
  ~prefill: prefill=#none,
  // Without a venue the Location field is the venue search (Google Places).
  ~withVenue=true,
  // The viewer's own Stripe account can take charges.
  ~stripeChargesEnabled=false,
  ~onLocationSelected: option<string => unit>=?,
  ~onClubFormSubmitBlocked: option<unit => unit>=?,
) => {
  let data = Query.use(~variables=())
  let (selection, setSelection) = React.useState((): ClubActivitySelector.selection => {
    clubId: None,
    activityId: None,
    isAddingClub: false,
  })
  let (shake, setShake) = React.useState(() => 0)
  // Stable across renders: the form re-applies prefill whenever it changes.
  let prefilledValues = React.useMemo1(() =>
    switch prefill {
    | #none => None
    | #draft => Some(draft())
    | #paidDraft => Some(draft(~price=1500))
    }
  , [prefill])
  <div className="min-h-screen w-full bg-gray-50 text-gray-900 dark:bg-[#111111] dark:text-gray-100">
    <div className="mx-auto max-w-2xl space-y-4 px-4 py-8">
      <ClubActivitySelector
        query=data.fragmentRefs onChange={s => setSelection(_ => s)} triggerShake=shake
      />
      <CreateLocationEventForm
        location=?{withVenue ? data.location->Option.map(l => l.fragmentRefs) : None}
        onLocationSelected={id => onLocationSelected->Option.forEach(f => f(id))}
        stripeChargesEnabled
        ?prefilledValues
        selectedClub=?selection.clubId
        selectedActivity=?selection.activityId
        isClubFormOpen=selection.isAddingClub
        onClubFormSubmitBlocked={() => {
          setShake(n => n + 1)
          onClubFormSubmitBlocked->Option.forEach(f => f())
        }}
      />
    </div>
  </div>
}

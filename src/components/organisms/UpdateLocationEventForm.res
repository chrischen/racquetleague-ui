module EventFragment = %relay(`
  fragment UpdateLocationEventForm_event on Event {
    id
    title
    details
    maxRsvps
    minRating
    activity {
      id
      name
      slug
    }
    club {
      id
    }
    startDate
    endDate
    listed
    timezone
    tags
    price
    cancelDeadline
    smartRsvpThreshold
    chargesEnabled
  }
`)

@react.component
let make = (~event, ~location, ~query, ~isCopy=false, ~viewerStripeChargesEnabled=false) => {
  let eventData = EventFragment.use(event)

  let (clubSelection, setClubSelection) = React.useState((): ClubActivitySelector.selection => {
    clubId: eventData.club->Option.map(c => c.id),
    activityId: eventData.activity->Option.map(a => a.id),
    isAddingClub: false,
  })
  let (shakeCounter, setShakeCounter) = React.useState(() => 0)

  // The form takes wall-clock strings in the event's zone, not the browser's.
  let tz = eventData.timezone->Option.getOr(Util.Timezone.fallback)
  let wallClock = d => Util.Timezone.toWallClock(d->Util.Datetime.toDate, tz)
  let timeOfDay = wall => wall->String.slice(~start=11, ~end=16)

  // For copy: today's date + source time-of-day. For update: source datetime.
  let startDate = if isCopy {
    eventData.startDate->Option.map(sd => {
      let today = Util.Timezone.toWallClock(Js.Date.make(), tz)->String.slice(~start=0, ~end=10)
      today ++ "T" ++ timeOfDay(wallClock(sd))
    })
  } else {
    eventData.startDate->Option.map(wallClock)
  }

  // Both modes keep the source end time-of-day; the form rolls an end at or
  // before the start over to the next day, so a copy keeps its duration.
  let endDate = eventData.endDate->Option.map(d => timeOfDay(wallClock(d)))

  let prefilledValues: CreateLocationEventForm.prefilledValues = {
    title: ?eventData.title,
    activitySlug: ?eventData.activity->Option.flatMap(a => a.slug),
    clubId: ?eventData.club->Option.map(c => c.id),
    maxRsvps: ?eventData.maxRsvps,
    minRating: ?eventData.minRating,
    ?startDate,
    ?endDate,
    details: ?eventData.details,
    listed: ?eventData.listed,
    timezone: ?eventData.timezone,
    tags: ?eventData.tags,
    price: ?eventData.price,
    cancelDeadline: ?eventData.cancelDeadline,
    smartRsvpThreshold: ?eventData.smartRsvpThreshold,
    // Editing and copying both mirror the source event, so the form must not
    // layer its new-event defaults over fields the source event left unset.
    fromExistingEvent: true,
  }

  <>
    <ClubActivitySelector
      query
      initialClubId=?{eventData.club->Option.map(c => c.id)}
      initialActivityId=?{eventData.activity->Option.map(a => a.id)}
      onChange={sel => setClubSelection(_ => sel)}
      triggerShake=shakeCounter
    />
    <CreateLocationEventForm
      eventId=?{isCopy ? None : Some(eventData.id)}
      location
      stripeChargesEnabled={isCopy ? viewerStripeChargesEnabled : eventData.chargesEnabled}
      prefilledValues
      selectedClub=?clubSelection.clubId
      selectedActivity=?clubSelection.activityId
      isClubFormOpen=clubSelection.isAddingClub
      onClubFormSubmitBlocked={() => setShakeCounter(n => n + 1)}
    />
  </>
}

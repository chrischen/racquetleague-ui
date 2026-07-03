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
    owner {
      stripeChargesEnabled
    }
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

  // For copy: today's date + source time-of-day. For update: source datetime.
  let startDate = if isCopy {
    eventData.startDate->Option.map(sd => {
      let sourceStart = sd->Util.Datetime.toDate
      let timeStr = sourceStart->DateFns.formatWithPattern("HH:mm")
      let todayStr = Js.Date.make()->DateFns.formatWithPattern("yyyy-MM-dd")
      todayStr ++ "T" ++ timeStr
    })
  } else {
    eventData.startDate->Option.map(d =>
      d->Util.Datetime.toDate->DateFns.formatWithPattern("yyyy-MM-dd'T'HH:mm")
    )
  }

  // For copy: today's start + source duration. For update: source end time.
  let endDate = if isCopy {
    switch (eventData.startDate, eventData.endDate, startDate) {
    | (Some(sd), Some(ed), Some(newStart)) => {
        let sourceStart = sd->Util.Datetime.toDate
        let sourceEnd = ed->Util.Datetime.toDate
        let durationHours =
          (sourceEnd->DateFns.getTime -. sourceStart->DateFns.getTime) /. (1000.0 *. 60.0 *. 60.0)
        Some(
          newStart
          ->DateFns.parseISO
          ->DateFns.addHours(durationHours)
          ->DateFns.formatWithPattern("HH:mm"),
        )
      }
    | _ => None
    }
  } else {
    eventData.endDate->Option.map(d => d->Util.Datetime.toDate->DateFns.formatWithPattern("HH:mm"))
  }

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
      stripeChargesEnabled={isCopy
        ? viewerStripeChargesEnabled
        : eventData.owner->Option.flatMap(o => o.stripeChargesEnabled)->Option.getOr(false)}
      prefilledValues
      selectedClub=?clubSelection.clubId
      selectedActivity=?clubSelection.activityId
      isClubFormOpen=clubSelection.isAddingClub
      onClubFormSubmitBlocked={() => setShakeCounter(n => n + 1)}
    />
  </>
}

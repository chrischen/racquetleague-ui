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
  }
`)

@react.component
let make = (~event, ~location, ~query) => {
  let eventData = EventFragment.use(event)

  let (clubSelection, setClubSelection) = React.useState(() =>
    ({
      clubId: eventData.club->Option.map(c => c.id),
      activityId: eventData.activity->Option.map(a => a.id),
      isAddingClub: false,
    }: ClubActivitySelector.selection)
  )
  let (shakeCounter, setShakeCounter) = React.useState(() => 0)

  // Convert event data to prefilled values for CreateLocationEventForm
  let prefilledValues: CreateLocationEventForm.prefilledValues = {
    title: ?eventData.title,
    activitySlug: ?eventData.activity->Option.flatMap(a => a.slug),
    clubId: ?eventData.club->Option.map(c => c.id),
    maxRsvps: ?eventData.maxRsvps,
    minRating: ?eventData.minRating,
    startDate: ?eventData.startDate->Option.map(d =>
      d->Util.Datetime.toDate->DateFns.formatWithPattern("yyyy-MM-dd'T'HH:mm")
    ),
    endDate: ?eventData.endDate->Option.map(d =>
      d->Util.Datetime.toDate->DateFns.formatWithPattern("HH:mm")
    ),
    details: ?eventData.details,
    listed: ?eventData.listed,
    timezone: ?eventData.timezone,
    tags: ?eventData.tags,
    price: ?eventData.price,
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
      eventId=eventData.id
      location
      prefilledValues
      selectedClub=?clubSelection.clubId
      selectedActivity=?clubSelection.activityId
      isClubFormOpen=clubSelection.isAddingClub
      onClubFormSubmitBlocked={() => setShakeCounter(n => n + 1)}
    />
  </>
}


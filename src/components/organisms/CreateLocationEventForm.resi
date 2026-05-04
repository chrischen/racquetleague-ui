type prefilledValues = {
  title?: string,
  activitySlug?: string,
  clubId?: string,
  maxRsvps?: int,
  minRating?: float,
  startDate?: string,
  endDate?: string,
  details?: string,
  listed?: bool,
  timezone?: string,
  tags?: array<string>,
  price?: int,
  cancelDeadline?: int,
}

@react.component
let make: (
  ~eventId: string=?,
  ~location: RescriptRelay.fragmentRefs<[> #CreateLocationEventForm_location]>,
  ~prefilledValues: prefilledValues=?,
  ~selectedClub: string=?,
  ~selectedActivity: string=?,
  ~isClubFormOpen: bool=?,
  ~onClubFormSubmitBlocked: unit => unit=?,
) => React.element

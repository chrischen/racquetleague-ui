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
}
@react.component
let make: (
  ~eventId: string=?,
  ~location: RescriptRelay.fragmentRefs<[> #CreateLocationEventForm_location]>,
  ~query: RescriptRelay.fragmentRefs<[> #CreateLocationEventForm_query]>,
  ~prefilledValues: prefilledValues=?,
) => React.element

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
  smartRsvpThreshold?: float,
  fromExistingEvent?: bool,
}

// New events default to a 24h cancel deadline (ms); shared with callers that
// create events without the form.
let defaultCancelDeadline: int

@react.component
let make: (
  ~eventId: string=?,
  ~location: RescriptRelay.fragmentRefs<[> #CreateLocationEventForm_location]>=?,
  ~onLocationSelected: string => unit=?,
  ~autoSearchAddress: string=?,
  ~stripeChargesEnabled: bool=?,
  ~prefilledValues: prefilledValues=?,
  ~selectedClub: string=?,
  ~selectedActivity: string=?,
  ~isClubFormOpen: bool=?,
  ~onClubFormSubmitBlocked: unit => unit=?,
  ~proposedEvents: array<EventProposal.t>=?,
  ~onProposedEventsChange: (array<EventProposal.t> => array<EventProposal.t>) => unit=?,
  ~onCancelProposal: unit => unit=?,
) => React.element

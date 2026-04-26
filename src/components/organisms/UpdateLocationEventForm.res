%%raw("import { t } from '@lingui/macro'")

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

  <CreateLocationEventForm eventId=eventData.id location query prefilledValues />
}

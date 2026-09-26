// An accepted multi-event proposal from the assistant. The schedule supplies
// what differs per event - venue, start and end - and the create form supplies
// everything else, once, for all of them. The page owns the list; the form
// reads it and reports venue picks and create outcomes back through it.

type venue =
  // The assistant named an address that is still being looked up.
  | Resolving
  | Resolved({id: string, name: string})
  // No address, or the lookup found nothing: the organizer picks the venue.
  | Unresolved

type status =
  | Pending
  | Created(string)
  | Failed

type t = {
  key: string,
  address: option<string>,
  startDate: Date.t,
  endDate: Date.t,
  venue: venue,
  status: status,
}

// A draft's date as an instant, or nothing when it is missing ("") or does not
// parse. Formatting an invalid date throws, so drafts are checked here first.
let instantOf = (value: string): option<Date.t> => {
  let date = Js.Date.fromString(value)
  date->Js.Date.getTime->Float.isNaN ? None : Some(date)
}

// `batch` tells one acceptance's events from another's, so a venue lookup
// started for an earlier batch can never land on a later one. A draft without
// a usable start and end is left out: the schedule can't be edited here, so it
// could never be created.
let ofEventDetails = (~batch: string, events: array<AITypes.eventDetails>): array<t> =>
  events
  ->Array.mapWithIndex((event, index) =>
    switch (instantOf(event.date), instantOf(event.time)) {
    | (Some(startDate), Some(endDate)) =>
      Some({
        key: `${batch}-${index->Int.toString}`,
        address: event.location,
        startDate,
        endDate,
        venue: event.location->Option.isSome ? Resolving : Unresolved,
        status: Pending,
      })
    | _ => None
    }
  )
  ->Array.filterMap(event => event)

let update = (events: array<t>, key: string, change: t => t): array<t> =>
  events->Array.map(event => event.key == key ? change(event) : event)

let isResolved = (event: t) =>
  switch event.venue {
  | Resolved(_) => true
  | Resolving | Unresolved => false
  }

let isCreated = (event: t) =>
  switch event.status {
  | Created(_) => true
  | Pending | Failed => false
  }

let venueId = (event: t) =>
  switch event.venue {
  | Resolved({id}) => Some(id)
  | Resolving | Unresolved => None
  }

// Storybook support for CourtPseudoEventRow.stories.tsx; the app never
// imports this. CourtPseudoEventRow is one venue's court opening, shown when a
// CourtPseudoEventGroup in the Discover feed is expanded: the opening's start
// and length, the venue, courts and players in the slot, the viewer's own time
// in it, and a button to mark or edit availability for just this slot.
// Expanded, it lists the other players and the venue's court card. The bands
// come from the shared fixtures, grouped as PkEventsDayFeed groups them.

/** The windows the row saves, in hours (19.5 is 19:30). */
@genType
type window = {start: float, end: float}

@genType @react.component
let make = (
  ~state: [
    | #viewerAvailable
    | #othersOnly
    | #nobodyYet
    | #unpricedVenue
  ]=#viewerAvailable,
  ~onAvailabilityChange: option<array<window> => unit>=?,
) => {
  // Wed 14's afternoon run holds Toyosu 13–17, Ginza 15–18, Minato 18–21 and
  // Ginza 20–22, in start order.
  let afternoon =
    StoryFixturesDiscovery.courtGroupsOn(StoryFixturesDiscovery.wed14)
    ->Array.get(1)
    ->Option.map(g => g.bands)
    ->Option.getOr([])
  let bandAt = (bands: array<TimeWindow.courtAvailabilityBand>, venueName, start) =>
    bands->Array.find(b =>
      b.start == start &&
        b.segments->Array.some(s =>
          s.slots->Array.some(slot => slot.court.location.name == venueName)
        )
    )
  // A venue the scraper knew only by its booking page: no hourly rollup, so
  // no surface or price, and the generic "Court" name.
  let unpriced: TimeWindow.courtAvailability = {
    id: "court-unknown-2026-10-14",
    location: {
      id: "https://reserva.be/kotosports",
      name: "Court",
      reservationUrl: Some("https://reserva.be/kotosports"),
    },
    courtName: None,
    hourlyStats: [],
    intents: [{id: 0, start: 16., end: 19.}],
  }
  let (band, availability, players) = switch state {
  // Minato 18–21: the viewer saved 18–22, five others overlap.
  | #viewerAvailable => (
      afternoon->bandAt("Minato Sports Center", 18.),
      StoryFixturesDiscovery.viewerIntentsOn(StoryFixturesDiscovery.wed14),
      StoryFixturesDiscovery.slotPlayersOn(StoryFixturesDiscovery.wed14),
    )
  // Toyosu 13–17: two players overlap, the viewer hasn't said.
  | #othersOnly => (
      afternoon->bandAt("Toyosu Riverside Courts", 13.),
      [],
      StoryFixturesDiscovery.slotPlayersOn(StoryFixturesDiscovery.wed14),
    )
  // Ginza 15–18 with nobody's windows passed in.
  | #nobodyYet => (afternoon->bandAt("PickleOne Ginza", 15.), [], [])
  | #unpricedVenue => (
      TimeWindow.groupCourtAvailabilityIntoPseudoEventBands([unpriced])->Array.get(0),
      [],
      StoryFixturesDiscovery.slotPlayersOn(StoryFixturesDiscovery.wed14),
    )
  }
  let createEvent: CourtOpeningCard.createEventContext = {
    localDate: StoryFixturesDiscovery.wed14,
    activityId: PkEventsList.defaultActivityId,
  }
  <div
    className="max-w-4xl border-y border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#222326]">
    {switch band {
    | Some(band) =>
      <CourtPseudoEventRow
        band
        availability
        players
        isLastInGroup=true
        createEvent
        onAvailabilityChange={intents =>
          onAvailabilityChange->Option.forEach(cb =>
            cb(intents->Array.map(i => {start: i.start, end: i.end}))
          )}
      />
    | None => React.null
    }}
  </div>
}

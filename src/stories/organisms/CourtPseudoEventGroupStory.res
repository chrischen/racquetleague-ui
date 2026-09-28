// Storybook support for CourtPseudoEventGroup.stories.tsx; the app never
// imports this. CourtPseudoEventGroup is the cyan summary row PkEventsDayFeed
// puts in the Discover feed for a continuous run of open courts: the span,
// how many courts at how many venues, surface mix and price. "View slots"
// expands it into one CourtPseudoEventRow per venue opening. The groups are
// built from the shared fixtures exactly as PkEventsDayFeed builds them.

/** The windows the row saves, in hours (19.5 is 19:30). */
@genType
type window = {start: float, end: float}

@genType @react.component
let make = (
  ~state: [
    | #afternoonRun
    | #singleVenue
    | #morning
    | #noPlayers
  ]=#afternoonRun,
  ~onAvailabilityChange: option<array<window> => unit>=?,
) => {
  // (day, which of the day's groups, whether the viewer and other players
  // are shown)
  let (date, index, withPeople) = switch state {
  // Wed 14, 13:00–22:00: four openings at three venues, overlapping.
  | #afternoonRun => (StoryFixturesDiscovery.wed14, 1, true)
  // Mon 19, 18:00–22:00: one venue.
  | #singleVenue => (StoryFixturesDiscovery.mon19, 0, true)
  // Wed 14, 07:00–09:00: early courts, before the day's first event.
  | #morning => (StoryFixturesDiscovery.wed14, 0, true)
  // Sat 17 morning with nobody else's windows passed in.
  | #noPlayers => (StoryFixturesDiscovery.sat17, 0, false)
  }
  let groups = StoryFixturesDiscovery.courtGroupsOn(date)
  let createEvent: CourtOpeningCard.createEventContext = {
    localDate: date,
    activityId: PkEventsList.defaultActivityId,
  }
  <div
    className="max-w-4xl border-y border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#222326]">
    {switch groups->Array.get(index) {
    | Some(group) =>
      <CourtPseudoEventGroup
        group
        availability={withPeople ? StoryFixturesDiscovery.viewerIntentsOn(date) : []}
        players={withPeople ? StoryFixturesDiscovery.slotPlayersOn(date) : []}
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

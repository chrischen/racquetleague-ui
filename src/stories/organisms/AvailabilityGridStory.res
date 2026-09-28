// Storybook support for AvailabilityGrid.stories.tsx; the app never imports
// this. AvailabilityGrid is the horizontal weekly planner (one row per day,
// time running left to right) that VerticalAvailabilityGrid replaced on the
// availability page; nothing renders it today, but the page still builds its
// day data with this module's types. The week is Monday 12 to Sunday 18
// October, today Wednesday, drawn from the shared fixtures.

/** One edited day as the grid saves it. */
@genType
type interval = {startHour: int, endHour: int}
@genType
type dayUpdate = {isoDate: string, intervals: array<interval>}

@genType @react.component
let make = (
  // #planned: saved windows over other players' demand, the viewer's events
  // and open courts; #blank: none of it, a first visit.
  ~state: [#planned | #blank]=#planned,
  ~isSaving=false,
  ~onSave: option<array<dayUpdate> => unit>=?,
) => {
  let intl = ReactIntl.useIntl()
  let dates = StoryFixturesDiscovery.daysFrom("2026-10-12", 7)
  let planned = state == #planned
  let days = dates->Array.mapWithIndex((isoDate, i): AvailabilityGrid.dayData => {
    let date = Js.Date.fromString(isoDate ++ "T12:00:00+09:00")
    let format = options => intl->ReactIntl.Intl.formatDateWithOptions(date, options)
    {
      dayIdx: i,
      label: format(ReactIntl.dateTimeFormatOptions(~weekday=#short, ~timeZone="Asia/Tokyo", ())),
      dateLabel: format(
        ReactIntl.dateTimeFormatOptions(~month=#short, ~day=#numeric, ~timeZone="Asia/Tokyo", ()),
      ),
      isoDate,
      isWeekend: i >= 5,
      isToday: isoDate == StoryFixturesDiscovery.wed14,
      initialIntervals: planned
        ? StoryFixturesDiscovery.viewerAvailability
          ->Array.find(d => d.localDate == isoDate)
          ->Option.map(d =>
            d.intervals->Array.map(
              (iv): AvailabilityGrid.interval => {
                startHour: iv.startHour,
                endHour: iv.endHour,
              },
            )
          )
          ->Option.getOr([])
        : [],
    }
  })
  <AvailabilityGrid
    days
    isSaving
    onSave={changes =>
      onSave->Option.forEach(cb =>
        cb(
          changes->Array.map(c => {
            isoDate: c.isoDate,
            intervals: c.intervals->Array.map(iv => {startHour: iv.startHour, endHour: iv.endHour}),
          }),
        )
      )}
    existingEvents=?{planned
      ? Some(StoryFixturesDiscovery.byDate(dates, StoryFixturesDiscovery.existingEventsOn))
      : None}
    demand=?{planned
      ? Some(StoryFixturesDiscovery.byDate(dates, StoryFixturesDiscovery.demandOn))
      : None}
    courtAvailability=?{planned
      ? Some(StoryFixturesDiscovery.byDate(dates, StoryFixturesDiscovery.courtsOn))
      : None}
  />
}

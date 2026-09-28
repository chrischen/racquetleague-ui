// Storybook support for VerticalAvailabilityGrid.stories.tsx; the app never
// imports this. VerticalAvailabilityGrid is the availability page's planner:
// fifteen day columns from today, time running down, with the viewer's
// windows (lime chips), other players' demand (violet heat), the viewer's
// events (amber) and open courts (cyan silhouettes), then a summary listing
// the courts that cover each saved window. The days are built as
// AvailabilityPage builds them, from the shared fixtures, starting Wednesday
// 14 October.

/** One edited day as the grid saves it. */
@genType
type interval = {startHour: int, endHour: int}
@genType
type dayUpdate = {isoDate: string, intervals: array<interval>}

@genType @react.component
let make = (
  // #planned: saved windows plus everything around them; #firstVisit: the
  // same players, events and courts but nothing saved yet; #blank: an empty
  // area with nothing at all.
  ~state: [#planned | #firstVisit | #blank]=#planned,
  ~isSaving=false,
  ~onSave: option<array<dayUpdate> => unit>=?,
) => {
  let intl = ReactIntl.useIntl()
  let dates = StoryFixturesDiscovery.daysFrom(StoryFixturesDiscovery.fromDate, 15)
  let days = dates->Array.mapWithIndex((isoDate, i): VerticalAvailabilityGrid.dayData => {
    let date = Js.Date.fromString(isoDate ++ "T12:00:00+09:00")
    let format = options => intl->ReactIntl.Intl.formatDateWithOptions(date, options)
    let dow = date->Js.Date.getDay->Float.toInt
    {
      dayIdx: i,
      label: format(ReactIntl.dateTimeFormatOptions(~weekday=#short, ~timeZone="Asia/Tokyo", ())),
      dateLabel: format(
        ReactIntl.dateTimeFormatOptions(~month=#short, ~day=#numeric, ~timeZone="Asia/Tokyo", ()),
      ),
      isoDate,
      isWeekend: dow == 0 || dow == 6,
      isToday: i == 0,
      initialIntervals: state == #planned
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
  let context = state != #blank
  <VerticalAvailabilityGrid
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
    existingEvents=?{context
      ? Some(StoryFixturesDiscovery.byDate(dates, StoryFixturesDiscovery.existingEventsOn))
      : None}
    demand=?{context
      ? Some(StoryFixturesDiscovery.byDate(dates, StoryFixturesDiscovery.demandOn))
      : None}
    courtAvailability=?{context
      ? Some(StoryFixturesDiscovery.byDate(dates, StoryFixturesDiscovery.courtsOn))
      : None}
  />
}

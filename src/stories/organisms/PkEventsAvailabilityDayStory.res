// Storybook support for PkEventsAvailabilityDay.stories.tsx; the app never
// imports this. PkEventsAvailabilityDay is the availability row under each
// day's header in the events lists: the day header with its trigger, then a
// one-line summary of the viewer's saved windows, the day's events, players
// and courts, which opens the editor. The wrapper draws the header the way
// PkEventsList.Day (Discover) or ClubEventsList.Day (a club's schedule) does.
module Query = %relay(`
  query PkEventsAvailabilityDayStoryQuery {
    ...PkEventsAvailabilityDay_query @arguments(fromDate: "2026-10-14", toDate: "2026-10-28")
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PkEventsAvailabilityDayStoryQuery_graphql.node->Obj.magic

/** The window "Host event" hands over, in hours (19.5 is 19:30). */
@genType
type window = {start: float, end: float}

@genType @react.component
let make = (
  // The day in Tokyo, "YYYY-MM-DD", and its label in the list.
  ~localDate="2026-10-14",
  ~label="Today",
  // The day's event count, for the header.
  ~eventCount=0,
  // Discover; a club's schedule ("Add to <day>", club-scoped players); or a
  // location club's, whose editor also picks the level of the event it hosts.
  ~host: [#discover | #club | #locationClub]=#discover,
  ~onCreateEvent: option<(string, window) => unit>=?,
  ~onRefetchNeeded=() => (),
) => {
  let data = Query.use(~variables=())
  let availability = PkEventsAvailabilityDay.Fragment.use(data.fragmentRefs)
  let isLoggedIn = availability.viewer->Option.flatMap(v => v.user)->Option.isSome
  let intl = ReactIntl.useIntl()
  let (levelTags, setLevelTags) = React.useState(() => [LevelTagPills.allLevel])
  let dateDetails =
    intl->ReactIntl.Intl.formatDateWithOptions(
      Js.Date.fromString(localDate ++ "T12:00:00+09:00"),
      ReactIntl.dateTimeFormatOptions(~month=#short, ~day=#numeric, ~timeZone="Asia/Tokyo", ()),
    )
  let renderHeader = (trigger: React.element) =>
    <div className="px-4 md:px-6 py-3 flex items-center justify-between">
      <div className="flex items-baseline gap-3">
        <h3 className="font-semibold text-gray-900 dark:text-gray-100"> {label->React.string} </h3>
        <span className="font-mono text-xs text-gray-400 dark:text-gray-500">
          {`${dateDetails} · ${eventCount->Int.toString} ${eventCount == 1
              ? "event"
              : "events"}`->React.string}
        </span>
      </div>
      {trigger}
    </div>
  let onCreateEvent = (intent: TimeWindow.playIntent) =>
    onCreateEvent->Option.forEach(cb => cb(localDate, {start: intent.start, end: intent.end}))
  <div
    className="max-w-4xl border-y border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#222326]">
    {switch host {
    | #discover =>
      <PkEventsAvailabilityDay
        data=availability
        localDate
        dateGroup=label
        activityId=PkEventsList.defaultActivityId
        onRefetchNeeded
        isLoggedIn
        onCreateEvent
        renderHeader
      />
    | #club | #locationClub =>
      <PkEventsAvailabilityDay
        data=availability
        localDate
        dateGroup=label
        activityId=PkEventsList.defaultActivityId
        onRefetchNeeded
        isLoggedIn
        onCreateEvent
        renderHeader
        triggerLabel={`Add to ${label}`}
        triggerIcon={<Lucide.Plus size=11 />}
        clubSlug={host == #locationClub ? "picklr" : "tokyo-pickleball"}
        hostOptions=?{host == #locationClub
          ? Some(
              <LevelTagPills
                selected=levelTags
                onChange={tags => setLevelTags(_ => tags)}
                legend={React.string("Skill level")}
              />,
            )
          : None}
      />
    }}
  </div>
}

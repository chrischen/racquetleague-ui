// Storybook support for PkEventsDayFeed.stories.tsx; the app never imports
// this. PkEventsDayFeed is the body of one day on Discover when inline courts
// are on: that day's event rows with the court openings interleaved by start
// time. As in PkEventsList.Day, the event rows are built by the host (here,
// from the events the mocks put on Query.events that fall on `localDate`).
module Query = %relay(`
  query PkEventsDayFeedStoryQuery {
    ...UseProfileGate_query
    ...PkEventsAvailabilityDay_query @arguments(fromDate: "2026-10-14", toDate: "2026-10-28")
    viewer {
      user {
        ...PkEventRow_user
      }
    }
    events(first: 50) {
      edges {
        node {
          id
          startDate
          timezone
          ...PkEventRow_event
        }
      }
    }
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = PkEventsDayFeedStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (
  // The day in Tokyo, "YYYY-MM-DD".
  ~localDate="2026-10-14",
  ~onRefetchNeeded=() => (),
) => {
  let data = Query.use(~variables=())
  let availability = PkEventsAvailabilityDay.Fragment.use(data.fragmentRefs)
  let user = data.viewer->Option.flatMap(v => v.user)->Option.map(u => u.fragmentRefs)
  let events =
    data.events.edges
    ->Option.getOr([])
    ->Array.filterMap(edge => edge->Option.flatMap(e => e.node))
    ->Array.filterMap(node =>
      node.startDate->Option.flatMap(start => {
        let date = start->Util.Datetime.toDate
        let tz = node.timezone->Option.getOr("Asia/Tokyo")
        StoryFixturesDiscovery.tokyoDay(date) == localDate
          ? Some(
              (
                {
                  startHour: TimeWindow.hourInTimeZone(date, tz),
                  key: node.id,
                  render: isLast =>
                    <PkEventRow
                      key=node.id
                      event=node.fragmentRefs
                      user
                      isLastInGroup=isLast
                      query=data.fragmentRefs
                    />,
                }: PkEventsDayFeed.feedEvent
              ),
            )
          : None
      })
    )
  <div
    className="max-w-4xl border-y border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#222326]">
    <PkEventsDayFeed
      data=availability
      localDate
      activityId=PkEventsList.defaultActivityId
      events
      hasHiddenPreview=false
      onRefetchNeeded
    />
  </div>
}

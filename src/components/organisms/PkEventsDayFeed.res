%%raw("import { t } from '@lingui/macro'")

// Experimental: interleaves the day's court openings (as CourtPseudoEventRow)
// with its event rows, ordered by start time. Court data is client-only, so
// this renders only after geolocation resolves; the caller shows plain event
// rows as the Suspense fallback, which keeps events SSR-visible.
//
// Court openings are bucketed into per-segment pseudo-events (each distinct
// active-court span surfaces separately), and each row can set the viewer's
// availability scoped to just that slot — committed via UseSetAvailabilityDay,
// then a refetch keeps the availability display in sync.
//
// Reuses PkEventsAvailabilityDay.Query (identical variables) so the court
// fetch is deduped with the availability row's — no extra network request.

// One event row, pre-built by the caller (which owns event fragments + intl):
// `render` takes whether the row is last in the merged feed.
type feedEvent = {
  startHour: float,
  key: string,
  render: bool => React.element,
}

type feedItem =
  | FeedEvent(feedEvent)
  | FeedCourtGroup(TimeWindow.courtPseudoEventGroup)

@react.component
let make = (
  ~localDate: string,
  ~fromDate: string,
  ~toDate: string,
  ~activityId: string,
  ~location: UseUserLocation.location,
  ~fetchKey: int,
  ~events: array<feedEvent>,
  ~hasHiddenPreview: bool,
  ~onRefetchNeeded: unit => unit,
  // When set, courts are scoped to this single location (must match the sibling
  // PkEventsAvailabilityDay so the deduped query fetches the right source).
  ~locationId: option<string>=?,
) => {
  let fetchPolicy = fetchKey > 0 ? RescriptRelay.StoreAndNetwork : RescriptRelay.StoreOrNetwork
  let data = PkEventsAvailabilityDay.Query.use(
    ~variables={
      activityId,
      fromDate,
      toDate,
      location,
      locationId: locationId->Option.getOr(""),
      byLocation: locationId->Option.isSome,
    },
    ~fetchKey=Int.toString(fetchKey),
    ~fetchPolicy,
  )

  let (commitDay, _isMutating) = UseSetAvailabilityDay.use()

  let genericCourtName = Lingui.UtilString.t`Court`
  // Slots first (so a long opening surfaces at multiple times), then collapse
  // adjacent slots into one contiguous summary group per continuous span.
  let courtGroups =
    PkEventsAvailabilityDay.courtAvailabilityForDate(
      PkEventsAvailabilityDay.courtRowsFromData(data),
      ~localDate,
      ~genericCourtName,
    )
    ->TimeWindow.groupCourtAvailabilityIntoPseudoEventBands
    ->TimeWindow.groupContiguousPseudoEventBands

  let viewerUserId = data.viewer->Option.flatMap(v => v.user)->Option.map(u => u.id)

  // The viewer's own availability intents for this day, so slot edits can
  // replace only the slot window and preserve the rest of the day.
  let availabilityIntents =
    data.viewer
    ->Option.flatMap(v => v.availability->Array.find(d => d.localDate == localDate))
    ->Option.map(d =>
      d.intervals->Array.mapWithIndex((iv, i): TimeWindow.playIntent => {
        id: i,
        start: iv.startHour->Float.fromInt,
        end: iv.endHour->Float.fromInt,
      })
    )
    ->Option.getOr([])

  // Other players available this day (excluding the viewer) for the slot's
  // demand heatmap and "players available in this slot" list.
  let players =
    data.availabilityUsersForDateRange
    ->Array.filter(d => d.localDate == localDate)
    ->Array.filter(d =>
      switch viewerUserId {
      | None => true
      | Some(vid) => d.user->Option.map(u => u.id)->Option.getOr("") != vid
      }
    )
    ->Array.map((d): CourtPseudoEventRow.slotPlayer => {
      let name = d.user->Option.flatMap(u => u.lineUsername)->Option.getOr("?")
      {
        id: d.id,
        name,
        initials: name->String.slice(~start=0, ~end=2)->String.toUpperCase,
        intents: d.intervals->Array.mapWithIndex(
          (iv, i): TimeWindow.playIntent => {
            id: i,
            start: iv.startHour->Float.fromInt,
            end: iv.endHour->Float.fromInt,
          },
        ),
      }
    })

  let onAvailabilityChange = (newIntents: array<TimeWindow.playIntent>) => {
    let _ = commitDay(
      ~localDate,
      ~activityId,
      ~intervals=UseSetAvailabilityDay.intervalsOfIntents(newIntents),
      ~onCompleted=(_res, _err) => onRefetchNeeded(),
    )
  }

  // Merge events + court slots, ordered by start time. On a tie, the event
  // sorts before the court slot (events are the primary content).
  let startOf = item =>
    switch item {
    | FeedEvent(e) => e.startHour
    | FeedCourtGroup(g) => g.start
    }
  let items =
    Belt.Array.concat(
      events->Array.map(e => FeedEvent(e)),
      courtGroups->Array.map(g => FeedCourtGroup(g)),
    )->Array.toSorted((a, b) =>
      if startOf(a) != startOf(b) {
        startOf(a) -. startOf(b)
      } else {
        switch (a, b) {
        | (FeedEvent(_), FeedCourtGroup(_)) => -1.0
        | (FeedCourtGroup(_), FeedEvent(_)) => 1.0
        | _ => 0.0
        }
      }
    )

  let lastIdx = items->Array.length - 1
  <>
    {items
    ->Array.mapWithIndex((item, idx) => {
      let isLastFeedItem = idx == lastIdx && !hasHiddenPreview
      switch item {
      | FeedEvent(e) => e.render(isLastFeedItem)
      | FeedCourtGroup(g) =>
        <CourtPseudoEventGroup
          key={"court-" ++ g.key}
          group=g
          availability=availabilityIntents
          players
          isLastInGroup=isLastFeedItem
          hasBottomBorder=false
          onAvailabilityChange
        />
      }
    })
    ->React.array}
  </>
}

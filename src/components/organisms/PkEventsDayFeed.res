%%raw("import { t } from '@lingui/macro'")

// Experimental: interleaves the day's court openings (as CourtPseudoEventRow)
// with its event rows, ordered by start time. Court data is client-only, so
// this renders only after geolocation resolves; the caller shows plain event
// rows as the Suspense fallback, which keeps events SSR-visible.
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
  | FeedCourt(TimeWindow.courtAvailabilityBand)

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
  ~onUseCourtTime: TimeWindow.playIntent => unit,
) => {
  let fetchPolicy = fetchKey > 0 ? RescriptRelay.StoreAndNetwork : RescriptRelay.StoreOrNetwork
  let data = PkEventsAvailabilityDay.Query.use(
    ~variables={activityId, fromDate, toDate, location},
    ~fetchKey=Int.toString(fetchKey),
    ~fetchPolicy,
  )

  let genericCourtName = Lingui.UtilString.t`Court`
  let courtBands =
    PkEventsAvailabilityDay.courtAvailabilityForDate(
      data.locationsAvailability,
      ~localDate,
      ~genericCourtName,
    )->TimeWindow.groupCourtAvailabilityIntoBands

  // Merge events + court bands, ordered by start time. On a tie, the event
  // sorts before the court band (events are the primary content).
  let startOf = item =>
    switch item {
    | FeedEvent(e) => e.startHour
    | FeedCourt(b) => b.start
    }
  let items =
    Belt.Array.concat(
      events->Array.map(e => FeedEvent(e)),
      courtBands->Array.map(b => FeedCourt(b)),
    )->Array.toSorted((a, b) =>
      if startOf(a) != startOf(b) {
        startOf(a) -. startOf(b)
      } else {
        switch (a, b) {
        | (FeedEvent(_), FeedCourt(_)) => -1.0
        | (FeedCourt(_), FeedEvent(_)) => 1.0
        | _ => 0.0
        }
      }
    )

  let lastIdx = items->Array.length - 1
  <>
    {items
    ->Array.mapWithIndex((item, idx) => {
      let isLast = idx == lastIdx && !hasHiddenPreview
      switch item {
      | FeedEvent(e) => e.render(isLast)
      | FeedCourt(b) =>
        <CourtPseudoEventRow
          key={"court-" ++ b.key} band=b isLastInGroup=isLast onUseTime=onUseCourtTime
        />
      }
    })
    ->React.array}
  </>
}

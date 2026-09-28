// Storybook support for EventStateExportModal.stories.tsx; the app never imports this.
// The event manager's "Export History" dialog: this device's scored matches
// and rating adjustments as one JSON string, read-only, with a Copy button.
// The text is the real encoder's output (EventStateTransfer.encode) for the
// shared Thursday-night fixtures, so it is exactly what the app would show.
open StoryFixturesMatch

// A long session: twelve fully scored rounds, alternating the round-1 and
// round-2 pairings, so the export fills the textarea and scrolls.
let longSession = () => {
  let players = plainPlayers()->Array.concat(StoryFixturesSession.guests())
  let base = StoryFixturesSession.recordedRounds(players)
  let scores = [(11., 7.), (9., 11.), (11., 4.), (11., 9.), (6., 11.), (11., 8.)]
  Belt.Array.range(0, 11)->Array.map(r =>
    base
    ->Array.getUnsafe(mod(r, 2))
    ->Array.mapWithIndex((m, c) => {
      ...m,
      id: `evt-long-r${(r + 1)->Int.toString}-c${(c + 1)->Int.toString}`,
      score: scores->Array.get(mod(r + c, scores->Array.length)),
      createdAt: StoryFixturesSession.roundTime(r),
    })
  )
}

@genType @react.component
let make = (~state: [#typical | #longSession]=#typical, ~onClose=() => ()) => {
  let text = React.useMemo1(() =>
    switch state {
    | #typical => StoryFixturesSession.sampleExport
    | #longSession =>
      EventStateTransfer.encode(
        ~eventId="evt-story-match",
        ~exportedAt=StoryFixturesSession.exportedAt,
        ~rounds=longSession(),
        ~adjustments=StoryFixturesSession.allAdjustments,
      )
    }
  , [state])
  <EventStateExportModal text onClose />
}

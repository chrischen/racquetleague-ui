// Storybook support for EventStateImportModal.stories.tsx; the app never imports this.
// The event manager's "Import History" dialog: paste an export and it previews
// what would be merged (rounds, matches, and what is skipped and why) before
// anything is written. The wrapper builds the preview the way EventManager
// does (EventStateTransfer.decode, then plan against this device's rounds,
// adjustments and roster), for three local situations. Props only: the preview
// never renders a player, so the roster needs no Relay data. Stories paste
// StoryFixturesSession.sampleExport, a second device's rounds 1 and 2.
open StoryFixturesMatch

@genType @react.component
let make = (
  ~local: [#fresh | #partial | #upToDate]=#fresh,
  ~disabled=false,
  ~onImport: option<string => unit>=?,
  ~onClose=() => (),
) => {
  let roster = plainPlayers()
  let withGuests = roster->Array.concat(StoryFixturesSession.guests())
  let recorded = StoryFixturesSession.recordedRounds(withGuests)
  // (this device's roster, rounds, adjustments)
  let (players, existingRounds, existingAdjustments) = switch local {
  // A fresh device: the whole roster including tonight's walk-ins, nothing played yet.
  | #fresh => (withGuests, [], [])
  // This device ran round 1 and the seeding itself, and never added the walk-ins.
  | #partial => (
      roster,
      recorded->Array.slice(~start=0, ~end=1),
      StoryFixturesSession.seedAdjustments,
    )
  // Everything in the export is already here.
  | #upToDate => (withGuests, recorded, StoryFixturesSession.allAdjustments)
  }

  let preview = text =>
    text
    ->EventStateTransfer.decode
    ->Result.map(payload =>
      EventStateTransfer.plan(
        ~existingRounds,
        ~existingAdjustments,
        ~existingRoundViolations=Js.Dict.empty(),
        ~currentRoundInt=existingRounds->Array.length,
        ~players,
        ~payload,
      ).counts
    )

  <EventStateImportModal
    preview onImport={text => onImport->Option.forEach(f => f(text))} disabled onClose
  />
}

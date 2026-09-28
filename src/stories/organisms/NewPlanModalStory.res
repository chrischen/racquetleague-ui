// Storybook support for NewPlanModal.stories.tsx; the app never imports this.
// NewPlanModal is the Magic Patterns "New plan" dialog: pick one of the next
// four days, draw time windows over the players' demand heatmap (fetched by
// TimePickerWithHeatmap from Query.availabilityHourlyCounts), then mark
// yourself available or host an event. Nothing in the app opens it now
// (NewPlanChooserModal took its place), but it still builds.

/** A drawn window, in hours (19.5 is 19:30). */
@genType
type window = {start: float, end: float}

@genType @react.component
let make = (
  ~isOpen=true,
  ~onClose=() => (),
  ~onMarkAvailable: option<(string, array<window>) => unit>=?,
  ~onCreateEvent: option<(string, window) => unit>=?,
) => {
  let toWindow = (i: TimeWindow.playIntent) => {start: i.start, end: i.end}
  <NewPlanModal
    isOpen
    onClose
    onMarkAvailable={(date, intents) =>
      onMarkAvailable->Option.forEach(cb => cb(date, intents->Array.map(toWindow)))}
    onCreateEvent={(date, intent) =>
      onCreateEvent->Option.forEach(cb => cb(date, toWindow(intent)))}
  />
}

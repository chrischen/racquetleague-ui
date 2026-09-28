// Storybook support for AddGuestPlayersModal.stories.tsx; the app never imports this.
// The event manager's walk-in dialog: paste or type names one per line, see a
// numbered preview, and add them all at once. Props only; the stories type
// into the textarea to reach the preview.

@genType @react.component
let make = (~onAdd: option<array<string> => unit>=?, ~onClose=() => ()) =>
  <AddGuestPlayersModal onAdd={names => onAdd->Option.forEach(f => f(names))} onClose />

// Storybook support for SessionAddPlayer.stories.tsx; the app never imports this.
// AiTetsu's "Add Player" pane: a QR code to the event page for players with an
// account, and a name field to add a walk-in by hand. Props only.

@genType @react.component
let make = (~eventId="evt-story-match", ~onPlayerAdd: option<string => unit>=?) =>
  <SessionAddPlayer
    eventId onPlayerAdd={input => onPlayerAdd->Option.forEach(f => f(input.name))}
  />

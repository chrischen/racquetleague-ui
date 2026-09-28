// Storybook support for RoundRobin.stories.tsx; the app never imports this.
// The standalone round-robin tool keeps everything in component state (walk-in
// players only, no event, nothing saved), so each story starts empty and its
// play function adds the players and draws the rounds through the UI.
@genType @react.component
let make = (~debug=false) => <RoundRobin debug />

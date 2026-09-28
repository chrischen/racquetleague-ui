// Storybook support for SessionEvenPlayMode.stories.tsx; the app never imports this.
// AiTetsu's settings pane for "even play": how many players sit out each round,
// so match counts level out. 0 turns it off in favour of match quality. Props only.

@genType @react.component
let make = (~breakCount=4, ~breakPlayersCount=4, ~onChangeBreakCount: option<int => unit>=?) =>
  <SessionEvenPlayMode
    breakCount
    breakPlayersCount
    onChangeBreakCount={count => onChangeBreakCount->Option.forEach(f => f(count))}
  />

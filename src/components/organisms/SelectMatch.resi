module SelectEventPlayersList: {
  type props<
  'players,
  'selected,
  'disabled,
  'onSelectPlayer,
  'minRating,
  'maxRating,
> = {
  players: 'players,
  selected: 'selected,
  disabled?: 'disabled,
  onSelectPlayer?: 'onSelectPlayer,
  minRating?: 'minRating,
  maxRating?: 'maxRating,
}
  let make: props<
  array<Rating.player>,
  array<Rating.Player.t<Rating.rsvpNode>>,
  array<Rating.Player.t<Rating.rsvpNode>>,
  Rating.Player.t<Rating.rsvpNode> => unit,
  float,
  float,
> => Jsx.element
}

@react.component
let make: (
  ~players: array<Rating.player>,
  ~activity: option<AiTetsu_event_graphql.Types.fragment_activity>,
  ~onMatchQueued: Rating.match => unit,
  // ~onMatchCompleted: Rating.CompletedMatch.t<Rating.rsvpNode> => unit,
  ~children: Rating.match => React.element,
) => React.element

@react.component
let make: (
  ~match: Rating.Match.t<Rating.rsvpNode>,
  ~activity: AiTetsu_event_graphql.Types.fragment_activity,
  ~minRating: float,
  ~maxRating: float,
  ~onDelete: unit => unit=?,
  ~onComplete: Rating.Match.t<Rating.rsvpNode> => unit=?,
  ~onSubmitted: unit => unit=?,
) => React.element;

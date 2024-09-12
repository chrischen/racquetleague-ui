@react.component
let make: (
  ~match: Rating.Match.t<Rating.rsvpNode>,
  ~score: (float, float)=?,
  ~minRating: float,
  ~maxRating: float,
  ~onDelete: unit => unit=?,
  ~onComplete: (Rating.CompletedMatch.t<Rating.rsvpNode>) => Js.Promise.t<unit>=?,
  // ~onSubmitted: unit => unit=?,
) => React.element;

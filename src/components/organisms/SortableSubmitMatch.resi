type view = Default | SubmitMatch
module PlayerView: {
  type props<'player, 'minRating, 'maxRating> = {
    player: 'player,
    minRating: 'minRating,
    maxRating: 'maxRating,
  }

  let make: props<Rating.player, float, float> => React.element
}

@react.component
let make: (
  ~defaultView: view=?,
  ~children: array<React.element>,
  ~match: Rating.Match.t<Rating.rsvpNode>,
  // ~score: (float, float)=?,
  ~minRating: float,
  ~maxRating: float,
  ~onDelete: unit => unit=?,
  ~onUpdated: Rating.CompletedMatch.t<Rating.rsvpNode> => unit=?,
) => // ~onSubmitted: unit => unit=?,
React.element

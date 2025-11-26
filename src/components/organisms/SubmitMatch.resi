type view = Default | SubmitMatch
module PlayerView: {
  type props<'player, 'minRating, 'maxRating> = {
    player: 'player,
    minRating: 'minRating,
    maxRating: 'maxRating,
  }

  let make: props<Rating.Player.t<Rating.rsvpNode>, float, float> => React.element
}

@react.component
let make: (
  ~defaultView: view=?,
  ~match: Rating.Match.t<Rating.rsvpNode>,
  ~score: (float, float)=?,
  ~minRating: float,
  ~maxRating: float,
  ~onDelete: unit => unit=?,
  ~onComplete: Rating.CompletedMatch.t<Rating.rsvpNode> => unit=?,
) => // ~onSubmitted: unit => unit=?,
React.element

module SortAction: {
  type sortDir = Asc | Desc
  type props<'sortDir, 'setSortDir> = {
    sortDir: 'sortDir,
    setSortDir: 'setSortDir,
  }
  let make: props<sortDir, (sortDir => sortDir) => unit> => React.element
}
module SelectEventPlayersList: {
  type props<'players, 'selected, 'disabled, 'onSelectPlayer, 'minRating, 'maxRating, 'playerNumberOffset> = {
    players: 'players,
    selected: 'selected,
    disabled?: 'disabled,
    onSelectPlayer?: 'onSelectPlayer,
    minRating?: 'minRating,
    maxRating?: 'maxRating,
    playerNumberOffset?: 'playerNumberOffset
  }
  let make: props<
    array<Rating.player>,
    array<Rating.Player.t<Rating.rsvpNode>>,
    array<Rating.Player.t<Rating.rsvpNode>>,
    Rating.Player.t<Rating.rsvpNode> => unit,
    float,
    float,
    int
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

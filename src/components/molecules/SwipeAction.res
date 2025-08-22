@module("./SwipeAction") @react.component
external make: (
  ~leftActions: React.element=?,
  ~rightActions: React.element=?,
  ~onFullSwipeLeft: unit => unit=?,
  ~onFullSwipeRight: unit => unit=?,
  ~partialThreshold: int=?,
  ~fullThreshold: int=?,
  ~className: string=?,
  ~contentClassName: string=?,
  ~actionsClassName: string=?,
  ~disableFullSwipe: bool=?,
  ~onPartialStateChange: string => unit=?,
  ~onTapped: unit => unit=?,
  ~hoverPartialSide: string=?,
  ~children: React.element,
  unit,
) => React.element = "SwipeAction"

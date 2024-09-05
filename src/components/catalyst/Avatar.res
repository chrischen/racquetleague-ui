@module("./avatar.tsx") @react.component
external make: (
  ~className: string=?,
  ~src: string=?,
  ~slot: string=?,
  ~alt: string=?,
  ~square: bool=?,
  ~initials: string=?,
) => React.element = "Avatar"

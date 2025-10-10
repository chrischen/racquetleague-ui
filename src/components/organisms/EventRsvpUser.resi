@react.component
let make: (
  ~user: RescriptRelay.fragmentRefs<[> #EventRsvpUser_user]>,
  ~highlight: bool=?,
  ~link: string=?,
  ~secondaryText: string=?,
  ~sigmaPercent: float=?,
  ~ratingPercent: float=?,
  ~isAdmin: bool=?,
) => React.element

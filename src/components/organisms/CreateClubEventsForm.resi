@react.component
let make: (
  ~query: RescriptRelay.fragmentRefs<[> #CreateClubEventsForm_query]>,
  ~club: RescriptRelay.fragmentRefs<[> #CreateClubEventsForm_club]>,
  ~prefillDate: string=?,
) => React.element

@react.component
let make: (
  ~events: RescriptRelay.fragmentRefs<[> #CalendarEventsFragment]>,
  ~onDateSelected: Js.Date.t => unit,
) => React.element

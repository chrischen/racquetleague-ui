@react.component
let make: (
  ~location: RescriptRelay.fragmentRefs<[> #CreateLocationEvent_location]>,
  ~query: RescriptRelay.fragmentRefs<[> #CreateLocationEvent_activities]>,
) => React.element

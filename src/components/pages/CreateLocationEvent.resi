@react.component
let make: (
  ~event: RescriptRelay.fragmentRefs<[> #CreateLocationEvent_event]> = ?,
  ~location: RescriptRelay.fragmentRefs<[> #CreateLocationEvent_location]>,
  ~query: RescriptRelay.fragmentRefs<[> #CreateLocationEvent_activities]>,
) => React.element

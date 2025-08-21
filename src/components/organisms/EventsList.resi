module TextEventItem: {
  let td: string => string
  let ts: (array<string>, array<string>) => string
  let make: (~event: RescriptRelay.fragmentRefs<[> #EventsListText_event]>) => string
}
module TextEventsList: {
  let toLocalTime: Js.Date.t => Js.Date.t
  type props<'events> = {events: 'events}
  let make: props<RescriptRelay.fragmentRefs<[> #EventsListFragment]>> => Jsx.element
}


@react.component
let make: (
  ~events: RescriptRelay.fragmentRefs<[> #CalendarEventsFragment | #EventsListFragment]>,
  ~header: React.element,
) => React.element

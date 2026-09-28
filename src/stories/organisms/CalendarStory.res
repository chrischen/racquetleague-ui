// Storybook support for Calendar.stories.tsx; the app never imports this.
// Calendar is the month view (react-calendar) that marks the days with events
// and reports the day clicked. The query spreads its fragment at the root.
module Query = %relay(`
  query CalendarStoryQuery {
    ...CalendarEventsFragment
  }
`)

@genType.import(("relay-runtime", "ConcreteRequest"))
type concreteRequest

/** The operation for the story's `parameters.relay.query`. */
@genType
let query: concreteRequest = CalendarStoryQuery_graphql.node->Obj.magic

@genType @react.component
let make = (~onDateSelected: option<Js.Date.t => unit>=?) => {
  let data = Query.use(~variables=())
  <div className="max-w-sm">
    <Calendar
      events=data.fragmentRefs
      onDateSelected={date => onDateSelected->Option.forEach(cb => cb(date))}
    />
  </div>
}

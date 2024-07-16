%%raw("import { t } from '@lingui/macro'")
%%raw("import './Calendar.css'")

module Fragment = %relay(`
  fragment CalendarEventsFragment on Query
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    afterDate: { type: "Datetime" }
    filters: { type: "EventFilters" }
  )
  @refetchable(queryName: "CalendarEventsRefetchQuery")
  {
    events(after: $after, first: $first, before: $before, filters: $filters, afterDate: $afterDate)
    @connection(key: "CalendarEventsFragment_events") {
      edges {
        node {
          id
          startDate
        }
      }
    }
  }
`)

let isSameDay = (date1, date2) => {
  open Js.Date
  date1->getDate == date2->getDate &&
  date1->getMonth == date2->getMonth &&
  date1->getFullYear == date2->getFullYear
}
let intlIsSameDay = (intl, date1, date2) => {
  // Date string in local time
  let date1String =
    intl->ReactIntl.Intl.formatDateWithOptions(
      date1,
      ReactIntl.dateTimeFormatOptions(~weekday=#long, ~day=#numeric, ~month=#short, ()),
    )
  let date2String =
    intl->ReactIntl.Intl.formatDateWithOptions(
      date2,
      ReactIntl.dateTimeFormatOptions(~weekday=#long, ~day=#numeric, ~month=#short, ()),
    )
  date1String == date2String
}
let inDates = (dates, intl, date) => {
  dates->Array.findIndex(d => intlIsSameDay(intl, d, date)) != -1
}
@react.component
let make = (~events) => {
  let {events: eventsQuery} = Fragment.use(events)
  let {data} = Fragment.usePagination(events)
  let events = data.events->Fragment.getConnectionNodes

  let (searchParams, setSearchParams) = Router.useSearchParamsFunc()
  let locale = React.useContext(LangProvider.LocaleContext.context)
  let intl = ReactIntl.useIntl()

  let dates = events->Array.reduce([], (acc, event) => {
    switch event.startDate {
      | Some(date) => acc->Array.concat([date->Util.Datetime.toDate])
      | None => acc
    };

  })
  // let dates = [Js.Date.fromString("2024-07-21"), Js.Date.fromString("2024-07-18")]
  <ReactCalendar
    className="w-full"
    locale=locale.lang
    value={Js.Date.make()}
    onClickDay={(date, _) => {
      setSearchParams(prevParams => {
        prevParams->Router.SearchParams.set("selectedDate", date->Js.Date.toISOString)
        prevParams;
      })
    }}
    tileContent={({date, view}) => {
      switch view {
      | "month" =>
        switch dates->inDates(intl, date) {
        | true =>
          <>
            <br />
            {"•"->React.string}
          </>
        | false =>
          <>
            <br />
            <br />
          </>
        }
      | _ => React.null
      }
    }}
    tileClassName={({date, view}) => {
      let date =
        intl->ReactIntl.Intl.formatDateWithOptions(
          date,
          ReactIntl.dateTimeFormatOptions(~weekday=#long, ~day=#numeric, ~month=#short, ()),
        )
      let today =
        intl->ReactIntl.Intl.formatDateWithOptions(
          Js.Date.make(),
          ReactIntl.dateTimeFormatOptions(~weekday=#long, ~day=#numeric, ~month=#short, ()),
        )
      switch view {
      | "month" => date == today ? Some("bg-blue-200 text-black") : None
      | _ => None
      }
    }}
  />
}

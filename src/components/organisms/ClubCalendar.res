%%raw("import { t } from '@lingui/macro'")
%%raw("import './Calendar.css'")

// let isSameDay = (date1, date2) => {
//   open Js.Date
//   date1->getDate == date2->getDate &&
//   date1->getMonth == date2->getMonth &&
//   date1->getFullYear == date2->getFullYear
// }
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
let make = (~dates, ~onDateSelected: Js.Date.t => unit) => {

  let locale = React.useContext(LangProvider.LocaleContext.context)
  let intl = ReactIntl.useIntl()

  // let dates = [Js.Date.fromString("2024-07-21"), Js.Date.fromString("2024-07-18")]
  <ReactCalendar
    className="w-full"
    calendarType="gregory"
    locale=locale.lang
    value={Js.Date.make()}
    onClickDay={(date, _) => {
      onDateSelected(date)
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

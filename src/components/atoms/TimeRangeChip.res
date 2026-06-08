@react.component
let make = (~startHour: float, ~endHour: float, ~className: string="") => {
  let intl = ReactIntl.useIntl()
  let formatHour = (h: float): string =>
    intl->ReactIntl.Intl.formatTimeWithOptions(
      Js.Date.makeWithYMDHMS(
        ~year=2000.,
        ~month=0.,
        ~date=1.,
        ~hours=h,
        ~minutes=0.,
        ~seconds=0.,
        (),
      ),
      ReactIntl.dateTimeFormatOptions(~hour=#numeric, ()),
    )
  <span
    className={Util.cx([
      "font-mono text-[11px] px-1.5 py-0.5 rounded bg-[#bdf25d]/40 dark:bg-[#bdf25d]/25 text-[#3f6212] dark:text-[#bdf25d]",
      className,
    ])}>
    {(formatHour(startHour) ++ "–" ++ formatHour(endHour))->React.string}
  </span>
}

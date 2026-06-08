type userDayInterval = {startHour: int, endHour: int}
type userDayUser = {id: string, lineUsername: option<string>, picture: option<string>}
type userDay = {
  id: string,
  localDate: string,
  user: option<userDayUser>,
  intervals: array<userDayInterval>,
}

@react.component
let make = (~userDay: userDay) => {
  let intl = ReactIntl.useIntl()
  let formatHour = (h: int): string =>
    intl->ReactIntl.Intl.formatTimeWithOptions(
      Js.Date.makeWithYMDHMS(
        ~year=2000.,
        ~month=0.,
        ~date=1.,
        ~hours=h->Float.fromInt,
        ~minutes=0.,
        ~seconds=0.,
        (),
      ),
      ReactIntl.dateTimeFormatOptions(~hour=#numeric, ()),
    )

  let name = userDay.user->Option.flatMap(u => u.lineUsername)->Option.getOr("?")
  let userId = userDay.user->Option.map(u => u.id)->Option.getOr(userDay.id)
  let pictureUrl = userDay.user->Option.flatMap(u => u.picture)

  <Router.Link
    to={"/league/pickleball/p/" ++ userId}
    className="flex items-center gap-2.5 bg-white/60 dark:bg-[#1e1f23]/60 rounded-md px-2 py-1.5 border border-violet-100 dark:border-violet-800/30 hover:border-violet-300 dark:hover:border-violet-600 transition-colors">
    <AvatarWithProgressBar ?pictureUrl name skillLevel=0.0 size=#small />
    <span className="flex-1 min-w-0 text-xs font-medium text-gray-900 dark:text-gray-100 truncate">
      {name->React.string}
    </span>
    <div className="flex flex-wrap gap-1 justify-end flex-shrink-0">
      {userDay.intervals
      ->Array.map(iv =>
        <span
          key={`${iv.startHour->Int.toString}-${iv.endHour->Int.toString}`}
          className="inline-flex items-center font-mono text-[9px] px-1.5 py-0.5 rounded bg-violet-100 dark:bg-violet-900/40 text-violet-700 dark:text-violet-300">
          {(formatHour(iv.startHour) ++ "–" ++ formatHour(iv.endHour))->React.string}
        </span>
      )
      ->React.array}
    </div>
  </Router.Link>
}

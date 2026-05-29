let isSameDay = (d1: Js.Date.t, d2: Js.Date.t): bool =>
  Js.Date.getFullYear(d1)->Float.toInt == Js.Date.getFullYear(d2)->Float.toInt &&
  Js.Date.getMonth(d1)->Float.toInt == Js.Date.getMonth(d2)->Float.toInt &&
  Js.Date.getDate(d1)->Float.toInt == Js.Date.getDate(d2)->Float.toInt

let hasEventOnDate = (eventDates: array<Js.Date.t>, date: Js.Date.t): bool =>
  eventDates->Array.some(d => isSameDay(d, date))

// Returns offset (in days from today) to reach Monday of the current ISO week
let getMondayOffsetFromToday = (): int => {
  let dayOfWeek = Js.Date.make()->Js.Date.getDay->Float.toInt
  // 0=Sun, 1=Mon, 2=Tue, ..., 6=Sat
  switch dayOfWeek {
  | 0 => -6 // Sunday: Monday was 6 days ago
  | n => -(n - 1) // Mon=0, Tue=-1, ..., Sat=-5
  }
}

// Returns array of weeks for the given month, each week is 7 cells (None = padding).
// Week starts on Monday (iso8601 layout).
let getMonthGrid = (year: int, month: int): array<array<option<int>>> => {
  // Last day-of-month by asking for day 0 of next month
  let lastDay =
    Js.Date.makeWithYMD(~year=year->Int.toFloat, ~month=(month + 1)->Int.toFloat, ~date=0., ())
    ->Js.Date.getDate
    ->Float.toInt
  // Day of week of the 1st: Sun=0..Sat=6 → Mon=0..Sun=6
  let rawDow =
    Js.Date.makeWithYMD(~year=year->Int.toFloat, ~month=month->Int.toFloat, ~date=1., ())
    ->Js.Date.getDay
    ->Float.toInt
  let firstDow = mod(rawDow + 6, 7)
  let totalCells = firstDow + lastDay
  let paddedTotal = totalCells + mod(7 - mod(totalCells, 7), 7)
  let cells = Belt.Array.makeBy(paddedTotal, i => {
    let dayNum = i - firstDow + 1
    if dayNum >= 1 && dayNum <= lastDay {
      Some(dayNum)
    } else {
      None
    }
  })
  let numWeeks = paddedTotal / 7
  Belt.Array.makeBy(numWeeks, weekIdx =>
    Belt.Array.makeBy(7, dayIdx => Array.getUnsafe(cells, weekIdx * 7 + dayIdx))
  )
}

@react.component
let make = (
  ~selectedDate: option<Js.Date.t>,
  ~onSelectDate: Js.Date.t => unit,
  ~onClearDate: unit => unit,
  ~eventDates: array<Js.Date.t>,
) => {
  let (isExpanded, setIsExpanded) = React.useState(() => false)
  let today = Js.Date.make()
  let setup = EventsListUtils.makeBucketSetup()
  let mondayOffset = getMondayOffsetFromToday()
  let intl = ReactIntl.useIntl()

  let todayYear = today->Js.Date.getFullYear->Float.toInt
  let todayMonth = today->Js.Date.getMonth->Float.toInt
  let (activeYear, setActiveYear) = React.useState(() => todayYear)
  let (activeMonth, setActiveMonth) = React.useState(() => todayMonth)

  // Generate Mon-Sun of current week
  let weekDays = [0, 1, 2, 3, 4, 5, 6]->Array.map(i => {
    let offset = mondayOffset + i
    let date = setup.dateFromOffset(offset->Int.toFloat)
    let dayOfWeek = date->Js.Date.getDay->Float.toInt
    let dayAbbrev = EventsListUtils.getDayName(dayOfWeek)
    let dateNum = date->Js.Date.getDate->Float.toInt
    let isWeekend = dayOfWeek == 0 || dayOfWeek == 6
    let isToday_ = isSameDay(date, today)
    let hasEvents = hasEventOnDate(eventDates, date)
    (date, dayAbbrev, dateNum, isWeekend, isToday_, hasEvents)
  })

  let prevMonth = () => {
    if activeMonth == 0 {
      setActiveYear(y => y - 1)
      setActiveMonth(_ => 11)
    } else {
      setActiveMonth(m => m - 1)
    }
  }

  let nextMonth = () => {
    if activeMonth == 11 {
      setActiveYear(y => y + 1)
      setActiveMonth(_ => 0)
    } else {
      setActiveMonth(m => m + 1)
    }
  }

  let monthDate = Js.Date.makeWithYMD(
    ~year=activeYear->Int.toFloat,
    ~month=activeMonth->Int.toFloat,
    ~date=1.,
    (),
  )
  let monthName =
    intl->ReactIntl.Intl.formatDateWithOptions(
      monthDate,
      ReactIntl.dateTimeFormatOptions(~month=#long, ()),
    )
  let monthLabel = monthName ++ " " ++ activeYear->Int.toString

  let weekHeaders = ["M", "T", "W", "T", "F", "S", "S"]
  let monthGrid = getMonthGrid(activeYear, activeMonth)

  <div className="flex flex-col w-full">
    <div className="flex items-center gap-2">
      <div className="flex flex-1 gap-1">
        {weekDays
        ->Array.map(((date, dayAbbrev, dateNum, isWeekend, isToday_, hasEvents)) => {
          let isSelected = selectedDate->Option.map(d => isSameDay(d, date))->Option.getOr(false)
          <button
            key={date->Js.Date.getTime->Float.toString}
            onClick={_ =>
              if isSelected {
                onClearDate()
              } else {
                onSelectDate(date)
              }}
            className={Util.cx([
              "flex-1 flex flex-col items-center justify-center h-12 rounded-lg transition-colors relative",
              isSelected
                ? "bg-[#bdf25d] text-black"
                : isWeekend
                ? "text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-[#2a2b30] hover:bg-gray-100 dark:hover:bg-[#353640]"
                : "text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-[#2a2b30]",
            ])}>
            <span
              className={Util.cx([
                "text-[10px] font-medium uppercase",
                isSelected ? "text-black/70" : "",
              ])}>
              {dayAbbrev->React.string}
            </span>
            <span
              className={Util.cx([
                "font-mono text-sm",
                isSelected ? "font-bold" : "font-medium",
                isToday_ && !isSelected ? "text-gray-900 dark:text-gray-100 font-bold" : "",
              ])}>
              {dateNum->Int.toString->React.string}
            </span>
            {isToday_ && !isSelected && !hasEvents
              ? <div
                  className="absolute bottom-1 w-1 h-1 rounded-full bg-gray-300 dark:bg-gray-600"
                />
              : React.null}
            {hasEvents && !isSelected
              ? <div className="absolute bottom-1 w-1 h-1 rounded-full bg-[#bdf25d]" />
              : React.null}
          </button>
        })
        ->React.array}
      </div>
      <button
        onClick={_ => setIsExpanded(v => !v)}
        className="p-1.5 rounded-md text-gray-400 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-[#2a2b30] transition-colors flex-shrink-0">
        <Lucide.ChevronDown
          size=16
          className={Util.cx(["transition-transform duration-200", isExpanded ? "rotate-180" : ""])}
        />
      </button>
    </div>
    <FramerMotion.AnimatePresence>
      {isExpanded
        ? <FramerMotion.Div
            key="calendar-expanded"
            className="overflow-hidden"
            initial={{FramerMotion.height: "0px", opacity: 0.}}
            animate={{FramerMotion.height: "auto", opacity: 1.}}
            exit={{FramerMotion.height: "0px", opacity: 0.}}>
            <div className="pt-3 pb-1">
              <div className="flex items-center justify-between mb-2 px-1">
                <button
                  onClick={_ => prevMonth()}
                  className="p-1 rounded-md text-gray-400 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-[#2a2b30] transition-colors">
                  <Lucide.ChevronLeft className="w-3.5 h-3.5" />
                </button>
                <span
                  className="font-mono text-[11px] tracking-wider text-gray-400 dark:text-gray-500 uppercase">
                  {monthLabel->React.string}
                </span>
                <button
                  onClick={_ => nextMonth()}
                  className="p-1 rounded-md text-gray-400 dark:text-gray-500 hover:text-gray-700 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-[#2a2b30] transition-colors">
                  <Lucide.ChevronRight className="w-3.5 h-3.5" />
                </button>
              </div>
              <div className="grid grid-cols-7 mb-1">
                {weekHeaders
                ->Array.mapWithIndex((header, i) =>
                  <div
                    key={i->Int.toString}
                    className="text-center text-[10px] font-medium uppercase py-1 text-gray-400 dark:text-gray-500">
                    {header->React.string}
                  </div>
                )
                ->React.array}
              </div>
              {monthGrid
              ->Array.mapWithIndex((week, weekIdx) =>
                <div key={weekIdx->Int.toString} className="grid grid-cols-7 gap-1 mb-1">
                  {week
                  ->Array.mapWithIndex((dayOpt, dayIdx) =>
                    switch dayOpt {
                    | None => <div key={dayIdx->Int.toString} className="h-10" />
                    | Some(dayNum) =>
                      let cellDate = Js.Date.makeWithYMD(
                        ~year=activeYear->Int.toFloat,
                        ~month=activeMonth->Int.toFloat,
                        ~date=dayNum->Int.toFloat,
                        (),
                      )
                      let isSelected_ =
                        selectedDate->Option.map(d => isSameDay(d, cellDate))->Option.getOr(false)
                      let isToday_ = isSameDay(today, cellDate)
                      let isPast = Js.Date.getTime(cellDate) < Js.Date.getTime(today) && !isToday_
                      let isWeekend_ = dayIdx == 5 || dayIdx == 6
                      let hasEvents_ = hasEventOnDate(eventDates, cellDate)
                      <button
                        key={dayNum->Int.toString}
                        onClick={_ =>
                          if isSelected_ {
                            onClearDate()
                          } else {
                            onSelectDate(cellDate)
                          }}
                        className={Util.cx([
                          "flex flex-col items-center justify-center w-full h-10 rounded-lg transition-colors relative",
                          isSelected_
                            ? "bg-[#bdf25d] text-black"
                            : isWeekend_
                            ? "text-gray-500 dark:text-gray-400 bg-gray-50 dark:bg-[#2a2b30] hover:bg-gray-100 dark:hover:bg-[#353640]"
                            : isPast
                            ? "text-gray-300 dark:text-gray-600 hover:bg-gray-50 dark:hover:bg-[#2a2b30]"
                            : "text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-[#2a2b30]",
                        ])}>
                        <span
                          className={Util.cx([
                            "font-mono text-sm",
                            isSelected_ ? "font-bold" : "font-medium",
                            isToday_ && !isSelected_
                              ? "text-gray-900 dark:text-gray-100 font-bold"
                              : "",
                          ])}>
                          {dayNum->Int.toString->React.string}
                        </span>
                        {isToday_ && !isSelected_ && !hasEvents_
                          ? <div
                              className="absolute bottom-0.5 w-1 h-1 rounded-full bg-gray-400 dark:bg-gray-500"
                            />
                          : React.null}
                        {hasEvents_ && !isSelected_
                          ? <div
                              className="absolute bottom-0.5 w-1 h-1 rounded-full bg-[#bdf25d]"
                            />
                          : React.null}
                      </button>
                    }
                  )
                  ->React.array}
                </div>
              )
              ->React.array}
            </div>
          </FramerMotion.Div>
        : React.null}
    </FramerMotion.AnimatePresence>
  </div>
}

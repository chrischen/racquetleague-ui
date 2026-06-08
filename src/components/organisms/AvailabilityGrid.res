%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// ─── Public types ─────────────────────────────────────────────────────────────

type interval = {startHour: int, endHour: int}

type dayData = {
  dayIdx: int,
  label: string,
  dateLabel: string,
  isoDate: string,
  isWeekend: bool,
  isToday: bool,
  initialIntervals: array<interval>,
}

type playerDemand = TimeWindowPicker.playerDemand

type intervalUpdate = {
  isoDate: string,
  intervals: array<interval>,
}

type existingEvent = TimeWindowPicker.existingEvent

// ─── Internal types ──────────────────────────────────────────────────────────

let snap = 0.5
let minDurationGrid = 0.5
let defaultDurationGrid = 2.0

let windowConfig: TimeWindowPicker.windowConfig = {
  hourMin: TimeWindowPicker.hourMin,
  hourMax: TimeWindowPicker.hourMax,
  snap,
  minDuration: minDurationGrid,
  defaultDuration: defaultDurationGrid,
}

// ─── DayRow ───────────────────────────────────────────────────────────────────

module DayRow = {
  @react.component
  let make = (
    ~dayLabel: string,
    ~dateLabel: string=?,
    ~isWeekend: bool=false,
    ~isToday: bool=false,
    ~existingEvents: array<existingEvent>=[],
    ~demand: array<playerDemand>=[],
    ~windows: array<TimeWindowPicker.playIntent>,
    ~onUpdate: array<TimeWindowPicker.playIntent> => unit,
  ) => {
    let (demandCounts, maxDemand) =
      demand->Array.length > 0
        ? TimeWindowPicker.computeDensity(demand->Array.flatMap(d => d.intents))
        : ([], 0)
    let demandHourCounts: array<
      TimeWindowPicker.hourCount,
    > = demandCounts->Array.mapWithIndex((count, i) => {
      let hc: TimeWindowPicker.hourCount = {
        hour: TimeWindowPicker.hourMin + i,
        count,
      }
      hc
    })
    <div
      className={"flex items-stretch border-b last:border-b-0 border-gray-200 dark:border-[#2a2b30] " ++ (
        isWeekend ? "bg-sky-50/50 dark:bg-sky-950/20" : ""
      )}>
      <div
        className={"w-14 md:w-20 flex-shrink-0 flex flex-col justify-center px-2 py-3 border-r border-gray-200 dark:border-[#2a2b30] " ++ (
          isWeekend ? "bg-sky-100/60 dark:bg-sky-900/30" : "bg-gray-50/60 dark:bg-[#1c1d21]"
        )}>
        <div
          className={"text-xs md:text-sm font-semibold flex items-center gap-1 " ++ (
            isWeekend ? "text-sky-700 dark:text-sky-300" : "text-gray-800 dark:text-gray-100"
          )}>
          {React.string(dayLabel)}
          {isToday
            ? <span className="w-1.5 h-1.5 rounded-full bg-[#bdf25d] flex-shrink-0" />
            : React.null}
        </div>
        {dateLabel
        ->Option.map(dl =>
          <div
            className={"font-mono text-[10px] mt-0.5 " ++ (
              isWeekend
                ? "text-sky-500/80 dark:text-sky-400/80"
                : "text-gray-400 dark:text-gray-500"
            )}>
            {React.string(dl)}
          </div>
        )
        ->Option.getOr(React.null)}
      </div>
      <div className="flex-1">
        <TimeWindowPicker
          intents=windows
          onChange=onUpdate
          config=windowConfig
          showAxis=false
          className="h-full"
          trackClassName="relative z-10 h-full overflow-hidden cursor-copy"
          existingEvents
          demandCounts=demandHourCounts
          maxDemand
        />
      </div>
    </div>
  }
}

// ─── AvailabilityGrid ────────────────────────────────────────────────────────

@react.component
let make = (
  ~days: array<dayData>,
  ~onSave: array<intervalUpdate> => unit,
  ~isSaving: bool=?,
  ~existingEvents: Js.Dict.t<array<existingEvent>>=?,
  ~demand: Js.Dict.t<array<playerDemand>>=?,
) => {
  // Windows indexed parallel to days array
  let (windows, setWindows) = React.useState(() =>
    days->Array.map(day =>
      if day.initialIntervals->Array.length > 0 {
        day.initialIntervals->Array.map(
          (iv): TimeWindowPicker.playIntent => {
            id: TimeWindowPicker.wid(),
            start: Float.fromInt(iv.startHour),
            end: Float.fromInt(iv.endHour),
          },
        )
      } else {
        []
      }
    )
  )

  let (mode, setMode) = React.useState(() => "specific")

  let updateDay = (idx: int, ws: array<TimeWindowPicker.playIntent>) =>
    setWindows(prev =>
      prev->Array.mapWithIndex((w, i) =>
        if i === idx {
          ws
        } else {
          w
        }
      )
    )

  let applyPreset = (preset: string) => {
    setWindows(prev =>
      days->Array.mapWithIndex((d, i) =>
        switch preset {
        | "weekday-evenings" if d.dayIdx < 5 =>
          Belt.Array.concat(
            prev->Array.getUnsafe(i),
            [
              (
                {
                  id: TimeWindowPicker.wid(),
                  start: 18.0,
                  end: 22.0,
                }: TimeWindowPicker.playIntent
              ),
            ],
          )
        | "weekend-mornings" if d.dayIdx >= 5 =>
          Belt.Array.concat(
            prev->Array.getUnsafe(i),
            [
              (
                {
                  id: TimeWindowPicker.wid(),
                  start: 9.0,
                  end: 12.0,
                }: TimeWindowPicker.playIntent
              ),
            ],
          )
        | "clear" => []
        | _ => prev->Array.getUnsafe(i)
        }
      )
    )
  }

  let summary = React.useMemo1(() =>
    days
    ->Array.mapWithIndex((d, i) => {
      let ws =
        windows
        ->Array.getUnsafe(i)
        ->Array.toSorted(
          (a: TimeWindowPicker.playIntent, b: TimeWindowPicker.playIntent) => a.start -. b.start,
        )
      (d.label, ws)
    })
    ->Array.filter(((_, ws)) => ws->Array.length > 0)
  , [windows])

  let totalHours = React.useMemo1(
    () =>
      windows->Array.reduce(0.0, (sum, dayWins) =>
        dayWins->Array.reduce(sum, (s, w) => s +. (w.end -. w.start))
      ),
    [windows],
  )

  let axisHours = Belt.Array.makeBy(TimeWindowPicker.hourRange / 3 + 1, i =>
    TimeWindowPicker.hourMin + i * 3
  )

  let handleSave = _ => {
    let changes = days->Array.mapWithIndex((d, i) => {
      isoDate: d.isoDate,
      intervals: windows
      ->Array.getUnsafe(i)
      ->Array.map(w => {
        startHour: w.start->Js.Math.round->Float.toInt,
        endHour: w.end->Js.Math.round->Float.toInt,
      }),
    })
    onSave(changes)
  }

  <WaitForMessages>
    {_ =>
      <div className="flex-1 overflow-y-auto bg-white dark:bg-[#222326]">
        <div className="max-w-5xl mx-auto px-4 md:px-6 py-6 pb-24 md:pb-10">
          <div className="mb-5">
            <div
              className="font-mono text-[10px] tracking-wider text-gray-400 dark:text-gray-500 uppercase mb-1">
              {t`Schedule`}
            </div>
            <h1 className="text-2xl font-semibold text-gray-900 dark:text-gray-100 leading-tight">
              {t`When can you play?`}
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
              {t`Add time windows to each day. Drag to move them, grab the edges to resize.`}
            </p>
          </div>
          // Mode + presets
          <div className="flex flex-wrap items-center gap-2 mb-4">
            <div
              className="inline-flex items-center rounded-md border border-gray-200 dark:border-[#3a3b40] p-0.5 bg-gray-50 dark:bg-[#1e1f23]">
              <button
                onClick={_ => setMode(_ => "recurring")}
                className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded transition-colors ${mode === "recurring"
                    ? "bg-white dark:bg-[#2a2b30] text-gray-900 dark:text-gray-100 shadow-sm"
                    : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"}`}>
                <Lucide.Repeat size=12 />
                {t`Weekly`}
              </button>
              <button
                onClick={_ => setMode(_ => "specific")}
                className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-medium rounded transition-colors ${mode === "specific"
                    ? "bg-white dark:bg-[#2a2b30] text-gray-900 dark:text-gray-100 shadow-sm"
                    : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"}`}>
                <Lucide.CalendarRange size=12 />
                {t`One-off`}
              </button>
            </div>
            <div className="flex items-center gap-1.5 ml-auto flex-wrap">
              <button
                onClick={_ => applyPreset("weekday-evenings")}
                className="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-mono rounded-md border border-gray-200 dark:border-[#3a3b40] text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors">
                <Lucide.Moon size=11 />
                {t`Weekday eves`}
              </button>
              <button
                onClick={_ => applyPreset("weekend-mornings")}
                className="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-mono rounded-md border border-gray-200 dark:border-[#3a3b40] text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors">
                <Lucide.Sun size=11 />
                {t`Weekend morns`}
              </button>
              <button
                onClick={_ => applyPreset("clear")}
                className="inline-flex items-center gap-1 px-2.5 py-1 text-xs font-mono rounded-md border border-gray-200 dark:border-[#3a3b40] text-gray-500 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-[#2a2b30] hover:text-red-600 dark:hover:text-red-400 transition-colors">
                <Lucide.Trash2 className="w-[11px] h-[11px]" />
                {t`Clear`}
              </button>
            </div>
          </div>
          // Timeline grid
          <div
            className="border border-gray-200 dark:border-[#2a2b30] rounded-lg bg-white dark:bg-[#1e1f23] overflow-hidden">
            <div
              className="flex items-stretch bg-gray-50 dark:bg-[#1c1d21] border-b border-gray-200 dark:border-[#2a2b30]">
              <div
                className="w-14 md:w-20 flex-shrink-0 border-r border-gray-200 dark:border-[#2a2b30]"
              />
              <div className="flex-1 relative h-7">
                {axisHours
                ->Array.mapWithIndex((h, i) => {
                  let leftPct =
                    Float.fromInt(h - TimeWindowPicker.hourMin) /.
                    Float.fromInt(TimeWindowPicker.hourRange) *. 100.0
                  <div
                    key={h->Int.toString}
                    className="absolute top-0 bottom-0 flex items-center"
                    style={ReactDOM.Style.make(
                      ~left=leftPct->Float.toString ++ "%",
                      ~transform=if i === 0 {
                        "translateX(0)"
                      } else if i === axisHours->Array.length - 1 {
                        "translateX(-100%)"
                      } else {
                        "translateX(-50%)"
                      },
                      (),
                    )}>
                    <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500 px-1">
                      {React.string(TimeWindowPicker.hourLabel(Float.fromInt(h)))}
                    </span>
                  </div>
                })
                ->React.array}
              </div>
            </div>
            {days
            ->Array.mapWithIndex((d, i) =>
              <DayRow
                key={d.dayIdx->Int.toString}
                dayLabel={d.label}
                dateLabel=?{mode === "specific" ? Some(d.dateLabel) : None}
                isWeekend={d.isWeekend}
                isToday={d.isToday}
                existingEvents={existingEvents
                ->Option.flatMap(dict => dict->Js.Dict.get(d.isoDate))
                ->Option.getOr([])}
                demand={demand
                ->Option.flatMap(dict => dict->Js.Dict.get(d.isoDate))
                ->Option.getOr([])}
                windows={windows->Array.getUnsafe(i)}
                onUpdate={ws => updateDay(i, ws)}
              />
            )
            ->React.array}
          </div>
          <p className="text-[11px] font-mono text-gray-400 dark:text-gray-500 mt-2 px-1">
            {t`Drag a window to move it · drag the edges to resize · tap + to add another`}
          </p>
          // Summary
          <div
            className="mt-6 border border-gray-200 dark:border-[#2a2b30] rounded-lg p-4 bg-white dark:bg-[#1e1f23]">
            <div className="flex items-center justify-between mb-3">
              <h2
                className="font-mono text-xs tracking-wider text-gray-400 dark:text-gray-500 uppercase">
                {t`Your availability`}
              </h2>
              <span className="font-mono text-[11px] text-gray-500 dark:text-gray-400">
                {React.string(totalHours->Float.toString ++ "h / 2 weeks")}
              </span>
            </div>
            {summary->Array.length === 0
              ? <div
                  className="text-center py-6 text-xs text-gray-400 dark:text-gray-500 font-mono">
                  {t`Add time windows above`}
                </div>
              : <div className="space-y-2">
                  {summary
                  ->Array.map(((label, ws)) =>
                    <div key={label} className="flex items-start gap-3 text-sm">
                      <span
                        className="w-9 flex-shrink-0 font-semibold text-gray-900 dark:text-gray-100">
                        {React.string(label)}
                      </span>
                      <div className="flex flex-wrap gap-1.5">
                        {ws
                        ->Array.map(w =>
                          <TimeRangeChip
                            key={w.id->Int.toString}
                            startHour=w.start
                            endHour={w.end}
                            className="bg-[#bdf25d]/30 dark:bg-[#bdf25d]/20"
                          />
                        )
                        ->React.array}
                      </div>
                    </div>
                  )
                  ->React.array}
                </div>}
          </div>
          // Save CTA
          <div
            className="mt-4 flex items-center justify-between gap-3 p-4 rounded-lg border border-gray-200 dark:border-[#2a2b30] bg-gray-50 dark:bg-[#1e1f23]">
            <div className="flex items-center gap-2.5 min-w-0">
              <div
                className="w-8 h-8 rounded-full bg-[#bdf25d]/30 flex items-center justify-center flex-shrink-0">
                <Lucide.Users className="text-[#65a30d] dark:text-[#bdf25d]" />
              </div>
              <div className="min-w-0">
                <div className="text-sm font-medium text-gray-900 dark:text-gray-100">
                  {t`Share with your club`}
                </div>
                <div className="text-[11px] text-gray-500 dark:text-gray-400">
                  {t`Let hosts schedule events when most of you are free`}
                </div>
              </div>
            </div>
            <button
              onClick=handleSave
              disabled={isSaving->Option.getOr(false)}
              className="inline-flex items-center gap-1.5 px-3.5 py-1.5 text-sm font-semibold bg-[#bdf25d] hover:bg-[#aee050] text-black rounded-md transition-colors shadow-sm flex-shrink-0 disabled:opacity-50 disabled:cursor-not-allowed">
              <Lucide.Check size=14 strokeWidth=2.5 />
              {isSaving->Option.getOr(false) ? t`Saving…` : t`Save`}
            </button>
          </div>
        </div>
      </div>}
  </WaitForMessages>
}

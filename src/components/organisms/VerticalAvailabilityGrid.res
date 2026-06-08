%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// ─── Public types ─────────────────────────────────────────────────────────────

type existingEvent = TimeWindowPicker.existingEvent
type playerDemand = TimeWindowPicker.playerDemand
type dayData = AvailabilityGrid.dayData
type intervalUpdate = AvailabilityGrid.intervalUpdate

// ─── DOM bindings ─────────────────────────────────────────────────────────────

type pointerEv2
@get external pClientY: pointerEv2 => float = "clientY"
@get external pClientX2: pointerEv2 => float = "clientX"
@val external document2: Dom.element = "document"
@send
external addPointerListener2: (Dom.element, string, pointerEv2 => unit) => unit = "addEventListener"
@send
external removePointerListener2: (Dom.element, string, pointerEv2 => unit) => unit =
  "removeEventListener"
type domRect2 = {left: float, top: float, width: float, height: float}
@send external getBoundingClientRect2: Dom.element => domRect2 = "getBoundingClientRect"

// ─── Config ───────────────────────────────────────────────────────────────────

let snap = 1.0
let minDurationGrid = 1.0
let defaultDurationGrid = 2.0

// ─── VerticalWindowChip ───────────────────────────────────────────────────────

type vertDragMode = VMove | VResizeTop | VResizeBottom

type vertDragState = {
  mode: vertDragMode,
  startY: float,
  initial: TimeWindowPicker.playIntent,
  current: TimeWindowPicker.playIntent,
  targetDayIdx: int,
}

module VerticalWindowChip = {
  @react.component
  let make = (
    ~dayArrayIdx: int,
    ~intent: TimeWindowPicker.playIntent,
    ~trackRef: React.ref<Js.Nullable.t<Dom.element>>,
    ~onChange: TimeWindowPicker.playIntent => unit,
    ~onDelete: unit => unit,
    ~onMoveDay: (int, TimeWindowPicker.playIntent) => unit,
    ~getTargetDayArrayIdx: float => int,
    ~getColTranslateX: (int, int) => float,
  ) => {
    let hourMinF = TimeWindowPicker.hourMin->Float.fromInt
    let hourMaxF = TimeWindowPicker.hourMax->Float.fromInt
    let hourRangeF = TimeWindowPicker.hourRange->Float.fromInt

    let (drag, setDrag) = React.useState(() => None)
    let onChangeRef = React.useRef(onChange)
    onChangeRef.current = onChange
    let onMoveDayRef = React.useRef(onMoveDay)
    onMoveDayRef.current = onMoveDay
    let getTargetRef = React.useRef(getTargetDayArrayIdx)
    getTargetRef.current = getTargetDayArrayIdx
    let getTranslateRef = React.useRef(getColTranslateX)
    getTranslateRef.current = getColTranslateX

    React.useEffect1(() => {
      switch drag {
      | None => None
      | Some(d) =>
        let handleMove = (e: pointerEv2) => {
          switch trackRef.current->Js.Nullable.toOption {
          | None => ()
          | Some(el) =>
            let rect = el->getBoundingClientRect2
            if rect.height !== 0.0 {
              let dy = e->pClientY -. d.startY
              let dHours = dy /. rect.height *. hourRangeF
              let next = switch d.mode {
              | VMove =>
                let duration = d.initial.end -. d.initial.start
                let ns = TimeWindowPicker.clamp(
                  TimeWindowPicker.snapTo(d.initial.start +. dHours, snap),
                  hourMinF,
                  hourMaxF -. duration,
                )
                {...d.initial, start: ns, end: ns +. duration}
              | VResizeTop => {
                  ...d.initial,
                  start: TimeWindowPicker.clamp(
                    TimeWindowPicker.snapTo(d.initial.start +. dHours, snap),
                    hourMinF,
                    d.initial.end -. minDurationGrid,
                  ),
                }
              | VResizeBottom => {
                  ...d.initial,
                  end: TimeWindowPicker.clamp(
                    TimeWindowPicker.snapTo(d.initial.end +. dHours, snap),
                    d.initial.start +. minDurationGrid,
                    hourMaxF,
                  ),
                }
              }
              let targetDayArrayIdx = if d.mode == VMove {
                getTargetRef.current(e->pClientX2)
              } else {
                d.targetDayIdx
              }
              setDrag(_ => Some({...d, current: next, targetDayIdx: targetDayArrayIdx}))
            }
          }
        }
        let handleEnd = (_: pointerEv2) => {
          setDrag(prev => {
            switch prev {
            | None => ()
            | Some(d) =>
              if d.targetDayIdx !== dayArrayIdx {
                onMoveDayRef.current(d.targetDayIdx, d.current)
              } else {
                onChangeRef.current(d.current)
              }
            }
            None
          })
        }
        document2->addPointerListener2("pointermove", handleMove)
        document2->addPointerListener2("pointerup", handleEnd)
        document2->addPointerListener2("pointercancel", handleEnd)
        Some(
          () => {
            document2->removePointerListener2("pointermove", handleMove)
            document2->removePointerListener2("pointerup", handleEnd)
            document2->removePointerListener2("pointercancel", handleEnd)
          },
        )
      }
    }, [drag])

    let begin_ = (mode: vertDragMode) => (e: ReactEvent.Pointer.t) => {
      e->ReactEvent.Pointer.preventDefault
      e->ReactEvent.Pointer.stopPropagation
      let y = e->ReactEvent.Pointer.clientY->Float.fromInt
      setDrag(_ => Some({
        mode,
        startY: y,
        initial: intent,
        current: intent,
        targetDayIdx: dayArrayIdx,
      }))
    }

    let displayIntent = drag->Option.map(d => d.current)->Option.getOr(intent)
    let topPct = (displayIntent.start -. hourMinF) /. hourRangeF *. 100.0
    let heightPct = (displayIntent.end -. displayIntent.start) /. hourRangeF *. 100.0

    let translateX = switch drag {
    | Some({mode: VMove, targetDayIdx}) if targetDayIdx !== dayArrayIdx =>
      Some(getTranslateRef.current(dayArrayIdx, targetDayIdx))
    | _ => None
    }

    <div
      className={`absolute left-1 right-1 select-none touch-none group rounded border shadow-sm flex flex-col items-center justify-between ${drag->Option.isSome
          ? "bg-[#aee050] border-[#94c93a] z-30"
          : "bg-[#bdf25d] border-[#a3d949] z-20 hover:bg-[#aee050]"}`}
      style={ReactDOM.Style.make(
        ~top=topPct->Float.toString ++ "%",
        ~height=heightPct->Float.toString ++ "%",
        ~transform=translateX
        ->Option.map(tx => `translateX(${tx->Float.toString}px)`)
        ->Option.getOr(""),
        ~cursor=switch drag {
        | Some({mode: VMove}) => "grabbing"
        | _ => "grab"
        },
        (),
      )}
      onPointerDown={begin_(VMove)}
      onClick={e => e->ReactEvent.Mouse.stopPropagation}>
      <div
        onPointerDown={begin_(VResizeTop)}
        onClick={e => e->ReactEvent.Mouse.stopPropagation}
        className="absolute top-0 left-0 right-0 h-2.5 cursor-ns-resize flex items-center justify-center touch-none">
        <div className="w-4 h-0.5 bg-black/40 rounded-full" />
      </div>
      <div
        className="flex-1 flex flex-col items-center justify-center min-h-0 pointer-events-none overflow-hidden py-2">
        <span className="text-[10px] font-mono font-semibold text-black/80 leading-tight">
          {React.string(TimeWindowPicker.hourLabel(displayIntent.start))}
        </span>
        <span className="text-[10px] font-mono font-semibold text-black/80 leading-tight">
          {React.string(TimeWindowPicker.hourLabel(displayIntent.end))}
        </span>
      </div>
      <div
        onPointerDown={begin_(VResizeBottom)}
        onClick={e => e->ReactEvent.Mouse.stopPropagation}
        className="absolute bottom-0 left-0 right-0 h-2.5 cursor-ns-resize flex items-center justify-center touch-none">
        <div className="w-4 h-0.5 bg-black/40 rounded-full" />
      </div>
      <button
        onClick={e => {
          e->ReactEvent.Mouse.stopPropagation
          onDelete()
        }}
        className="absolute -top-2 -right-2 w-5 h-5 bg-white dark:bg-[#2a2b30] border border-gray-200 dark:border-[#3a3b40] rounded-full flex items-center justify-center text-gray-500 hover:text-red-500 shadow-sm opacity-0 group-hover:opacity-100 transition-opacity z-40">
        <Lucide.Trash2 className="w-2.5 h-2.5" />
      </button>
    </div>
  }
}

// ─── VerticalDayColumn ────────────────────────────────────────────────────────

module VerticalDayColumn = {
  @react.component
  let make = (
    ~dayArrayIdx: int,
    ~dayLabel: string,
    ~dateLabel: string=?,
    ~isWeekend: bool=false,
    ~isToday: bool=false,
    ~windows: array<TimeWindowPicker.playIntent>,
    ~existingEvents: array<existingEvent>=[],
    ~demand: array<playerDemand>=[],
    ~onUpdate: array<TimeWindowPicker.playIntent> => unit,
    ~onMoveDay: (int, int, TimeWindowPicker.playIntent) => unit,
    ~getTargetDayArrayIdx: float => int,
    ~getColTranslateX: (int, int) => float,
    ~colRef: React.ref<Js.Nullable.t<Dom.element>>,
  ) => {
    let hourMinF = TimeWindowPicker.hourMin->Float.fromInt
    let hourRangeF = TimeWindowPicker.hourRange->Float.fromInt
    let trackRef = colRef

    let updateWindow = (id, next) =>
      onUpdate(
        windows->Array.map(w =>
          if w.id === id {
            next
          } else {
            w
          }
        ),
      )

    let deleteWindow = id => onUpdate(windows->Array.filter(w => w.id !== id))

    let handleTrackClick = (e: ReactEvent.Mouse.t) => {
      switch trackRef.current->Js.Nullable.toOption {
      | None => ()
      | Some(el) =>
        let rect = el->getBoundingClientRect2
        if rect.height !== 0.0 {
          let ratio = (e->ReactEvent.Mouse.clientY->Float.fromInt -. rect.top) /. rect.height
          let tapHour = hourMinF +. ratio *. hourRangeF
          let start = TimeWindowPicker.clamp(
            TimeWindowPicker.snapTo(tapHour -. defaultDurationGrid /. 2.0, snap),
            hourMinF,
            hourMinF +. hourRangeF -. defaultDurationGrid,
          )
          let end_ = start +. defaultDurationGrid
          let overlaps = windows->Array.some(w => start < w.end && end_ > w.start)
          if !overlaps {
            onUpdate(Belt.Array.concat(windows, [{id: TimeWindowPicker.wid(), start, end: end_}]))
          }
        }
      }
    }

    let demandIntents = demand->Array.flatMap(d => d.intents)
    let (densityCounts, densityMax) =
      demand->Array.length > 0 ? TimeWindowPicker.computeDensity(demandIntents) : ([], 0)

    <div
      className={`flex-1 min-w-[60px] md:min-w-[80px] flex flex-col border-r last:border-r-0 border-gray-200 dark:border-[#2a2b30] ${isWeekend
          ? "bg-sky-50/50 dark:bg-sky-950/20"
          : ""}`}>
      <div
        className={`h-14 flex-shrink-0 flex flex-col items-center justify-center border-b border-gray-200 dark:border-[#2a2b30] ${isWeekend
            ? "bg-sky-100/60 dark:bg-sky-900/30"
            : "bg-gray-50/60 dark:bg-[#1c1d21]"}`}>
        <div
          className={`text-xs font-semibold flex items-center gap-1 ${isWeekend
              ? "text-sky-700 dark:text-sky-300"
              : "text-gray-800 dark:text-gray-100"}`}>
          {React.string(dayLabel)}
          {isToday
            ? <span className="w-1.5 h-1.5 rounded-full bg-[#bdf25d] flex-shrink-0" />
            : React.null}
        </div>
        {dateLabel
        ->Option.map(dl =>
          <div
            className={`font-mono text-[10px] mt-0.5 ${isWeekend
                ? "text-sky-500/80 dark:text-sky-400/80"
                : "text-gray-400 dark:text-gray-500"}`}>
            {React.string(dl)}
          </div>
        )
        ->Option.getOr(React.null)}
      </div>
      <div
        className="relative h-[600px] cursor-copy"
        ref={ReactDOM.Ref.domRef(trackRef)}
        onClick=handleTrackClick>
        {densityMax > 0
          ? <div className="absolute inset-0 flex flex-col pointer-events-none">
              {densityCounts
              ->Array.mapWithIndex((count, i) => {
                let intensity = if densityMax > 0 {
                  count->Float.fromInt /. densityMax->Float.fromInt
                } else {
                  0.0
                }
                let opacity = if count === 0 {
                  "0"
                } else {
                  (0.08 +. intensity *. 0.22)->Float.toFixed(~digits=2)
                }
                <div
                  key={i->Int.toString}
                  className="flex-1 w-full"
                  style={ReactDOM.Style.make(
                    ~backgroundColor=if count === 0 {
                      "transparent"
                    } else {
                      "rgba(139, 92, 246, " ++ opacity ++ ")"
                    },
                    (),
                  )}
                />
              })
              ->React.array}
            </div>
          : React.null}
        <div className="absolute inset-0 pointer-events-none flex flex-col">
          {Belt.Array.makeBy(TimeWindowPicker.hourRange, i => {
            let hour = TimeWindowPicker.hourMin + i
            let isMajor = mod(hour, 3) === 0
            <div
              key={i->Int.toString}
              className={`flex-1 border-t ${isMajor
                  ? "border-gray-200 dark:border-[#2a2b30]"
                  : "border-gray-100/60 dark:border-[#262729]"}`}
            />
          })->React.array}
        </div>
        {existingEvents
        ->Array.map(ev => {
          let topPct = (ev.startHour -. hourMinF) /. hourRangeF *. 100.0
          let heightPct = (ev.endHour -. ev.startHour) /. hourRangeF *. 100.0
          if topPct >= 100.0 || heightPct <= 0.0 {
            React.null
          } else {
            <div
              key={ev.id}
              className="absolute left-1 right-1 z-10 pointer-events-none rounded-sm border border-amber-300/70 dark:border-amber-500/40 flex flex-col items-center justify-center overflow-hidden"
              style={ReactDOM.Style.make(
                ~top=topPct->Float.toString ++ "%",
                ~height=heightPct->Float.toString ++ "%",
                ~backgroundImage="repeating-linear-gradient(45deg, rgba(255,176,66,0.18), rgba(255,176,66,0.18) 4px, rgba(255,176,66,0.05) 4px, rgba(255,176,66,0.05) 8px)",
                (),
              )}
              title={ev.title ++
              " \xb7 " ++
              TimeWindowPicker.hourLabel(ev.startHour) ++
              "\xe2\x80\x93" ++
              TimeWindowPicker.hourLabel(ev.endHour)}>
              <span
                className="text-[9px] font-mono font-medium text-amber-800 dark:text-amber-300/90 whitespace-nowrap leading-tight"
                style={ReactDOM.Style.make(~transform="rotate(90deg)", ())}>
                {React.string(ev.title)}
              </span>
            </div>
          }
        })
        ->React.array}
        {windows
        ->Array.map(w =>
          <VerticalWindowChip
            key={w.id->Int.toString}
            dayArrayIdx
            intent=w
            trackRef
            onChange={nw => updateWindow(w.id, nw)}
            onDelete={() => deleteWindow(w.id)}
            onMoveDay={(targetDayArrayIdx, nw) => onMoveDay(w.id, targetDayArrayIdx, nw)}
            getTargetDayArrayIdx
            getColTranslateX
          />
        )
        ->React.array}
      </div>
    </div>
  }
}

// ─── VerticalAvailabilityGrid ─────────────────────────────────────────────────

@react.component
let make = (
  ~days: array<dayData>,
  ~onSave: array<intervalUpdate> => unit,
  ~isSaving: bool=?,
  ~existingEvents: Js.Dict.t<array<existingEvent>>=?,
  ~demand: Js.Dict.t<array<playerDemand>>=?,
) => {
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

  // Refs to each column track for computing cross-day drag translateX
  let colTrackRefs: array<React.ref<Js.Nullable.t<Dom.element>>> = React.useMemo0(() =>
    Belt.Array.makeBy(days->Array.length, _ => React.createRef())
  )

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

  let handleMoveDay = (
    sourceDayArrayIdx: int,
    windowId: int,
    targetDayArrayIdx: int,
    next: TimeWindowPicker.playIntent,
  ) => {
    setWindows(prev =>
      prev->Array.mapWithIndex((ws, i) =>
        if i === sourceDayArrayIdx {
          ws->Array.filter(w => w.id !== windowId)
        } else if i === targetDayArrayIdx {
          Belt.Array.concat(ws, [next])
        } else {
          ws
        }
      )
    )
  }

  // Given pointer X, return the closest column array index
  let getTargetDayArrayIdx = (pointerX: float): int => {
    let best = ref(0)
    let bestDist = ref(1.0e18)
    colTrackRefs->Array.forEachWithIndex((colRef, i) => {
      switch colRef.current->Js.Nullable.toOption {
      | None => ()
      | Some(el) =>
        let rect = el->getBoundingClientRect2
        let center = rect.left +. rect.width /. 2.0
        let dist = Js.Math.abs_float(pointerX -. center)
        if dist < bestDist.contents {
          bestDist := dist
          best := i
        }
      }
    })
    best.contents
  }

  // Given source and target column indices, return the X offset so the chip
  // visually moves to the target column during cross-day drag.
  let getColTranslateX = (sourceIdx: int, targetIdx: int): float => {
    let getLeft = (idx: int): option<float> =>
      switch (colTrackRefs->Array.getUnsafe(idx)).current->Js.Nullable.toOption {
      | None => None
      | Some(el) => Some((el->getBoundingClientRect2).left)
      }
    switch (getLeft(sourceIdx), getLeft(targetIdx)) {
    | (Some(sl), Some(tl)) => tl -. sl
    | _ => 0.0
    }
  }

  let applyPreset = (preset: string) => {
    setWindows(prev =>
      days->Array.mapWithIndex((d, i) =>
        switch preset {
        | "weekday-evenings" if !d.isWeekend =>
          Belt.Array.concat(
            prev->Array.getUnsafe(i),
            [{id: TimeWindowPicker.wid(), start: 18.0, end: 22.0}],
          )
        | "weekend-mornings" if d.isWeekend =>
          Belt.Array.concat(
            prev->Array.getUnsafe(i),
            [{id: TimeWindowPicker.wid(), start: 9.0, end: 12.0}],
          )
        | "clear" => []
        | _ => prev->Array.getUnsafe(i)
        }
      )
    )
  }

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
      let r: intervalUpdate = {
        isoDate: d.isoDate,
        intervals: windows
        ->Array.getUnsafe(i)
        ->Array.map(w => {
          let iv: AvailabilityGrid.interval = {
            startHour: w.start->Js.Math.round->Float.toInt,
            endHour: w.end->Js.Math.round->Float.toInt,
          }
          iv
        }),
      }
      r
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
              {t`Set your availability for the next 2 weeks. Tap a day to add a time window, drag to move, grab the edges to resize.`}
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2 mb-4">
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
          <div
            className="border border-gray-200 dark:border-[#2a2b30] rounded-lg bg-white dark:bg-[#1e1f23] overflow-x-auto overflow-y-hidden">
            <div className="min-w-[700px] flex items-stretch">
              <div
                className="w-12 md:w-14 flex-shrink-0 border-r border-gray-200 dark:border-[#2a2b30] bg-gray-50 dark:bg-[#1c1d21] sticky left-0 z-30 flex flex-col">
                <div className="h-14 border-b border-gray-200 dark:border-[#2a2b30]" />
                <div className="relative h-[600px]">
                  {axisHours
                  ->Array.mapWithIndex((h, i) => {
                    let topPct =
                      Float.fromInt(h - TimeWindowPicker.hourMin) /.
                      Float.fromInt(TimeWindowPicker.hourRange) *. 100.0
                    <div
                      key={h->Int.toString}
                      className="absolute left-0 right-2 flex items-center justify-end"
                      style={ReactDOM.Style.make(
                        ~top=topPct->Float.toString ++ "%",
                        ~transform=if i === 0 {
                          "translateY(0)"
                        } else if i === axisHours->Array.length - 1 {
                          "translateY(-100%)"
                        } else {
                          "translateY(-50%)"
                        },
                        (),
                      )}>
                      <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
                        {React.string(TimeWindowPicker.hourLabel(Float.fromInt(h)))}
                      </span>
                    </div>
                  })
                  ->React.array}
                </div>
              </div>
              <div className="flex-1 flex items-stretch">
                {days
                ->Array.mapWithIndex((d, i) =>
                  <VerticalDayColumn
                    key={d.dayIdx->Int.toString}
                    dayArrayIdx=i
                    dayLabel={d.label}
                    dateLabel={d.dateLabel}
                    isWeekend={d.isWeekend}
                    isToday={d.isToday}
                    windows={windows->Array.getUnsafe(i)}
                    existingEvents={existingEvents
                    ->Option.flatMap(dict => dict->Js.Dict.get(d.isoDate))
                    ->Option.getOr([])}
                    demand={demand
                    ->Option.flatMap(dict => dict->Js.Dict.get(d.isoDate))
                    ->Option.getOr([])}
                    onUpdate={ws => updateDay(i, ws)}
                    onMoveDay={(windowId, targetDayArrayIdx, nw) =>
                      handleMoveDay(i, windowId, targetDayArrayIdx, nw)}
                    getTargetDayArrayIdx
                    getColTranslateX
                    colRef={colTrackRefs->Array.getUnsafe(i)}
                  />
                )
                ->React.array}
              </div>
            </div>
          </div>
          <p className="text-[11px] font-mono text-gray-400 dark:text-gray-500 mt-2 px-1">
            {t`Tap an empty area of a day to add a window \xb7 drag to move \xb7 grab the edges to resize`}
          </p>
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
            {windows->Array.every(ws => ws->Array.length === 0)
              ? <div
                  className="text-center py-6 text-xs text-gray-400 dark:text-gray-500 font-mono">
                  {t`Add time windows above`}
                </div>
              : <div className="space-y-2">
                  {days
                  ->Array.mapWithIndex((d, i) => {
                    let ws =
                      windows
                      ->Array.getUnsafe(i)
                      ->Array.toSorted((
                        a: TimeWindowPicker.playIntent,
                        b: TimeWindowPicker.playIntent,
                      ) => a.start -. b.start)
                    if ws->Array.length === 0 {
                      React.null
                    } else {
                      <div key={d.dayIdx->Int.toString} className="flex items-start gap-3 text-sm">
                        <span
                          className="w-9 flex-shrink-0 font-semibold text-gray-900 dark:text-gray-100">
                          {React.string(d.label)}
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
                    }
                  })
                  ->React.array}
                </div>}
          </div>
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
              {isSaving->Option.getOr(false) ? t`Saving\xe2\x80\xa6` : t`Save`}
            </button>
          </div>
        </div>
      </div>}
  </WaitForMessages>
}

%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// ─── DOM bindings ────────────────────────────────────────────────────────────

type pointerEv
@get external pClientX: pointerEv => float = "clientX"
@val external document_: Dom.element = "document"
@send
external addPointerListener: (Dom.element, string, pointerEv => unit) => unit = "addEventListener"
@send
external removePointerListener: (Dom.element, string, pointerEv => unit) => unit =
  "removeEventListener"
type domRect = {left: float, width: float}
@send external getBoundingClientRect: Dom.element => domRect = "getBoundingClientRect"
@get external mouseClientX: ReactEvent.Mouse.t => int = "clientX"
@get external pointerClientX: ReactEvent.Pointer.t => int = "clientX"

// ─── Public types ─────────────────────────────────────────────────────────────

type playIntent = {
  id: int,
  start: float,
  end: float,
}

type windowConfig = {
  hourMin?: int,
  hourMax?: int,
  snap?: float,
  minDuration?: float,
  defaultDuration?: float,
}

type hourCount = {
  hour: int,
  count: int,
}

// ─── Constants ───────────────────────────────────────────────────────────────

let hourMin = 6
let hourMax = 24
let hourRange = hourMax - hourMin
let minDuration = 1.0
let defaultDuration = 3.0

type existingEvent = {
  id: string,
  title: string,
  startHour: float,
  endHour: float,
}

type playerDemand = {
  id: int,
  intents: array<playIntent>,
}

// Counts how many of the supplied intents cover each hour bucket in
// [hourMin, hourMax). Returns per-hour counts (length = hourRange) + max.
let computeDensity = (intents: array<playIntent>): (array<int>, int) => {
  let counts = Belt.Array.makeBy(hourRange, i => {
    let h = hourMin + i
    intents->Array.reduce(0, (acc, w) =>
      if Float.fromInt(h) >= w.start && Float.fromInt(h) < w.end {
        acc + 1
      } else {
        acc
      }
    )
  })
  let max = counts->Array.reduce(0, (acc, c) => if c > acc { c } else { acc })
  (counts, max)
}

let nextId = ref(1)
let wid = () => {
  let id = nextId.contents
  nextId := id + 1
  id
}

// ─── Utilities ───────────────────────────────────────────────────────────────

let hourLabel = (h: float): string => {
  let hh = Js.Math.floor_int(h)
  let mm = Js.Math.round((h -. Float.fromInt(hh)) *. 60.0)->Float.toInt
  hh->Int.toString->String.padStart(2, "0") ++ ":" ++ mm->Int.toString->String.padStart(2, "0")
}

let snapTo = (h: float, step: float): float => Js.Math.round(h /. step) *. step

let clamp = (v: float, mn: float, mx: float): float =>
  Js.Math.max_float(mn, Js.Math.min_float(mx, v))

// ─── WindowChip ──────────────────────────────────────────────────────────────

type dragMode = Move | ResizeLeft | ResizeRight

type dragState = {
  mode: dragMode,
  startX: float,
  initial: playIntent,
}

module WindowChip = {
  @react.component
  let make = (
    ~intent: playIntent,
    ~trackRef: React.ref<Js.Nullable.t<Dom.element>>,
    ~onChange: playIntent => unit,
    ~onDelete: unit => unit,
    ~config: windowConfig=?,
  ) => {
    let hourMinVal = config->Option.flatMap(c => c.hourMin)->Option.getOr(hourMin)->Float.fromInt
    let hourMaxVal = config->Option.flatMap(c => c.hourMax)->Option.getOr(hourMax)->Float.fromInt
    let snapStep = config->Option.flatMap(c => c.snap)->Option.getOr(1.0)
    let minDur = config->Option.flatMap(c => c.minDuration)->Option.getOr(minDuration)
    let hourRangeVal = hourMaxVal -. hourMinVal

    let (drag, setDrag) = React.useState(() => None)
    let onChangeRef = React.useRef(onChange)
    onChangeRef.current = onChange

    React.useEffect1(() => {
      switch drag {
      | None => None
      | Some(d) =>
        let handleMove = (e: pointerEv) => {
          switch trackRef.current->Js.Nullable.toOption {
          | None => ()
          | Some(el) =>
            let rect = el->getBoundingClientRect
            if rect.width !== 0.0 {
              let dx = e->pClientX -. d.startX
              let dHours = dx /. rect.width *. hourRangeVal
              let next = switch d.mode {
              | Move =>
                let duration = d.initial.end -. d.initial.start
                let ns = clamp(
                  snapTo(d.initial.start +. dHours, snapStep),
                  hourMinVal,
                  hourMaxVal -. duration,
                )
                {...d.initial, start: ns, end: ns +. duration}
              | ResizeLeft => {
                  ...d.initial,
                  start: clamp(
                    snapTo(d.initial.start +. dHours, snapStep),
                    hourMinVal,
                    d.initial.end -. minDur,
                  ),
                }
              | ResizeRight => {
                  ...d.initial,
                  end: clamp(
                    snapTo(d.initial.end +. dHours, snapStep),
                    d.initial.start +. minDur,
                    hourMaxVal,
                  ),
                }
              }
              onChangeRef.current(next)
            }
          }
        }
        let handleEnd = (_: pointerEv) => setDrag(_ => None)
        document_->addPointerListener("pointermove", handleMove)
        document_->addPointerListener("pointerup", handleEnd)
        document_->addPointerListener("pointercancel", handleEnd)
        Some(
          () => {
            document_->removePointerListener("pointermove", handleMove)
            document_->removePointerListener("pointerup", handleEnd)
            document_->removePointerListener("pointercancel", handleEnd)
          },
        )
      }
    }, [drag])

    let begin_ = (mode: dragMode) => (e: ReactEvent.Pointer.t) => {
      e->ReactEvent.Pointer.preventDefault
      e->ReactEvent.Pointer.stopPropagation
      let x = e->pointerClientX->Float.fromInt
      setDrag(_ => Some({mode, startX: x, initial: intent}))
    }

    let leftPct = (intent.start -. hourMinVal) /. hourRangeVal *. 100.0
    let widthPct = (intent.end -. intent.start) /. hourRangeVal *. 100.0
    let duration = intent.end -. intent.start

    <div
      className={`absolute top-1 bottom-1 select-none touch-none group rounded border shadow-sm flex items-center justify-between gap-1 ${drag->Option.isSome
          ? "bg-[#aee050] border-[#94c93a] z-30"
          : "bg-[#bdf25d] border-[#a3d949] z-20 hover:bg-[#aee050]"}`}
      style={ReactDOM.Style.make(
        ~left=leftPct->Float.toString ++ "%",
        ~width=widthPct->Float.toString ++ "%",
        ~cursor=switch drag {
        | Some({mode: Move}) => "grabbing"
        | _ => "grab"
        },
        (),
      )}
      onPointerDown={begin_(Move)}
      onClick={e => e->ReactEvent.Mouse.stopPropagation}>
      <div
        onPointerDown={begin_(ResizeLeft)}
        onClick={e => e->ReactEvent.Mouse.stopPropagation}
        className="absolute left-0 top-0 bottom-0 w-2.5 cursor-ew-resize flex items-center justify-center touch-none">
        <div className="w-0.5 h-4 bg-black/40 rounded-full" />
      </div>
      <span
        className="flex-1 min-w-0 px-2 text-center text-[11px] font-mono font-semibold text-black/80 truncate pointer-events-none">
        {widthPct > 18.0
          ? React.string(hourLabel(intent.start) ++ "–" ++ hourLabel(intent.end))
          : React.string(
              (duration->Js.Math.floor_int->Int.toString) ++ "h",
            )}
      </span>
      <div
        onPointerDown={begin_(ResizeRight)}
        onClick={e => e->ReactEvent.Mouse.stopPropagation}
        className="absolute right-0 top-0 bottom-0 w-2.5 cursor-ew-resize flex items-center justify-center touch-none">
        <div className="w-0.5 h-4 bg-black/40 rounded-full" />
      </div>
      <button
        onPointerDown={e => e->ReactEvent.Pointer.stopPropagation}
        onClick={e => {
          e->ReactEvent.Mouse.stopPropagation
          onDelete()
        }}
        className="absolute -top-1.5 -right-1.5 w-4 h-4 rounded-full bg-white dark:bg-[#1e1f23] border border-gray-300 dark:border-[#3a3b40] flex items-center justify-center opacity-0 group-hover:opacity-100 focus:opacity-100 transition-opacity shadow-sm"
        title="Remove">
        <Lucide.X size=10 className="text-gray-600 dark:text-gray-300" />
      </button>
    </div>
  }
}

// ─── InlineMultiPicker ───────────────────────────────────────────────────────

@react.component
let make = (
  ~intents: array<playIntent>,
  ~onChange: array<playIntent> => unit,
  ~config: windowConfig=?,
  ~showAxis: bool=true,
  ~className: string=?,
  ~trackClassName: string=?,
  ~demandCounts: array<hourCount>=?,
  ~maxDemand: int=0,
  ~existingEvents: array<existingEvent>=[],
) => {
  let trackRef = React.useRef(Js.Nullable.null)

  let hourMinVal = config->Option.flatMap(c => c.hourMin)->Option.getOr(hourMin)
  let hourMaxVal = config->Option.flatMap(c => c.hourMax)->Option.getOr(hourMax)
  let hourRangeVal = hourMaxVal - hourMinVal
  let snapStep = config->Option.flatMap(c => c.snap)->Option.getOr(1.0)
  let minDur = config->Option.flatMap(c => c.minDuration)->Option.getOr(minDuration)
  let defaultDur = config->Option.flatMap(c => c.defaultDuration)->Option.getOr(defaultDuration)

  let updateOne = (id: int, next: playIntent) =>
    onChange(
      intents->Array.map(i =>
        if i.id === id {
          next
        } else {
          i
        }
      ),
    )

  let removeOne = (id: int) => onChange(intents->Array.filter(i => i.id !== id))

  let addAtClick = (e: ReactEvent.Mouse.t) => {
    switch trackRef.current->Js.Nullable.toOption {
    | None => ()
    | Some(el) =>
      let rect = el->getBoundingClientRect
      if rect.width !== 0.0 {
        let x = e->mouseClientX->Float.fromInt -. rect.left
        let rawHour = Float.fromInt(hourMinVal) +. x /. rect.width *. Float.fromInt(hourRangeVal)
        let start = clamp(
          Js.Math.floor_float(rawHour),
          Float.fromInt(hourMinVal),
          Float.fromInt(hourMaxVal) -. minDur,
        )
        let inside = intents->Array.some(w => start >= w.start && start < w.end)
        if !inside {
          let nextStart = intents->Array.reduce(Float.fromInt(hourMaxVal), (acc, w) =>
            if w.start >= start && w.start < acc {
              w.start
            } else {
              acc
            }
          )
          let duration = Js.Math.min_float(defaultDur, nextStart -. start)
          if duration >= minDur {
            onChange(Belt.Array.concat(intents, [{id: wid(), start, end: start +. duration}]))
          }
        }
      }
    }
  }

  let axisHours = Belt.Array.makeBy(hourRangeVal / 3 + 1, i => hourMinVal + i * 3)

  <div className={className->Option.getOr("")}>
    {showAxis
      ? <div className="relative h-4 mb-0.5">
          {axisHours
          ->Array.mapWithIndex((h, i) => {
            let lp = Float.fromInt(h - hourMinVal) /. Float.fromInt(hourRangeVal) *. 100.0
            <div
              key={h->Int.toString}
              className="absolute top-0 bottom-0 flex items-center"
              style={ReactDOM.Style.make(
                ~left=lp->Float.toString ++ "%",
                ~transform=if i === 0 {
                  "translateX(0)"
                } else if i === axisHours->Array.length - 1 {
                  "translateX(-100%)"
                } else {
                  "translateX(-50%)"
                },
                (),
              )}>
              <span className="font-mono text-[9px] text-gray-400 dark:text-gray-500">
                {React.string(hourLabel(Float.fromInt(h)))}
              </span>
            </div>
          })
          ->React.array}
        </div>
      : React.null}
    <div
      ref={ReactDOM.Ref.domRef(trackRef)}
      onClick=addAtClick
      className={trackClassName->Option.getOr(
        "relative z-10 h-12 rounded-md border border-gray-200 dark:border-[#3a3b40] bg-white dark:bg-[#1e1f23] overflow-hidden cursor-copy",
      )}>
      {demandCounts->Option.isSome && maxDemand > 0
        ? <div className="absolute inset-0 flex pointer-events-none">
            {Belt.Array.makeBy(hourRangeVal, i => {
              let hour = hourMinVal + i
              let count =
                demandCounts
                ->Option.getOr([])
                ->Array.find(hc => hc.hour == hour)
                ->Option.map(hc => hc.count)
                ->Option.getOr(0)
              let intensity = count->Float.fromInt /. maxDemand->Float.fromInt
              // Subtle in-track wash: 0 → invisible, max → 0.30. Keeps green chips legible.
              let opacity = if count == 0 {"0"} else {
                (0.08 +. intensity *. 0.22)->Float.toFixed(~digits=2)
              }
              <div
                key={i->Int.toString}
                className="flex-1 h-full"
                style={ReactDOM.Style.make(
                  ~backgroundColor=if count == 0 {
                    "transparent"
                  } else {
                    "rgba(139, 92, 246, " ++ opacity ++ ")"
                  },
                  (),
                )}
              />
            })->React.array}
          </div>
        : React.null}
      <div className="absolute inset-0 pointer-events-none">
        {Belt.Array.makeBy(hourRangeVal + 1, i => {
          let h = hourMinVal + i
          let lp = Float.fromInt(i) /. Float.fromInt(hourRangeVal) *. 100.0
          let major = mod(h, 3) === 0
          <div
            key={i->Int.toString}
            className={`absolute top-0 bottom-0 border-l ${major
                ? "border-gray-200 dark:border-[#2a2b30]"
                : "border-gray-100/70 dark:border-[#262729]"}`}
            style={ReactDOM.Style.make(~left=lp->Float.toString ++ "%", ())}
          />
        })->React.array}
      </div>
      {existingEvents->Array.length > 0
        ? <div className="absolute inset-0 pointer-events-none">
            {existingEvents
            ->Array.map(ev => {
              let leftPct =
                (ev.startHour -. Float.fromInt(hourMinVal)) /.
                Float.fromInt(hourRangeVal) *. 100.0
              let widthPct =
                (ev.endHour -. ev.startHour) /. Float.fromInt(hourRangeVal) *. 100.0
              <div
                key={ev.id}
                className="absolute top-1 bottom-1 rounded-sm border border-amber-300/70 dark:border-amber-500/40 flex items-center px-1.5 overflow-hidden"
                style={ReactDOM.Style.make(
                  ~left=leftPct->Float.toString ++ "%",
                  ~width=widthPct->Float.toString ++ "%",
                  ~backgroundImage="repeating-linear-gradient(45deg, rgba(255,176,66,0.18), rgba(255,176,66,0.18) 4px, rgba(255,176,66,0.05) 4px, rgba(255,176,66,0.05) 8px)",
                  (),
                )}>
                <span
                  className="text-[9px] md:text-[10px] font-mono font-medium text-amber-800 dark:text-amber-300/90 truncate leading-tight">
                  {React.string(ev.title)}
                </span>
              </div>
            })
            ->React.array}
          </div>
        : React.null}
      {intents->Array.length === 0
        ? <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <span className="text-[11px] font-mono text-gray-400 dark:text-gray-500">
              {t`Tap anywhere to add a time window`}
            </span>
          </div>
        : React.null}
      {intents
      ->Array.map(w =>
        <WindowChip
          key={w.id->Int.toString}
          intent=w
          trackRef
          onChange={next => updateOne(w.id, next)}
          onDelete={() => removeOne(w.id)}
          ?config
        />
      )
      ->React.array}
    </div>
    {demandCounts->Option.isSome && maxDemand > 0
      ? <div
          className="relative z-0 h-3 -mt-1.5 flex pointer-events-none"
          style={ReactDOM.Style.make(~filter="blur(5px)", ())}
          ariaHidden={true}>
          {Belt.Array.makeBy(hourRangeVal, i => {
            let hour = hourMinVal + i
            let count =
              demandCounts
              ->Option.getOr([])
              ->Array.find(hc => hc.hour == hour)
              ->Option.map(hc => hc.count)
              ->Option.getOr(0)
            if count == 0 {
              <div key={i->Int.toString} className="flex-1 h-full" />
            } else {
              let intensity = count->Float.fromInt /. maxDemand->Float.fromInt
              let opacity = (0.55 +. intensity *. 0.45)->Float.toFixed(~digits=2)
              <div
                key={i->Int.toString}
                className="flex-1 h-full"
                style={ReactDOM.Style.make(
                  ~backgroundColor="rgba(139, 92, 246, " ++ opacity ++ ")",
                  (),
                )}
              />
            }
          })->React.array}
        </div>
      : React.null}
  </div>
}

// ─── Presets ─────────────────────────────────────────────────────────────────

type preset = {
  id: string,
  label: string,
  start: float,
  end: float,
}

let matchPreset = (draft: array<playIntent>): option<string> => {
  if draft->Array.length !== 1 {
    None
  } else {
    let w = draft->Array.getUnsafe(0)
    switch (w.start, w.end) {
    | (9.0, 22.0) => Some("anytime")
    | (9.0, 12.0) => Some("morning")
    | (13.0, 16.0) => Some("afternoon")
    | (19.0, 22.0) => Some("evening")
    | _ => None
    }
  }
}

let defaultIntent = (): playIntent => {id: wid(), start: 19.0, end: 22.0}

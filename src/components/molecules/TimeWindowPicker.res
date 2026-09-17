%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
// Shared time-window model (playIntent, court types + grouping, time
// formatting) lives in TimeWindow; this file is just the picker UI on top.
open TimeWindow

let ts = Lingui.UtilString.t

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

type windowConfig = {
  hourMin?: int,
  hourMax?: int,
  snap?: float,
  minDuration?: float,
  defaultDuration?: float,
  // Grid line spacing in hours; defaults to the snap step. A picker snapping
  // finer than its grid (15-minute events on a half-hour grid) sets this so
  // the track doesn't fill with lines.
  gridStep?: float,
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
// A tap that lands inside a court-availability band this short (hours) snaps the
// new window to the band's exact span, so the user matches the whole opening in
// one tap. Longer openings fall back to a plain defaultDuration window.
let maxMatchableCourtHours = 4.0

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
// Per-integer-hour player counts across [hMin, hMax). Full-day callers use the
// module defaults; the slot-scoped picker passes the band's own bounds.
let computeDensity = (~hourMin as hMin=hourMin, ~hourMax as hMax=hourMax, intents: array<playIntent>): (
  array<int>,
  int,
) => {
  let counts = Belt.Array.makeBy(hMax - hMin, i => {
    let h = hMin + i
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

let snapTo = (h: float, step: float): float => Js.Math.round(h /. step) *. step

let clamp = (v: float, mn: float, mx: float): float =>
  Js.Math.max_float(mn, Js.Math.min_float(mx, v))

// Axis labels are tinted by half of the day (amber before noon, sky from noon
// on) so the AM/PM split reads at a glance; noon itself gets a heavier grid
// line to match.
let hourPeriodLabelClass = (h: float): string =>
  h < 12.0 ? "text-amber-600 dark:text-amber-300" : "text-sky-600 dark:text-sky-300"
let isNoon = (h: float): bool => Js.Math.abs_float(h -. 12.0) < 0.001

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
    ~allowDelete: bool=true,
  ) => {
    let hourMinVal = config->Option.flatMap(c => c.hourMin)->Option.getOr(hourMin)->Float.fromInt
    let hourMaxVal = config->Option.flatMap(c => c.hourMax)->Option.getOr(hourMax)->Float.fromInt
    let snapStep = config->Option.flatMap(c => c.snap)->Option.getOr(1.0)
    let minDur = config->Option.flatMap(c => c.minDuration)->Option.getOr(minDuration)
    let hourRangeVal = hourMaxVal -. hourMinVal
    let intl = ReactIntl.useIntl()

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
      className={`absolute top-2 bottom-2 select-none touch-none group rounded border shadow-sm flex items-center justify-between gap-1 ${drag->Option.isSome
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
          ? React.string(hourLabelIntl(intl, intent.start) ++ "–" ++ hourLabelIntl(intl, intent.end))
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
      {allowDelete
        ? <button
            onPointerDown={e => e->ReactEvent.Pointer.stopPropagation}
            onClick={e => {
              e->ReactEvent.Mouse.stopPropagation
              onDelete()
            }}
            className="absolute -top-1.5 -right-1.5 w-4 h-4 rounded-full bg-white dark:bg-[#1e1f23] border border-gray-300 dark:border-[#3a3b40] flex items-center justify-center opacity-0 group-hover:opacity-100 focus:opacity-100 transition-opacity shadow-sm"
            title={Lingui.UtilString.t`Remove`}>
            <Lucide.X size=10 className="text-gray-600 dark:text-gray-300" />
          </button>
        : React.null}
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
  ~demandIntents: array<playIntent>=?,
  ~existingEvents: array<existingEvent>=[],
  ~courtAvailability: array<courtAvailability>=[],
  ~emptyLabel: string=?,
  // Caps how many windows a tap can add (a single-window form picker passes 1);
  // dragging existing windows is unaffected.
  ~maxIntents: int=?,
  ~allowDelete: bool=true,
) => {
  let trackRef = React.useRef(Js.Nullable.null)
  let intl = ReactIntl.useIntl()

  let hourMinVal = config->Option.flatMap(c => c.hourMin)->Option.getOr(hourMin)
  let hourMaxVal = config->Option.flatMap(c => c.hourMax)->Option.getOr(hourMax)
  let hourRangeVal = hourMaxVal - hourMinVal
  let snapStep = config->Option.flatMap(c => c.snap)->Option.getOr(1.0)
  let minDur = config->Option.flatMap(c => c.minDuration)->Option.getOr(minDuration)
  let defaultDur = config->Option.flatMap(c => c.defaultDuration)->Option.getOr(defaultDuration)
  let gridStep = config->Option.flatMap(c => c.gridStep)->Option.getOr(snapStep)

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

  let courtBands = groupCourtAvailabilityIntoBands(courtAvailability)

  let canAdd = switch maxIntents {
  | None => true
  | Some(max) => intents->Array.length < max
  }

  let addAtClick = (e: ReactEvent.Mouse.t) => {
    switch (canAdd, trackRef.current->Js.Nullable.toOption) {
    | (false, _)
    | (_, None) => ()
    | (true, Some(el)) =>
      let rect = el->getBoundingClientRect
      if rect.width !== 0.0 {
        let x = e->mouseClientX->Float.fromInt -. rect.left
        let rawHour = Float.fromInt(hourMinVal) +. x /. rect.width *. Float.fromInt(hourRangeVal)
        let start = clamp(
          snapTo(rawHour, snapStep),
          Float.fromInt(hourMinVal),
          Float.fromInt(hourMaxVal) -. minDur,
        )
        let inside = intents->Array.some(w => start >= w.start && start < w.end)
        if !inside {
          // If the tap lands inside a short court-availability band, snap the new
          // window to that band's exact opening (as long as it wouldn't overlap
          // an existing window). Otherwise fall back to a plain window that fills
          // the gap up to defaultDur.
          let snapBand =
            courtBands->Array.find(b =>
              rawHour >= b.start &&
              rawHour < b.end &&
              b.end -. b.start <= maxMatchableCourtHours &&
              !(intents->Array.some(w => b.start < w.end && b.end > w.start))
            )
          switch snapBand {
          | Some(b) => onChange(Belt.Array.concat(intents, [{id: wid(), start: b.start, end: b.end}]))
          | None =>
            let nextStart = intents->Array.reduce(Float.fromInt(hourMaxVal), (acc, w) =>
              if w.start >= start && w.start < acc {
                w.start
              } else {
                acc
              }
            )
            let duration = Js.Math.min_float(
              Js.Math.min_float(defaultDur, nextStart -. start),
              Float.fromInt(hourMaxVal) -. start,
            )
            if duration >= minDur {
              onChange(Belt.Array.concat(intents, [{id: wid(), start, end: start +. duration}]))
            }
          }
        }
      }
    }
  }

  // Sparse axis for narrow slot ranges; every 3h for the full-day picker.
  let axisStep = hourRangeVal <= 4 ? Js.Math.max_float(0.5, Float.fromInt(hourRangeVal) /. 2.0) : 3.0
  let axisHours = {
    let arr = []
    let cursor = ref(Float.fromInt(hourMinVal))
    while cursor.contents < Float.fromInt(hourMaxVal) {
      arr->Array.push(cursor.contents)
      cursor := cursor.contents +. axisStep
    }
    arr->Array.push(Float.fromInt(hourMaxVal))
    arr
  }

  // Player-demand heatmap source: either raw intents (slot picker, computed over
  // the visible range) or pre-aggregated hourly counts (full-day feed picker).
  let heatmap = switch demandIntents {
  | Some(di) if di->Array.length > 0 =>
    Some(computeDensity(~hourMin=hourMinVal, ~hourMax=hourMaxVal, di))
  | _ =>
    switch demandCounts {
    | Some(dc) if maxDemand > 0 =>
      Some((
        Belt.Array.makeBy(hourRangeVal, i => {
          let hour = hourMinVal + i
          dc->Array.find(hc => hc.hour == hour)->Option.map(hc => hc.count)->Option.getOr(0)
        }),
        maxDemand,
      ))
    | _ => None
    }
  }

  <div className={className->Option.getOr("")}>
    {showAxis
      ? <div className="relative h-4 mb-0.5">
          {axisHours
          ->Array.mapWithIndex((h, i) => {
            let lp = (h -. Float.fromInt(hourMinVal)) /. Float.fromInt(hourRangeVal) *. 100.0
            <div
              key={h->Float.toString}
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
              <span className={`font-mono text-[9px] ${hourPeriodLabelClass(h)}`}>
                {React.string(hourLabelIntl(intl, h))}
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
        "relative h-12 rounded-lg border border-gray-200 dark:border-[#3a3b40] bg-white dark:bg-[#1e1f23] overflow-hidden " ++ (
          canAdd ? "cursor-copy" : "cursor-default"
        ),
      )}>
      {switch heatmap {
      | Some((counts, maxD)) =>
        <div
          className="absolute inset-0 z-0 flex pointer-events-none"
          role="img"
          ariaLabel={Lingui.UtilString.t`Player availability heatmap`}>
          {counts
          ->Array.mapWithIndex((count, i) => {
            let intensity = maxD > 0 ? count->Float.fromInt /. maxD->Float.fromInt : 0.0
            // Background wash: 0 → invisible, max → ~0.28. Faint enough to sit
            // behind courts, events and the green chips without muddying them.
            let opacity = if count == 0 {"0"} else {
              (0.08 +. intensity *. 0.2)->Float.toFixed(~digits=2)
            }
            <div
              key={i->Int.toString}
              className="flex-1 h-full border-y border-violet-200/40 dark:border-violet-800/25"
              style={ReactDOM.Style.make(
                ~backgroundColor=if count == 0 {
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
      | None => React.null
      }}
      {
        // One gridline per grid step; whole hours read as the major lines.
        let gridLineCount =
          Js.Math.max_int(1, Js.Math.round(Float.fromInt(hourRangeVal) /. gridStep)->Float.toInt)
        <div className="absolute inset-0 z-[1] pointer-events-none">
          {Belt.Array.makeBy(gridLineCount + 1, i => {
            let hour = Float.fromInt(hourMinVal) +. Float.fromInt(i) *. gridStep
            let lp = Float.fromInt(i) /. Float.fromInt(gridLineCount) *. 100.0
            let major = Js.Math.floor_float(hour) == hour
            <div
              key={i->Int.toString}
              className={`absolute top-0 bottom-0 border-l ${if isNoon(hour) {
                  "border-l-2 border-sky-300 dark:border-sky-700"
                } else if major {
                  "border-gray-200 dark:border-[#34353a]"
                } else {
                  "border-gray-100/70 dark:border-[#292a2e]"
                }}`}
              style={ReactDOM.Style.make(~left=lp->Float.toString ++ "%", ())}
            />
          })->React.array}
        </div>
      }
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
                title={ev.title ++
                " · " ++
                hourLabelIntl(intl, ev.startHour) ++
                "–" ++
                hourLabelIntl(intl, ev.endHour)}
                className="user-event-block absolute inset-y-2 z-[15] flex items-center overflow-hidden rounded border px-1.5 shadow-sm"
                style={ReactDOM.Style.make(
                  ~left=leftPct->Float.toString ++ "%",
                  ~width=widthPct->Float.toString ++ "%",
                  (),
                )}>
                <span
                  className="min-w-0 truncate font-mono text-[9px] font-semibold text-amber-950 dark:text-amber-200">
                  {React.string(ev.title)}
                </span>
              </div>
            })
            ->React.array}
          </div>
        : React.null}
      // Court openings as one smooth cyan silhouette anchored to the bottom of
      // the track — thickness = court count, blending smoothly at changes.
      // Read-only — clicks fall through to add.
      <CourtAvailabilityBandOverlay
        bands=courtBands
        hourMin=hourMinVal
        hourMax=hourMaxVal
        placement=CourtAvailabilityBandOverlay.End
      />
      {intents->Array.length === 0
        ? <div
            className="absolute inset-0 z-[15] flex items-center justify-center pointer-events-none">
            <span className="text-[10px] font-mono text-gray-400 dark:text-gray-500">
              {React.string(emptyLabel->Option.getOr(Lingui.UtilString.t`Tap to add your time`))}
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
          allowDelete
        />
      )
      ->React.array}
    </div>
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

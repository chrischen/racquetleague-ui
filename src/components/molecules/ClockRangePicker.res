%%raw("import { t } from '@lingui/macro'")

// Circular start/end time picker, ported from the Magic Patterns
// ClockRangePicker. Two native time inputs sit above a 12-hour dial; the S/E
// handles (or the dial itself, which moves whichever endpoint was last active)
// set times in 15-minute steps. The dial only shows 12 hours, so dragging
// across 12 flips that endpoint between AM and PM, and the sun/moon toggle
// shifts both endpoints together. The range is measured forward from the
// start, so it may wrap past midnight, and is clamped to 15 minutes–12 hours.

let ts = Lingui.UtilString.t

@get external currentTargetEl: ReactEvent.Pointer.t => Dom.element = "currentTarget"
@get external pointerClientX: ReactEvent.Pointer.t => float = "clientX"
@get external pointerClientY: ReactEvent.Pointer.t => float = "clientY"
@send
external setPointerCapture: (Dom.element, Dom.eventPointerId) => unit = "setPointerCapture"
@send
external hasPointerCapture: (Dom.element, Dom.eventPointerId) => bool = "hasPointerCapture"
type domRect = {left: float, top: float, width: float, height: float}
@send external getBoundingClientRect: Dom.element => domRect = "getBoundingClientRect"

type endpoint = Start | End
type period = AM | PM

let clockMinutes = 12 * 60
let dayMinutes = 24 * 60
let timeStepMinutes = 15
// The dial is drawn in a 240×240 viewBox; handles and labels are positioned
// as percentages of it so the dial can scale with its container.
let viewSize = 240.
let center = 120.
let trackRadius = 92.
let labelRadius = 76.
let trackCircumference = 2. *. Math.Constants.pi *. trackRadius

let timeToMinutes = (value: string): int =>
  switch value->String.split(":") {
  | [h, m] => h->Int.fromString->Option.getOr(0) * 60 + m->Int.fromString->Option.getOr(0)
  | _ => 0
  }

let wrapDay = minutes => mod(mod(minutes, dayMinutes) + dayMinutes, dayMinutes)

let forwardDuration = (startMinutes, endMinutes) => wrapDay(endMinutes - startMinutes)

let minutesToTime = (totalMinutes: int): string => {
  let normalized = wrapDay(totalMinutes)
  let pad = n => n->Int.toString->String.padStart(2, "0")
  `${pad(normalized / 60)}:${pad(mod(normalized, 60))}`
}

let snapToStep = (minutes: float): int =>
  Math.round(minutes /. timeStepMinutes->Int.toFloat)->Float.toInt * timeStepMinutes

let minutesToAngle = (minutes: int): float =>
  mod(minutes, clockMinutes)->Int.toFloat /. clockMinutes->Int.toFloat *. 360.

// Rounded to 3 decimals: sin/cos differ in the last bits between Node and the
// browser, and these coordinates end up as SVG attribute strings, so unrounded
// values cause a hydration mismatch on every render of the dial.
let round3 = v => Math.round(v *. 1000.) /. 1000.
let polarPoint = (angle: float, radius: float) => {
  let radians = angle *. Math.Constants.pi /. 180.
  (
    round3(center +. Math.sin(radians) *. radius),
    round3(center -. Math.cos(radians) *. radius),
  )
}

let percentOfView = v => `${(v /. viewSize *. 100.)->Float.toString}%`

let periodOf = minutes => minutes >= clockMinutes ? PM : AM

let formatDuration = (totalMinutes: int): string => {
  let hours = totalMinutes / 60
  let minutes = mod(totalMinutes, 60)
  if hours == 0 {
    `${minutes->Int.toString}m`
  } else if minutes == 0 {
    `${hours->Int.toString}h`
  } else {
    `${hours->Int.toString}h ${minutes->Int.toString}m`
  }
}

let formatClockTime = (minutes: int): string => {
  let hour12 = switch mod(minutes / 60, 12) {
  | 0 => 12
  | h => h
  }
  `${hour12->Int.toString}:${mod(minutes, 60)->Int.toString->String.padStart(2, "0")}`
}

// Drag bookkeeping. The dial angle only yields a 12-hour position, so each
// drag remembers which half of the day the endpoint is in and flips it when
// the pointer crosses 12 o'clock.
type dragState = {
  endpoint: endpoint,
  mutable previousClockMinutes: int,
  mutable periodOffset: int,
}

let stepFromKey = (e: ReactEvent.Keyboard.t): option<int> => {
  let big = e->ReactEvent.Keyboard.shiftKey
  switch e->ReactEvent.Keyboard.key {
  | "ArrowRight" | "ArrowUp" => Some(big ? 60 : timeStepMinutes)
  | "ArrowLeft" | "ArrowDown" => Some(big ? -60 : -timeStepMinutes)
  | _ => None
  }
}

module Handle = {
  @react.component
  let make = (
    ~endpoint: endpoint,
    ~active: bool,
    ~x: float,
    ~y: float,
    ~onActivate: unit => unit,
    ~onDragStart: unit => unit,
    ~onDrag: (float, float) => unit,
    ~onDragEnd: unit => unit,
    ~onStep: int => unit,
  ) => {
    let ts = Lingui.UtilString.t
    <button
      type_="button"
      ariaLabel={endpoint == Start ? ts`Drag start time` : ts`Drag end time`}
      onFocus={_ => onActivate()}
      onPointerDown={e => {
        e->ReactEvent.Pointer.stopPropagation
        onActivate()
        onDragStart()
        e->currentTargetEl->setPointerCapture(e->ReactEvent.Pointer.pointerId)
      }}
      onPointerMove={e =>
        if e->currentTargetEl->hasPointerCapture(e->ReactEvent.Pointer.pointerId) {
          onDrag(e->pointerClientX, e->pointerClientY)
        }}
      onPointerUp={_ => onDragEnd()}
      onPointerCancel={_ => onDragEnd()}
      onKeyDown={e =>
        switch stepFromKey(e) {
        | Some(step) => {
            e->ReactEvent.Keyboard.preventDefault
            e->ReactEvent.Keyboard.stopPropagation
            onStep(step)
          }
        | None => ()
        }}
      className={Util.cx([
        "absolute z-30 flex h-11 w-11 touch-none -translate-x-1/2 -translate-y-1/2 cursor-grab items-center justify-center rounded-full outline-none active:cursor-grabbing focus-visible:ring-2 focus-visible:ring-[#94c93a]",
        active ? "z-40" : "",
      ])}
      style={ReactDOM.Style.make(~left=percentOfView(x), ~top=percentOfView(y), ())}>
      <span
        className={Util.cx([
          "flex h-7 w-7 items-center justify-center rounded-full border-2 border-white text-[9px] font-bold text-white shadow-md dark:border-[#222326]",
          endpoint == Start ? "bg-gray-700" : "bg-[#86b52f]",
          active ? "ring-2 ring-[#94c93a]" : "",
        ])}
        ariaHidden=true>
        {(endpoint == Start ? "S" : "E")->React.string}
      </span>
    </button>
  }
}

let timeInputClass = "native-time-input block h-full w-full min-w-0 max-w-full border-0 bg-transparent text-gray-900 outline-none dark:text-gray-100"

@react.component
let make = (
  ~startTime: string,
  ~endTime: string,
  ~onStartTimeChange: string => unit,
  ~onEndTimeChange: string => unit,
) => {
  open Lingui.Util
  let (activeEndpoint, setActiveEndpoint) = React.useState(() => Start)
  let dialRef: React.ref<Js.Nullable.t<Dom.element>> = React.useRef(Js.Nullable.null)
  let dragState: React.ref<option<dragState>> = React.useRef(None)

  let startMinutes = timeToMinutes(startTime)
  let endMinutes = timeToMinutes(endTime)
  let durationMinutes = forwardDuration(startMinutes, endMinutes)
  let validRange = durationMinutes >= timeStepMinutes && durationMinutes <= clockMinutes
  let activeMinutes = activeEndpoint == Start ? startMinutes : endMinutes
  let activePeriod = periodOf(activeMinutes)
  // A full 12-hour arc would close on itself; trim it so the round caps stay
  // visible as a ring rather than merging into an unbroken circle.
  let arcLength =
    durationMinutes == clockMinutes
      ? trackCircumference -. 0.5
      : durationMinutes->Int.toFloat /. clockMinutes->Int.toFloat *. trackCircumference
  let startAngle = minutesToAngle(startMinutes)
  let (startX, startY) = polarPoint(startAngle, trackRadius)
  let (endX, endY) = polarPoint(minutesToAngle(endMinutes), trackRadius)

  // Moving the start only drags the end along when the range would otherwise
  // fall outside 15 minutes–12 hours; moving the end is clamped to that window.
  let updateEndpoint = (endpoint, minutes: int) => {
    let snapped = snapToStep(minutes->Int.toFloat)
    switch endpoint {
    | Start => {
        let nextStart = Js.Math.min_int(Js.Math.max_int(snapped, 0), dayMinutes - timeStepMinutes)
        let forwardGap = forwardDuration(nextStart, endMinutes)
        onStartTimeChange(minutesToTime(nextStart))
        if forwardGap < timeStepMinutes || forwardGap > clockMinutes {
          onEndTimeChange(minutesToTime(nextStart + timeStepMinutes))
        }
      }
    | End => {
        let candidateEnd = wrapDay(snapped)
        let duration = forwardDuration(startMinutes, candidateEnd)
        let nextEnd = if duration < timeStepMinutes {
          wrapDay(startMinutes + timeStepMinutes)
        } else if duration > clockMinutes {
          wrapDay(startMinutes + clockMinutes)
        } else {
          candidateEnd
        }
        onEndTimeChange(minutesToTime(nextEnd))
      }
    }
  }

  let beginEndpointDrag = endpoint => {
    let endpointMinutes = endpoint == Start ? startMinutes : endMinutes
    dragState.current = Some({
      endpoint,
      previousClockMinutes: mod(endpointMinutes, clockMinutes),
      periodOffset: endpointMinutes >= clockMinutes ? clockMinutes : 0,
    })
  }
  let endEndpointDrag = () => dragState.current = None

  let selectFromPointer = (endpoint, clientX: float, clientY: float) =>
    switch dialRef.current->Js.Nullable.toOption {
    | None => ()
    | Some(el) => {
        let bounds = el->getBoundingClientRect
        let centerX = bounds.left +. bounds.width /. 2.
        let centerY = bounds.top +. bounds.height /. 2.
        // Angle clockwise from 12 o'clock.
        let angle = Math.atan2(~y=clientX -. centerX, ~x=centerY -. clientY)
        let normalizedAngle = angle < 0. ? angle +. Math.Constants.pi *. 2. : angle
        let clockMins = mod(
          snapToStep(normalizedAngle /. (Math.Constants.pi *. 2.) *. clockMinutes->Int.toFloat),
          clockMinutes,
        )
        let state = switch dragState.current {
        | Some(s) if s.endpoint == endpoint => Some(s)
        | _ => {
            beginEndpointDrag(endpoint)
            dragState.current
          }
        }
        switch state {
        | None => ()
        | Some(s) => {
            let crossedClockwise =
              s.previousClockMinutes > clockMinutes * 3 / 4 && clockMins < clockMinutes / 4
            let crossedCounterClockwise =
              s.previousClockMinutes < clockMinutes / 4 && clockMins > clockMinutes * 3 / 4
            if crossedClockwise || crossedCounterClockwise {
              s.periodOffset = s.periodOffset == 0 ? clockMinutes : 0
            }
            s.previousClockMinutes = clockMins
            updateEndpoint(endpoint, s.periodOffset + clockMins)
          }
        }
      }
    }

  let moveActiveEndpoint = step => updateEndpoint(activeEndpoint, activeMinutes + step)

  let setRangePeriod = period =>
    if period != activePeriod {
      let shift = period == PM ? clockMinutes : -clockMinutes
      dragState.current = None
      onStartTimeChange(minutesToTime(startMinutes + shift))
      onEndTimeChange(minutesToTime(endMinutes + shift))
    }

  let timeInput = (endpoint, value, onChange) =>
    <label className="block min-w-0 overflow-hidden">
      <span
        className="mb-1 block text-[10px] font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
        {endpoint == Start ? t`Start` : t`End`}
      </span>
      <div
        className={Util.cx([
          "box-border h-10 w-full min-w-0 max-w-full overflow-hidden rounded-lg border bg-white transition-colors focus-within:ring-2 focus-within:ring-[#bdf25d]/40 dark:bg-[#1e1f23]",
          activeEndpoint == endpoint ? "border-[#94c93a]" : "border-gray-200 dark:border-[#3a3b40]",
        ])}>
        <input
          type_="time"

          step={(timeStepMinutes * 60)->Int.toFloat}
          value
          onFocus={_ => setActiveEndpoint(_ => endpoint)}
          onChange={e => {
            let v: string = ReactEvent.Form.target(e)["value"]
            if v != "" {
              onChange(timeToMinutes(v))
            }
          }}
          className=timeInputClass
        />
      </div>
    </label>

  <div
    className="min-w-0 overflow-hidden rounded-xl border border-gray-200 bg-white p-3 dark:border-[#3a3b40] dark:bg-[#222326]">
    <div className="grid min-w-0 grid-cols-2 gap-2" ariaLabel={ts`Event time range`}>
      {timeInput(Start, startTime, m => updateEndpoint(Start, m))}
      {timeInput(End, endTime, m => updateEndpoint(End, m))}
    </div>
    <div
      ref={ReactDOM.Ref.domRef(dialRef)}
      role="slider"
      tabIndex=0
      ariaLabel={activeEndpoint == Start ? ts`start time` : ts`end time`}
      ariaValuemin=0.
      ariaValuemax={(dayMinutes - timeStepMinutes)->Int.toFloat}
      ariaValuenow={activeMinutes->Int.toFloat}
      ariaValuetext={`${formatClockTime(activeMinutes)}, ${activePeriod == AM
          ? ts`daytime`
          : ts`nighttime`}`}
      onPointerDown={e => {
        beginEndpointDrag(activeEndpoint)
        e->currentTargetEl->setPointerCapture(e->ReactEvent.Pointer.pointerId)
        selectFromPointer(activeEndpoint, e->pointerClientX, e->pointerClientY)
      }}
      onPointerMove={e =>
        if e->currentTargetEl->hasPointerCapture(e->ReactEvent.Pointer.pointerId) {
          selectFromPointer(activeEndpoint, e->pointerClientX, e->pointerClientY)
        }}
      onPointerUp={_ => endEndpointDrag()}
      onPointerCancel={_ => endEndpointDrag()}
      onKeyDown={e =>
        switch stepFromKey(e) {
        | Some(step) => {
            e->ReactEvent.Keyboard.preventDefault
            moveActiveEndpoint(step)
          }
        | None => ()
        }}
      className="relative mx-auto mt-3 aspect-square w-full max-w-[264px] touch-none cursor-crosshair rounded-full outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 dark:focus-visible:ring-offset-[#222326]">
      <svg
        viewBox="0 0 240 240"
        className="pointer-events-none absolute inset-0 h-full w-full"
        ariaHidden=true>
        <circle
          cx="120"
          cy="120"
          r="92"
          fill="none"
          stroke="currentColor"
          strokeWidth="10"
          className="text-gray-100 dark:text-[#2a2b30]"
        />
        {validRange
          ? <circle
              cx="120"
              cy="120"
              r="92"
              fill="none"
              stroke="currentColor"
              strokeWidth="10"
              strokeLinecap="round"
              strokeDasharray={`${arcLength->Float.toString} ${(trackCircumference -. arcLength)
                  ->Float.toString}`}
              transform={`rotate(${(startAngle -. 90.)->Float.toString} 120 120)`}
              className="text-[#94c93a]"
            />
          : React.null}
        {Array.fromInitializer(~length=48, index => {
          let angle = index->Int.toFloat *. 7.5
          let major = mod(index, 4) == 0
          let (ox, oy) = polarPoint(angle, 105.)
          let (ix, iy) = polarPoint(angle, major ? 98. : 102.)
          <line
            key={index->Int.toString}
            x1={ix->Float.toString}
            y1={iy->Float.toString}
            x2={ox->Float.toString}
            y2={oy->Float.toString}
            stroke="currentColor"
            strokeWidth={major ? "1.5" : "1"}
            className="text-gray-300 dark:text-gray-600"
          />
        })->React.array}
        <line
          x1="120"
          y1="120"
          x2={startX->Float.toString}
          y2={startY->Float.toString}
          stroke="currentColor"
          strokeWidth="1.5"
          className="text-gray-400 dark:text-gray-500"
        />
        <line
          x1="120"
          y1="120"
          x2={endX->Float.toString}
          y2={endY->Float.toString}
          stroke="currentColor"
          strokeWidth="1.5"
          className="text-[#6f9627] dark:text-[#bdf25d]"
        />
      </svg>
      {[12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
      ->Array.mapWithIndex((hour, index) => {
        let (x, y) = polarPoint(index->Int.toFloat *. 30., labelRadius)
        <span
          key={hour->Int.toString}
          className="pointer-events-none absolute flex h-6 w-6 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full font-mono text-[10px] font-semibold text-gray-600 dark:text-gray-300"
          style={ReactDOM.Style.make(~left=percentOfView(x), ~top=percentOfView(y), ())}
          ariaHidden=true>
          {hour->Int.toString->React.string}
        </span>
      })
      ->React.array}
      <div
        className="pointer-events-none absolute left-1/2 top-1/2 w-24 -translate-x-1/2 -translate-y-1/2 text-center">
        <span className="block font-mono text-base font-semibold text-gray-900 dark:text-gray-100">
          {(validRange ? formatDuration(durationMinutes) : "—")->React.string}
        </span>
        <span
          className="mt-0.5 block text-[9px] font-semibold uppercase tracking-wide text-gray-400">
          {t`duration`}
        </span>
      </div>
      <Handle
        endpoint=Start
        active={activeEndpoint == Start}
        x=startX
        y=startY
        onActivate={() => setActiveEndpoint(_ => Start)}
        onDragStart={() => beginEndpointDrag(Start)}
        onDrag={(cx, cy) => selectFromPointer(Start, cx, cy)}
        onDragEnd=endEndpointDrag
        onStep={step => updateEndpoint(Start, startMinutes + step)}
      />
      <Handle
        endpoint=End
        active={activeEndpoint == End}
        x=endX
        y=endY
        onActivate={() => setActiveEndpoint(_ => End)}
        onDragStart={() => beginEndpointDrag(End)}
        onDrag={(cx, cy) => selectFromPointer(End, cx, cy)}
        onDragEnd=endEndpointDrag
        onStep={step => updateEndpoint(End, endMinutes + step)}
      />
    </div>
    <div className="mt-3 flex items-center justify-between gap-3">
      <p className="text-xs text-gray-500 dark:text-gray-400">
        {activeEndpoint == Start ? t`Editing start` : t`Editing end`}
      </p>
      <div
        className="grid grid-cols-2 overflow-hidden rounded-md border border-gray-200 dark:border-[#3a3b40]">
        {[AM, PM]
        ->Array.map(period => {
          let pressed = activePeriod == period
          <button
            key={period == AM ? "am" : "pm"}
            type_="button"
            onClick={_ => setRangePeriod(period)}
            ariaLabel={period == AM
              ? ts`Move start and end to daytime hours`
              : ts`Move start and end to nighttime hours`}
            ariaPressed={pressed ? #"true" : #"false"}
            className={Util.cx([
              "flex h-8 min-w-[46px] items-center justify-center transition-colors duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[#94c93a]",
              pressed
                ? "bg-[#bdf25d] text-black"
                : "bg-white text-gray-500 hover:bg-gray-50 dark:bg-[#1e1f23] dark:text-gray-400 dark:hover:bg-[#2a2b30]",
            ])}>
            {period == AM
              ? <Lucide.Sun size=15 \"aria-hidden"="true" />
              : <Lucide.Moon size=15 \"aria-hidden"="true" />}
          </button>
        })
        ->React.array}
      </div>
    </div>
    <p className="mt-2 text-center text-[10px] text-gray-500 dark:text-gray-400">
      {t`Drag around the clock · Arrow keys move 15 minutes`}
    </p>
  </div>
}

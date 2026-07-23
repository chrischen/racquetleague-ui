%%raw("import { t, plural } from '@lingui/macro'")

// Read-only court-availability overlay for a time track — a purely contextual
// background layer that never mutates the user's selected availability
// (pointer-events-none, so clicks fall through to the track beneath).
//
// Three visual encodings of the same band/segment model:
//   • Line (placement=Center) — a cyan bar whose thickness encodes the court
//             count. Sits at the full inset (z-[5]) as a hairline.
//   • Edge (placement=Edge)   — a cyan cell-border outline (border-2, no fill)
//             filling each segment. The default timeline treatment: courts read
//             as an outlined footprint behind the events and green chips.
//   • Box   — a filled cyan block whose opacity encodes the court count, inset
//             one step deeper (inset-y-3 / left-3 right-3, z-10).
//
// Shared by the horizontal inline picker track and the vertical schedule
// column (the `orientation` prop). Depends only on the UI-free TimeWindow
// model, so callers can render it without a module cycle.

let ts = Lingui.UtilString.t

type orientation = Horizontal | Vertical
// `Start`/`End` anchor a smooth thickness silhouette to that edge of the track
// (top/bottom when horizontal, left/right when vertical); `Edge` renders cell
// borders; `Center` a thin centered bar.
type placement = Center | Start | End | Edge
type display = Line | Box
type variant = BoxV | EdgeV | LineV | SmoothV

// Court count → profile thickness in px: 1 court ⇒ 4px, +3px per extra court,
// capped at 18px — a fuller "demand profile" scale, kept readable by the low
// fill opacity below.
let getCourtLineThickness = (courtCount: int) =>
  Js.Math.min_int(18, 4 + Js.Math.max_int(0, courtCount - 1) * 3)

let corner = (on, px) => on ? px : "0px"

// Logistic eased 0→1, rescaled so the endpoints hit exactly 0 and 1.
let normalizedLogistic = (progress: float): float => {
  let steepness = 9.0
  let logistic = value => 1.0 /. (1.0 +. Js.Math.exp(-.(steepness *. (value -. 0.5))))
  let low = logistic(0.0)
  let high = logistic(1.0)
  (logistic(progress) -. low) /. (high -. low)
}

let clampUnit = value => Js.Math.max_float(0.0, Js.Math.min_float(1.0, value))

type thicknessProfile = {pStart: float, pEnd: float, px: float}

// One smooth silhouette per contiguous band: per-segment thickness (from the
// court total) blended with a logistic over ≤30 minutes at count changes, and
// logistic-tapered into both caps. Returns a CSS polygon() clip-path anchored
// to the requested edge of the track.
let getSmoothBandClipPath = (
  band: TimeWindow.courtAvailabilityBand,
  orientation: orientation,
  placement: placement,
): string => {
  let profiles = band.segments->Array.map(segment => {
    pStart: segment.start,
    pEnd: segment.end,
    px: getCourtLineThickness(
      TimeWindow.summarizeCourtAvailability(
        ~fromHour=segment.start->Float.toInt,
        ~toHour=segment.end->Float.toInt,
        segment.slots->Array.map(s => s.court),
      ).courtCount,
    )->Float.fromInt,
  })
  let duration = band.end -. band.start
  let capSpan = Js.Math.min_float(0.45, duration *. 0.22)
  let sampleCount = Js.Math.max_int(72, Js.Math.ceil_int(duration *. 12.0))
  let thicknessAt = (hour: float) => {
    let thickness = ref(profiles->Array.get(0)->Option.map(p => p.px)->Option.getOr(0.0))
    for index in 1 to profiles->Array.length - 1 {
      let previous = profiles->Array.getUnsafe(index - 1)
      let current = profiles->Array.getUnsafe(index)
      let transitionSpan = Js.Math.min_float(
        0.5,
        Js.Math.min_float(
          (previous.pEnd -. previous.pStart) *. 0.5,
          (current.pEnd -. current.pStart) *. 0.5,
        ),
      )
      let progress = clampUnit(
        (hour -. (current.pStart -. transitionSpan /. 2.0)) /. transitionSpan,
      )
      thickness := thickness.contents +. (current.px -. previous.px) *. normalizedLogistic(progress)
    }
    let startProgress = clampUnit((hour -. band.start) /. capSpan)
    let endProgress = clampUnit((band.end -. hour) /. capSpan)
    thickness.contents *. normalizedLogistic(startProgress) *. normalizedLogistic(endProgress)
  }
  let points = Belt.Array.makeBy(sampleCount + 1, index => {
    let progress = index->Float.fromInt /. sampleCount->Float.fromInt
    (progress, thicknessAt(band.start +. duration *. progress))
  })
  let pct = p => (p *. 100.0)->Float.toFixed(~digits=2) ++ "%"
  let px = t => t->Float.toFixed(~digits=2) ++ "px"
  switch (orientation, placement) {
  | (Horizontal, End) => {
      let edge =
        points->Array.map(((p, t)) => pct(p) ++ " calc(100% - " ++ px(t) ++ ")")->Array.join(", ")
      "polygon(0 100%, " ++ edge ++ ", 100% 100%)"
    }
  | (Horizontal, _) => {
      // Start: anchored to the top edge; trace the profile right-to-left.
      let reversed =
        points->Array.toReversed->Array.map(((p, t)) => pct(p) ++ " " ++ px(t))->Array.join(", ")
      "polygon(0 0, 100% 0, " ++ reversed ++ ")"
    }
  | (Vertical, Start) => {
      let edge = points->Array.map(((p, t)) => px(t) ++ " " ++ pct(p))->Array.join(", ")
      "polygon(0 0, " ++ edge ++ ", 0 100%)"
    }
  | (Vertical, _) => {
      // End: anchored to the right edge.
      let edge =
        points->Array.map(((p, t)) => "calc(100% - " ++ px(t) ++ ") " ++ pct(p))->Array.join(", ")
      "polygon(100% 0, " ++ edge ++ ", 100% 100%)"
    }
  }
}

@react.component
let make = (
  ~bands: array<TimeWindow.courtAvailabilityBand>,
  ~hourMin: int,
  ~hourMax: int,
  ~orientation: orientation=Horizontal,
  ~placement: placement=Center,
  ~display: display=Line,
) => {
  let intl = ReactIntl.useIntl()
  let fmt = h => TimeWindow.hourLabelIntl(intl, h)
  let hourRange = (hourMax - hourMin)->Float.fromInt

  let variant = switch (display, placement) {
  | (Box, _) => BoxV
  | (Line, Edge) => EdgeV
  | (Line, Start) | (Line, End) => SmoothV
  | (Line, Center) => LineV
  }

  bands
  ->Array.map(band => {
    let bandOffset = (band.start -. hourMin->Float.fromInt) /. hourRange *. 100.0
    let bandSize = (band.end -. band.start) /. hourRange *. 100.0
    let bandStyle = switch orientation {
    | Horizontal =>
      ReactDOM.Style.make(
        ~left=bandOffset->Float.toString ++ "%",
        ~width=bandSize->Float.toString ++ "%",
        (),
      )
    | Vertical =>
      ReactDOM.Style.make(
        ~top=bandOffset->Float.toString ++ "%",
        ~height=bandSize->Float.toString ++ "%",
        (),
      )
    }
    <div
      key={band.key}
      role="img"
      ariaLabel={fmt(band.start) ++ "–" ++ fmt(band.end)}
      className={`pointer-events-none absolute overflow-visible ${switch variant {
        | BoxV => "z-10"
        | EdgeV | LineV | SmoothV => "z-[5]"
        }} ${switch orientation {
        | Horizontal =>
          switch variant {
          | BoxV => "inset-y-3 min-w-5"
          | EdgeV | LineV | SmoothV => "inset-y-0 min-w-5"
          }
        | Vertical =>
          switch variant {
          | BoxV => "left-3 right-3"
          | EdgeV | SmoothV => "inset-x-0"
          | LineV => "left-1 right-1"
          }
        }}`}
      style={bandStyle}>
      {switch variant {
      | SmoothV =>
        // One silhouette per contiguous band: thickness varies smoothly along
        // the span instead of stepping per segment.
        <span
          ariaHidden=true
          className="absolute inset-0 bg-cyan-500/35 dark:bg-cyan-400/30"
          style={ReactDOM.Style.make(
            ~clipPath=getSmoothBandClipPath(band, orientation, placement),
            (),
          )}
        />
      | BoxV | EdgeV | LineV =>
        band.segments
      ->Array.mapWithIndex((segment, index) => {
        let segmentOffset = (segment.start -. band.start) /. (band.end -. band.start) *. 100.0
        let segmentShare = (segment.end -. segment.start) /. (band.end -. band.start) *. 100.0
        // Intensity/thickness reflects the peak available-court total during the
        // segment (from the per-hour rollup), not the number of records.
        let slotCount =
          TimeWindow.summarizeCourtAvailability(
            ~fromHour=segment.start->Float.toInt,
            ~toHour=segment.end->Float.toInt,
            segment.slots->Array.map(s => s.court),
          ).courtCount
        let courtsPhrase = Lingui.UtilString.plural(
          slotCount,
          {
            one: ts`${slotCount->Int.toString} court`,
            other: ts`${slotCount->Int.toString} courts`,
          },
        )
        let thickness = getCourtLineThickness(slotCount)->Int.toString ++ "px"
        let opacity =
          Js.Math.min_float(1.0, 0.55 +. slotCount->Float.fromInt *. 0.075)->Float.toString
        let isFirst = index === 0
        let isLast = index === band.segments->Array.length - 1
        // Box and Edge share the same full-segment geometry (4px outer corners);
        // only the fill vs. border and opacity differ. Line is a thin centered bar.
        let radiusH =
          corner(isFirst, "4px") ++
          " " ++
          corner(isLast, "4px") ++
          " " ++
          corner(isLast, "4px") ++
          " " ++
          corner(isFirst, "4px")
        let radiusV =
          corner(isFirst, "4px") ++
          " " ++
          corner(isFirst, "4px") ++
          " " ++
          corner(isLast, "4px") ++
          " " ++
          corner(isLast, "4px")
        let segStyle = switch (variant, orientation) {
        // Unreachable: SmoothV renders the single-silhouette branch, never
        // per-segment spans.
        | (SmoothV, _) => ReactDOM.Style.make()
        | (BoxV, Horizontal) =>
          ReactDOM.Style.make(
            ~left=segmentOffset->Float.toString ++ "%",
            ~width=segmentShare->Float.toString ++ "%",
            ~top="0",
            ~bottom="0",
            ~opacity,
            ~borderRadius=radiusH,
            (),
          )
        | (EdgeV, Horizontal) =>
          ReactDOM.Style.make(
            ~left=segmentOffset->Float.toString ++ "%",
            ~width=segmentShare->Float.toString ++ "%",
            ~top="0",
            ~bottom="0",
            ~borderRadius=radiusH,
            (),
          )
        | (BoxV, Vertical) =>
          ReactDOM.Style.make(
            ~top=segmentOffset->Float.toString ++ "%",
            ~height=segmentShare->Float.toString ++ "%",
            ~left="0",
            ~right="0",
            ~opacity,
            ~borderRadius=radiusV,
            (),
          )
        | (EdgeV, Vertical) =>
          ReactDOM.Style.make(
            ~top=segmentOffset->Float.toString ++ "%",
            ~height=segmentShare->Float.toString ++ "%",
            ~left="0",
            ~right="0",
            ~borderRadius=radiusV,
            (),
          )
        | (LineV, Horizontal) =>
          ReactDOM.Style.make(
            ~left=segmentOffset->Float.toString ++ "%",
            ~width=segmentShare->Float.toString ++ "%",
            ~height=thickness,
            ~top="50%",
            ~transform="translateY(-50%)",
            ~borderRadius=corner(isFirst, "999px") ++
            " " ++
            corner(isLast, "999px") ++
            " " ++
            corner(isLast, "999px") ++
            " " ++
            corner(isFirst, "999px"),
            (),
          )
        | (LineV, Vertical) =>
          ReactDOM.Style.make(
            ~top=segmentOffset->Float.toString ++ "%",
            ~height=segmentShare->Float.toString ++ "%",
            ~width=thickness,
            ~left="50%",
            ~transform="translateX(-50%)",
            ~borderRadius=corner(isFirst, "999px") ++
            " " ++
            corner(isFirst, "999px") ++
            " " ++
            corner(isLast, "999px") ++
            " " ++
            corner(isLast, "999px"),
            (),
          )
        }
        <span
          key={segment.key}
          title={courtsPhrase ++ " · " ++ fmt(segment.start) ++ "–" ++ fmt(segment.end)}
          className={`absolute ${switch variant {
            | BoxV => "border border-cyan-500 bg-cyan-200/90 dark:border-cyan-500 dark:bg-cyan-900/80"
            | EdgeV => "border-2 border-cyan-500 bg-transparent dark:border-cyan-400"
            | LineV | SmoothV => "bg-cyan-500/35 dark:bg-cyan-400/30"
            }}`}
          style={segStyle}
        />
      })
        ->React.array
      }}
    </div>
  })
  ->React.array
}

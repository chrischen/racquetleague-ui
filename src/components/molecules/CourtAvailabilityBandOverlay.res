%%raw("import { t, plural } from '@lingui/macro'")

// Absolute-positioned court-availability overlay for a time track. Each band of
// uninterrupted availability renders as one continuous outline; internal
// dividers mark where the active court set changes, and every proportional
// segment shows its exact court count and stays independently selectable.
//
// Shared by the horizontal inline picker/grid track and the vertical schedule
// column — hence the `orientation` prop. Depends only on the UI-free TimeWindow
// model, so the picker can render it without a module cycle.

let ts = Lingui.UtilString.t

type orientation = Horizontal | Vertical

@react.component
let make = (
  ~bands: array<TimeWindow.courtAvailabilityBand>,
  ~hourMin: int,
  ~hourMax: int,
  ~orientation: orientation=Horizontal,
  ~onUseSegment: option<TimeWindow.courtSlotGroup => unit>=?,
) => {
  let intl = ReactIntl.useIntl()
  let fmt = h => TimeWindow.hourLabelIntl(intl, h)
  let hourRange = (hourMax - hourMin)->Float.fromInt

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
      role="group"
      onClick={e => e->ReactEvent.Mouse.stopPropagation}
      className={`absolute z-[15] overflow-hidden rounded border border-cyan-600/80 bg-transparent dark:bg-transparent ${switch orientation {
        | Horizontal => "top-1 h-3.5 min-w-5 flex"
        | Vertical => "left-1 right-1 flex flex-col"
        }}`}
      style={bandStyle}>
      {band.segments
      ->Array.mapWithIndex((segment, index) => {
        let segmentShare = (segment.end -. segment.start) /. (band.end -. band.start) *. 100.0
        let canUse =
          onUseSegment->Option.isSome && segment.end -. segment.start <= TimeWindow.maxMatchableCourtHours
        let slotCount = segment.slots->Array.length
        let courtsPhrase = Lingui.UtilString.plural(
          slotCount,
          {
            one: ts`${slotCount->Int.toString} court`,
            other: ts`${slotCount->Int.toString} courts`,
          },
        )
        let dividerClass = switch orientation {
        | Horizontal => index > 0 ? "border-l border-cyan-600/55 dark:border-cyan-400/45" : ""
        | Vertical => index > 0 ? "border-t border-cyan-600/55 dark:border-cyan-400/45 flex-col" : "flex-col"
        }
        let segStyle = switch orientation {
        | Horizontal => ReactDOM.Style.make(~width=segmentShare->Float.toString ++ "%", ())
        | Vertical => ReactDOM.Style.make(~height=segmentShare->Float.toString ++ "%", ())
        }
        <button
          key={segment.key}
          type_="button"
          disabled={!canUse}
          onClick={e => {
            e->ReactEvent.Mouse.stopPropagation
            if canUse {
              switch onUseSegment {
              | Some(cb) => cb(segment)
              | None => ()
              }
            }
          }}
          title={courtsPhrase ++
          " · " ++
          fmt(segment.start) ++
          "–" ++
          fmt(segment.end) ++ (canUse ? " · " ++ ts`Match my time` : "")}
          className={`relative min-h-0 min-w-0 flex items-center justify-center px-0.5 text-cyan-800 dark:text-cyan-300 ${dividerClass} ${canUse
              ? "cursor-pointer hover:bg-cyan-100/60 dark:hover:bg-cyan-900/25 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-cyan-500"
              : "cursor-default"}`}
          style={segStyle}>
          {switch orientation {
          | Vertical => <Lucide.MapPin size=9 className="flex-shrink-0" />
          | Horizontal => React.null
          }}
          <span
            className="max-w-full truncate font-mono text-[8px] font-bold leading-none pointer-events-none">
            {switch orientation {
            | Vertical => (slotCount->Int.toString ++ " " ++ ts`open`)->React.string
            | Horizontal => slotCount->Int.toString->React.string
            }}
          </span>
        </button>
      })
      ->React.array}
    </div>
  })
  ->React.array
}

%%raw("import { t } from '@lingui/macro'")

// Density curve of the confirmed players' DUPR levels across the 2.0–8.0
// scale, shaded by the usual skill bands. Ported from the Magic Patterns event
// panel; the caller decides whether there are enough ratings to show it.

let chartWidth = 320.
let chartHeight = 72.
let baseline = 68.
let curveHeight = 54.
// 0.05 DUPR per sample, fine enough to draw a single player's narrow spike.
let sampleCount = 121
let minLevel = 2.
let maxLevel = 8.

// Kernel width in DUPR points, from the spread of the ratings: one player, or
// several at the same level, draws a narrow spike; a court of mixed levels a
// smoother curve. Silverman's rule of thumb, clamped so neither extreme
// degenerates into a hairline or a featureless bell.
let minBandwidth = 0.12
let maxBandwidth = 0.35

let bandwidthFor = (duprs: array<float>): float => {
  let n = duprs->Array.length
  if n <= 1 {
    minBandwidth
  } else {
    let nf = Float.fromInt(n)
    let mean = duprs->Array.reduce(0., (a, b) => a +. b) /. nf
    let variance = duprs->Array.reduce(0., (acc, d) => acc +. (d -. mean) *. (d -. mean)) /. nf
    let h = 0.9 *. Math.sqrt(variance) *. Math.pow(nf, ~exp=-0.2)
    Math.max(minBandwidth, Math.min(maxBandwidth, h))
  }
}

type band = {label: string, lo: float, hi: float, color: string}

let bands = (): array<band> => {
  let ts = Lingui.UtilString.t
  [
    {label: ts`Beginner`, lo: 2., hi: 3., color: "#60a5fa"},
    {label: ts`Intermediate`, lo: 3., hi: 4., color: "#2dd4bf"},
    {label: ts`Advanced`, lo: 4., hi: 5., color: "#a3e635"},
    {label: ts`Semi-Pro`, lo: 5., hi: 6., color: "#fbbf24"},
    {label: ts`Pro`, lo: 6., hi: 8., color: "#c084fc"},
  ]
}

let axisLevels = [2., 3., 4., 5., 6., 7., 8.]

let xFor = level => (level -. minLevel) /. (maxLevel -. minLevel) *. chartWidth

let f = Float.toString

// Smoothed path through the density samples: each segment bends toward its
// sample and ends at the midpoint to the next, so the curve never overshoots.
let curvePathOf = (points: array<(float, float)>): string =>
  points->Array.reduceWithIndex("", (path, (x, y), i) =>
    if i == 0 {
      `M ${f(x)} ${f(y)}`
    } else if i == points->Array.length - 1 {
      let (px, py) = points->Array.getUnsafe(i - 1)
      `${path} Q ${f(px)} ${f(py)}, ${f(x)} ${f(y)}`
    } else {
      let (nx, ny) = points->Array.getUnsafe(i + 1)
      `${path} Q ${f(x)} ${f(y)}, ${f((x +. nx) /. 2.)} ${f((y +. ny) /. 2.)}`
    }
  )

@react.component
let make = (
  ~duprs: array<float>,
  // The "top court" figure the section prints under the chart (the top-six
  // average), so the accessible label matches what sighted users read.
  ~topCourtDupr: string,
) => {
  let ts = Lingui.UtilString.t
  let bandwidth = bandwidthFor(duprs)
  let samples = Belt.Array.makeBy(sampleCount, i => {
    let level =
      minLevel +. Float.fromInt(i) /. Float.fromInt(sampleCount - 1) *. (maxLevel -. minLevel)
    duprs->Array.reduce(0., (total, skill) => {
      let distance = (level -. skill) /. bandwidth
      total +. Math.exp(-0.5 *. distance *. distance)
    })
  })
  let peak = samples->Array.reduce(1., (acc, d) => Math.max(acc, d))
  let points =
    samples->Array.mapWithIndex((density, i) => (
      Float.fromInt(i) /. Float.fromInt(sampleCount - 1) *. chartWidth,
      baseline -. density /. peak *. curveHeight,
    ))
  let curvePath = curvePathOf(points)
  let areaPath = `${curvePath} L ${f(chartWidth)} ${f(baseline)} L 0 ${f(baseline)} Z`
  let bands = bands()

  <div>
    <div
      className="relative h-[72px] w-full overflow-hidden rounded-md bg-gray-50 dark:bg-[#1e1f23]">
      <svg
        viewBox={`0 0 ${f(chartWidth)} ${f(chartHeight)}`}
        preserveAspectRatio="none"
        className="h-full w-full"
        role="img"
        ariaLabel={ts`Player level distribution from DUPR 2.0 to 8.0. Top court DUPR is ${topCourtDupr}.`}>
        {bands
        ->Array.map(band =>
          <rect
            key=band.label
            x={f(xFor(band.lo))}
            y="0"
            width={f(xFor(band.hi) -. xFor(band.lo))}
            height={f(baseline)}
            fill=band.color
            fillOpacity="0.13"
          />
        )
        ->React.array}
        {axisLevels
        ->Array.map(level =>
          <line
            key={f(level)}
            x1={f(xFor(level))}
            y1="0"
            x2={f(xFor(level))}
            y2={f(baseline)}
            stroke="currentColor"
            strokeWidth="0.5"
            className="text-gray-200 dark:text-[#353640]"
          />
        )
        ->React.array}
        <path d=areaPath fill="currentColor" className="text-[#bdf25d] opacity-25" />
        <path
          d=curvePath
          fill="none"
          stroke="currentColor"
          strokeWidth="2.5"
          vectorEffect="non-scaling-stroke"
          className="text-[#75a719] dark:text-[#bdf25d]"
        />
        <line
          x1="0"
          y1={f(baseline)}
          x2={f(chartWidth)}
          y2={f(baseline)}
          stroke="currentColor"
          strokeWidth="1"
          className="text-gray-300 dark:text-[#3a3b40]"
        />
      </svg>
    </div>
    <div
      className="mt-1 flex justify-between text-[10px] text-gray-500 dark:text-gray-400"
      ariaHidden=true>
      {axisLevels
      ->Array.map(level =>
        <span key={f(level)}> {level->Float.toFixed(~digits=1)->React.string} </span>
      )
      ->React.array}
    </div>
    <div className="mt-2 flex flex-wrap gap-x-3 gap-y-1.5" ariaLabel={ts`DUPR level key`}>
      {bands
      ->Array.map(band =>
        <span
          key=band.label
          className="inline-flex items-center gap-1.5 text-[10px] text-gray-600 dark:text-gray-300">
          <span
            className="h-2 w-2 rounded-sm"
            style={ReactDOM.Style.make(~backgroundColor=band.color, ())}
            ariaHidden=true
          />
          <span> {band.label->React.string} </span>
        </span>
      )
      ->React.array}
    </div>
  </div>
}

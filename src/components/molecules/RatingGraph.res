%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
// Type definitions
type ratingDataPoint = {
  date: string,
  rating: float,
  uncertainty: float,
  upperBound: float,
  lowerBound: float,
}

// Recharts bindings
module ResponsiveContainer = {
  @module("recharts") @react.component
  external make: (~width: string=?, ~height: string=?, ~children: React.element) => React.element =
    "ResponsiveContainer"
}

module ComposedChart = {
  type margin = {
    top: int,
    right: int,
    left: int,
    bottom: int,
  }

  @module("recharts") @react.component
  external make: (
    ~data: array<ratingDataPoint>,
    ~margin: margin=?,
    ~children: React.element,
  ) => React.element = "ComposedChart"
}

module CartesianGrid = {
  @module("recharts") @react.component
  external make: (
    ~strokeDasharray: string=?,
    ~stroke: string=?,
    ~strokeOpacity: float=?,
  ) => React.element = "CartesianGrid"
}

module XAxis = {
  type style = {fontSize: string}

  @module("recharts") @react.component
  external make: (
    ~dataKey: string,
    ~stroke: string=?,
    ~style: style=?,
    ~tickLine: bool=?,
  ) => React.element = "XAxis"
}

module YAxis = {
  type style = {fontSize: string}

  @module("recharts") @react.component
  external make: (
    ~stroke: string=?,
    ~style: style=?,
    ~tickLine: bool=?,
    ~domain: array<float>=?,
    ~tickFormatter: float => string=?,
  ) => React.element = "YAxis"
}

module Tooltip = {
  @module("recharts") @react.component
  external make: (~content: React.element) => React.element = "Tooltip"
}

// Used for the uncertainty band: Recharts draws an Area whose value is a
// [low, high] pair as a range.
module Area = {
  @module("recharts") @react.component
  external make: (
    ~\"type": string,
    ~dataKey: ratingDataPoint => array<float>,
    ~stroke: string=?,
    ~fill: string=?,
    ~fillOpacity: float=?,
  ) => React.element = "Area"
}

module Line = {
  type dot = {
    fill: string,
    strokeWidth: int,
    r: int,
  }

  type activeDot = {r: int}

  @module("recharts") @react.component
  external make: (
    ~\"type": string,
    ~dataKey: string,
    ~stroke: string,
    ~strokeWidth: int=?,
    ~dot: dot=?,
    ~activeDot: activeDot=?,
  ) => React.element = "Line"
}

// The Y axis range: the data's range plus a tenth of it either side, and at
// least minYSpan tall so a nearly flat history isn't magnified into noise.
let minYSpan = 4.0
let yDomain = (data: array<ratingDataPoint>): (float, float) => {
  let values = data->Array.flatMap(p => [p.rating, p.lowerBound, p.upperBound])
  switch values->Array.get(0) {
  | None => (0.0, minYSpan)
  | Some(first) =>
    let lo = values->Array.reduce(first, Math.min)
    let hi = values->Array.reduce(first, Math.max)
    let span = hi -. lo
    let pad = Math.max(span *. 0.1, (minYSpan -. span) /. 2.0)
    (lo -. pad, hi +. pad)
  }
}

// Custom Tooltip Component
module CustomTooltip = {
  type payloadItem = {payload: ratingDataPoint}

  @react.component
  let make = (~active: option<bool>, ~payload: option<array<payloadItem>>) => {
    switch (active, payload) {
    | (Some(true), Some(payloadData)) =>
      payloadData
      ->Array.get(0)
      ->Option.map(p => {
        let data = p.payload
        <div
          className="bg-white dark:bg-[#1e1f23] px-4 py-3 rounded-lg shadow-lg border border-gray-200 dark:border-[#2a2b30]">
          <p className="text-sm font-medium text-gray-900 dark:text-gray-100 mb-1">
            {data.date->React.string}
          </p>
          <p className="text-sm text-gray-700 dark:text-gray-300">
            {t`Rating: `}
            <span className="font-semibold text-blue-600 dark:text-blue-400">
              {data.rating->Float.toString->React.string}
            </span>
          </p>
          <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
            {`Uncertainty: ±${data.uncertainty->Float.toString}`->React.string}
          </p>
        </div>
      })
      ->Option.getOr(React.null)
    | _ => React.null
    }
  }
}

@react.component
let make = (~data: array<ratingDataPoint>) => {
  let (yMin, yMax) = yDomain(data)
  <div className="w-full h-80">
    <ResponsiveContainer width="100%" height="100%">
      <ComposedChart
        data
        margin={
          top: 10,
          right: 10,
          left: 0,
          bottom: 0,
        }>
        <defs>
          <linearGradient id="uncertaintyGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#3B82F6" stopOpacity="0.15" />
            <stop offset="95%" stopColor="#3B82F6" stopOpacity="0.05" />
          </linearGradient>
        </defs>
        // Mid grey at low opacity reads as a faint grid on light and dark cards
        <CartesianGrid strokeDasharray="3 3" stroke="#9CA3AF" strokeOpacity={0.3} />
        <XAxis dataKey="date" stroke="#9CA3AF" style={{fontSize: "12px"}} tickLine={false} />
        <YAxis
          stroke="#9CA3AF"
          style={{fontSize: "12px"}}
          tickLine={false}
          domain={[yMin, yMax]}
          tickFormatter={value => value->Float.toFixed(~digits=1)}
        />
        <Tooltip content={<CustomTooltip active=None payload=None />} />
        // Uncertainty band, drawn as a range rather than masked with the
        // card's colour, so it works on light and dark cards alike
        <Area
          \"type"="monotone"
          dataKey={p => [p.lowerBound, p.upperBound]}
          stroke="none"
          fill="url(#uncertaintyGradient)"
          fillOpacity={1.0}
        />
        // Rating line
        <Line
          \"type"="monotone"
          dataKey="rating"
          stroke="#3B82F6"
          strokeWidth={3}
          dot={{
            fill: "#3B82F6",
            strokeWidth: 2,
            r: 4,
          }}
          activeDot={{r: 6}}
        />
      </ComposedChart>
    </ResponsiveContainer>
  </div>
}

@genType
let default = make

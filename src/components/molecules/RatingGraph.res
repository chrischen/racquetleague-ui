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
  external make: (~strokeDasharray: string=?, ~stroke: string=?) => React.element = "CartesianGrid"
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
    ~domain: array<string>=?,
    ~tickFormatter: float => string=?,
  ) => React.element = "YAxis"
}

module Tooltip = {
  @module("recharts") @react.component
  external make: (~content: React.element) => React.element = "Tooltip"
}

module Area = {
  @module("recharts") @react.component
  external make: (
    ~\"type": string,
    ~dataKey: string,
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
        <div className="bg-white px-4 py-3 rounded-lg shadow-lg border border-gray-200">
          <p className="text-sm font-medium text-gray-900 mb-1"> {data.date->React.string} </p>
          <p className="text-sm text-gray-700">
            {"Rating: "->React.string}
            <span className="font-semibold text-blue-600">
              {data.rating->Float.toString->React.string}
            </span>
          </p>
          <p className="text-xs text-gray-500 mt-1">
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
        <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
        <XAxis dataKey="date" stroke="#9CA3AF" style={{fontSize: "12px"}} tickLine={false} />
        <YAxis
          stroke="#9CA3AF"
          style={{fontSize: "12px"}}
          tickLine={false}
          domain={["dataMin - 50", "dataMax + 50"]}
          tickFormatter={value => value->Float.toFixed(~digits=1)}
        />
        <Tooltip content={<CustomTooltip active=None payload=None />} />
        // Uncertainty band
        <Area
          \"type"="monotone"
          dataKey="upperBound"
          stroke="none"
          fill="url(#uncertaintyGradient)"
          fillOpacity={1.0}
        />
        <Area
          \"type"="monotone" dataKey="lowerBound" stroke="none" fill="#ffffff" fillOpacity={1.0}
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

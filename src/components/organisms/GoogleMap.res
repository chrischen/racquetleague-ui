module APIProvider = {
  @react.component @module("@vis.gl/react-google-maps")
  external make: (~apiKey: string, ~libraries: array<string>=?, ~children: React.element) => React.element = "APIProvider"
}
module Map = {
  type coords = {
    lat: float,
    lng: float,
  }
  @react.component @module("@vis.gl/react-google-maps")
  external make: (
    ~mapId: string,
    ~defaultZoom: int=?,
    ~zoom: int=?,
    ~defaultCenter: coords=?,
    ~center: coords=?,
    ~children: React.element=?,
  ) => React.element = "Map"
}

module Marker = {
  type markerRef
  @react.component @module("@vis.gl/react-google-maps")
  external make: (~markerRef: markerRef=?, ~position: Map.coords=?) => React.element = "Marker"
}

module AdvancedMarker = {
  type markerRef;
  type clickTarget = {
    position: Map.coords
  }
  type clickEvent = {
    target: clickTarget,
    url: string
  };
  @react.component @module("@vis.gl/react-google-maps")
  external make: (
    ~key: Map.coords=?,
    ~title: string=?,
    ~className: string=?,
    ~ref: markerRef=?,
    ~position: Map.coords=?,
    ~children: React.element=?,
    ~onClick: (clickEvent => unit)=?,
    ~gmpClickable: bool=?,
  ) => React.element = "AdvancedMarker"
}
module Pin = {
  @react.component @module("@vis.gl/react-google-maps")
  external make: (
    ~background: string=?,
    ~glyphColor: string=?,
    ~borderColor: string=?,
    ~scale: float=?,

  ) => React.element = "Pin"
}

type location = RelaySchemaAssets_graphql.input_LocationInput

let tokyoDefault: location = {lat: 35.658581, lng: 139.745438}

type geolocationCoords = {latitude: float, longitude: float}
type geolocationPosition = {coords: geolocationCoords}
type geolocationError

@val @scope(("navigator", "geolocation"))
external getCurrentPosition: (geolocationPosition => unit, geolocationError => unit) => unit =
  "getCurrentPosition"

// Check whether we're in a browser environment (undefined in SSR/Node)
@val external window_: Js.Nullable.t<{..}> = "window"

let use = (): location => {
  let (location, setLocation) = React.useState(() => tokyoDefault)

  React.useEffect0(() => {
    if window_->Js.Nullable.toOption->Option.isSome {
      getCurrentPosition(
        pos =>
          setLocation(_ => {
            lat: pos.coords.latitude,
            lng: pos.coords.longitude,
          }),
        _err => (),
      )
    }
    None
  })

  location
}

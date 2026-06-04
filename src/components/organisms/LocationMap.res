module Fragment = %relay(`
  fragment LocationMap_location on Location {
    id
    coords {
      lng
      lat
    }
    address
  }
`)
@react.component
let make = (~location) => {
  // let navigate = Router.useNavigate()
  let {coords} = Fragment.use(location)
  {coords
  ->Option.map(coords => {
    <GoogleMap.Map
      mapId="eventsListMap" defaultZoom=12 defaultCenter={lat: coords.lat, lng: coords.lng}>
      <GoogleMap.AdvancedMarker position={(coords :> GoogleMap.Map.coords)} />
    </GoogleMap.Map>
  })
  ->Option.getOr(React.null)}
}

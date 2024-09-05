module Fragment = %relay(`
  fragment GMap_location on Location {
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
  <GoogleMap.APIProvider apiKey="AIzaSyBFLsnHmBaptaYoFhkXI6uL6peX579N5UY">
    {coords
    ->Option.map(coords => {
      <GoogleMap.Map
        mapId="eventsListMap" defaultZoom=12 defaultCenter={lat: coords.lat, lng: coords.lng}>
        <GoogleMap.AdvancedMarker position={(coords :> GoogleMap.Map.coords)} />
      </GoogleMap.Map>
    })
    ->Option.getOr(React.null)}
  </GoogleMap.APIProvider>
}

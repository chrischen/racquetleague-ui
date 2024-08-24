module Fragment = %relay(`
  fragment PinMap_eventConnection on EventConnection {
    edges {
      node {
        id
        startDate
        location {
          id
          coords {
            lng
            lat
          }
          address
        }
      }
    }
  }
`)
@react.component
let make = (~connection: RescriptRelay.fragmentRefs<[#PinMap_eventConnection]>, ~onLocationClick) => {
  // let navigate = Router.useNavigate()
  let connection = Fragment.use(connection)
  let locations =
    connection.edges
    ->Option.getOr([])
    ->Array.map(Option.flatMap(_, edge => edge.node->Option.flatMap(event => event.location->Option.map(location => (event.id, location)))))

  <GoogleMap.APIProvider apiKey="AIzaSyBFLsnHmBaptaYoFhkXI6uL6peX579N5UY">
    <GoogleMap.Map mapId="eventsListMap" defaultZoom=12 defaultCenter={lat: 35.6495, lng: 139.7417}>
      {locations
      ->Array.mapWithIndex((location, i) => {
        location
        ->Option.flatMap(((_id, location)) =>
          location.coords->Option.map(
            coords => {
              <GoogleMap.AdvancedMarker
                key={coords.lat->Float.toString ++ "|" ++ coords.lng->Float.toString ++ i->Int.toString}
                position={(coords :> GoogleMap.Map.coords)}
                onClick={_ => {
                  onLocationClick(location);
                  // navigate("/events/" ++ id, None)
                }}
              />
            },
          )
        )
        ->Option.getOr(React.null)
      })
      ->React.array}
    </GoogleMap.Map>
  </GoogleMap.APIProvider>
}

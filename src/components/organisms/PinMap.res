module Fragment = %relay(`
  fragment PinMap_eventConnection on EventConnection {
    edges {
      node {
        id
        startDate
        location {
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
let make = (~connection: RescriptRelay.fragmentRefs<[#PinMap_eventConnection]>) => {
  let navigate = Router.useNavigate()
  let connection = Fragment.use(connection)
  let locations =
    connection.edges
    ->Option.getOr([])
    ->Array.map(Option.flatMap(_, edge => edge.node->Option.flatMap(event => event.location->Option.map(location => (event.id, location)))))

  <GoogleMap.APIProvider apiKey="AIzaSyBFLsnHmBaptaYoFhkXI6uL6peX579N5UY">
    <GoogleMap.Map mapId="eventsListMap" defaultZoom=12 defaultCenter={lat: 35.6895, lng: 139.6917}>
      {locations
      ->Array.map(location => {
        location
        ->Option.flatMap(((id, location)) =>
          location.coords->Option.map(
            coords => {
              <GoogleMap.AdvancedMarker
                key={coords.lat->Float.toString ++ "|" ++ coords.lng->Float.toString}
                position={(coords :> GoogleMap.Map.coords)}
                onClick={e => {
                  navigate("/events/" ++ id, None)
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

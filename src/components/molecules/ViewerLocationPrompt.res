// Prompts the browser for geolocation (the same way the availability feature
// does, via UseUserLocation) and persists the viewer's home coordinates.
//
// Mount this only when the logged-in viewer has no stored coords yet: it
// renders nothing, saves once the prompt is granted, and then unmounts as the
// store update flows back into the page query. A denied/unsupported prompt
// resolves to the fallback location with `granted: false`, which we never
// persist.
module Mutation = %relay(`
  mutation ViewerLocationPromptMutation($input: UpdateViewerLocationInput!) {
    updateViewerLocation(input: $input) {
      viewer {
        id
        coords {
          lat
          lng
        }
      }
      errors {
        message
      }
    }
  }
`)

@react.component
let make = (~onSaved: option<unit => unit>=?) => {
  let (commit, _isMutating) = Mutation.use()
  let geoStatus = UseUserLocation.useStatus()
  let savedRef = React.useRef(false)

  React.useEffect1(() => {
    switch geoStatus {
    | UseUserLocation.Resolved({location, granted: true}) if !savedRef.current =>
      savedRef.current = true
      commit(~variables={input: {lat: location.lat, lng: location.lng}}, ~onCompleted=(
        _res,
        _err,
      ) => onSaved->Option.forEach(f => f()))->RescriptRelay.Disposable.ignore
    | _ => ()
    }
    None
  }, [geoStatus])

  React.null
}

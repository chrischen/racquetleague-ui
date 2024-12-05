%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

module AutocompleteLocationMutation = %relay(`
 mutation AutocompleteLocationFormMutation(
    $input: AutocompleteLocationInput!
  ) {
    autocompleteLocation(input: $input) {
      location {
        __typename
        id
        name
        links
        address
      }
    }
  }
`)

@react.component
let make = (~onSelected: string => unit) => {
  let (commitMutationCreate, _) = AutocompleteLocationMutation.use()
  // let ts = Lingui.UtilString.t

  let onSelect = (place: GoogleMapsAutocomplete.place) => {
    switch (place.name, place.formatted_address, place.geometry, place.place_id) {
    | (Some(name), Some(address), Some(geometry), Some(place_id)) =>
      commitMutationCreate(
        ~variables={
          input: {
            name,
            formattedAddress: address,
            lat: geometry.location.lat(),
            lng: geometry.location.lng(),
            mapsId: place_id,
            // plusCode: place.plus_code,
            // details: ?data.details,
          },
        },
        ~onCompleted=(response, _errors) => {
          response.autocompleteLocation.location
          ->Option.map(location => onSelected(location.id))
          ->ignore
          // reset()
          // onClose()
        },
      )->RescriptRelay.Disposable.ignore
    | _ => ()
    }
  }
  <GoogleMapsAutocomplete
    apiKey="AIzaSyCZWn4QS-HcYV_KDt9dOSy-EiJ9s3m8WIk"
    onPlaceSelected=onSelect
    options={{
      types: ["establishment"],
      fields: ["place_id", "geometry.location", "name", "formatted_address", "plus_code"],
    }}
  />
}

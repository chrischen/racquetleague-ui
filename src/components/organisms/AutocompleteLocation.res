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

type autocompleteLocationInput
let mapToAutocompleteLocationInput = (resp: GoogleMapsAutocomplete.place): unit => {
  ()
}
@react.component
let make = (~locations) => {
  let navigate = Router.useNavigate()
  let (commitMutationCreate, _) = AutocompleteLocationMutation.use()
  open Lingui.Util
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
          ->Option.map(location => navigate(location.id, None))
          ->ignore
          // reset()
          // onClose()
        },
      )->RescriptRelay.Disposable.ignore
    | _ => ()
    }
  }
  <WaitForMessages>
    {() =>
      <Grid>
        <FormSection
          title={t`event location`}
          description={t`choose the location where this event will be held.`}>
          <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8">
            <GoogleMapsAutocomplete
              apiKey="AIzaSyCZWn4QS-HcYV_KDt9dOSy-EiJ9s3m8WIk"
              onPlaceSelected=onSelect
              options={{
                types: ["establishment"],
                fields: ["place_id", "geometry.location", "name", "formatted_address", "plus_code"],
              }}
            />
          </div>
        </FormSection>
        <FramerMotion.AnimatePresence mode="wait">
          <Router.Outlet />
        </FramerMotion.AnimatePresence>
      </Grid>}
  </WaitForMessages>
}

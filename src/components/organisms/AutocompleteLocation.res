%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

// DOM bindings
@val @scope("document")
external createElement: string => Dom.element = "createElement"

// Google Maps Places API bindings
module GooglePlaces = {
  type location = {
    lat: unit => float,
    lng: unit => float,
  }

  type geometry = {location: location}

  type placeResult = {
    name: option<string>,
    @as("formatted_address") formattedAddress: option<string>,
    @as("place_id") placeId: option<string>,
    geometry: option<geometry>,
  }

  type placesServiceStatus

  @val @scope(("window", "google", "maps", "places", "PlacesServiceStatus"))
  external ok: placesServiceStatus = "OK"

  type textSearchRequest = {
    query: string,
    fields: array<string>,
  }

  type placesService

  @new @scope(("window", "google", "maps", "places"))
  external createPlacesService: Dom.element => placesService = "PlacesService"

  @send
  external textSearch: (
    placesService,
    textSearchRequest,
    (array<placeResult>, placesServiceStatus) => unit,
  ) => unit = "textSearch"
}

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
let make = (
  ~onSelected: string => unit,
  ~error: option<string>=?,
  ~autoSearchAddress: option<string>=?,
) => {
  let (commitMutationCreate, _) = AutocompleteLocationMutation.use()

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
          },
        },
        ~onCompleted=(response, _errors) => {
          response.autocompleteLocation.location
          ->Option.map(location => onSelected(location.id))
          ->ignore
        },
      )->RescriptRelay.Disposable.ignore
    | _ => ()
    }
  }

  // Effect to handle auto-search when address is provided
  React.useEffect(() => {
    switch autoSearchAddress {
    | Some(address) => {
        // Create a dummy div element for the PlacesService
        let dummyDiv = createElement("div")
        let service = GooglePlaces.createPlacesService(dummyDiv)

        let request: GooglePlaces.textSearchRequest = {
          query: address,
          fields: ["place_id", "geometry", "name", "formatted_address"],
        }

        GooglePlaces.textSearch(service, request, (results, status) => {
          if status == GooglePlaces.ok {
            results
            ->Array.get(0)
            ->Option.map(
              result => {
                // Convert geometry type from GooglePlaces to GoogleMapsAutocomplete
                let geometry = result.geometry->Option.map(
                  g => {
                    let loc: GoogleMapsAutocomplete.location = {
                      lat: g.location.lat,
                      lng: g.location.lng,
                    }
                    let geom: GoogleMapsAutocomplete.geometry = {location: loc}
                    geom
                  },
                )

                // Convert to the place type expected by onSelect (uses snake_case)
                let place: GoogleMapsAutocomplete.place = {
                  name: ?result.name,
                  formatted_address: ?result.formattedAddress,
                  place_id: ?result.placeId,
                  ?geometry,
                }
                onSelect(place)
              },
            )
            ->ignore
          }
        })
      }
    | None => ()
    }
    None
  }, [autoSearchAddress])

  <div>
    <div className="relative">
      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
        <Lucide.MapPin className="h-5 w-5 text-gray-400" />
      </div>
      <GoogleMapsAutocomplete
        apiKey="AIzaSyCZWn4QS-HcYV_KDt9dOSy-EiJ9s3m8WIk"
        onPlaceSelected=onSelect
        options={{
          types: ["establishment"],
          fields: ["place_id", "geometry.location", "name", "formatted_address", "plus_code"],
        }}
        className={Util.cx([
          "block w-full pl-10 pr-4 py-3 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors",
          error->Option.isSome ? "border-red-300" : "border-gray-300",
        ])}
        placeholder="Search for a location..."
      />
    </div>
    {error
    ->Option.map(errorMessage =>
      <p className="mt-1 text-sm text-red-600"> {errorMessage->React.string} </p>
    )
    ->Option.getOr(React.null)}
  </div>
}

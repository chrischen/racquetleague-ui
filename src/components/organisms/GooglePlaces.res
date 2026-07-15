// Google Maps Places API bindings (extracted from AutocompleteLocation so both
// the location picker and the bulk "Create events" resolver can share them).

@val @scope("document")
external createElement: string => Dom.element = "createElement"

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

// Headless: resolve an address string to the top place result, wrapping the
// callback-based `textSearch` in a promise. Resolves to None if the SDK isn't
// available, the request errors, or there are no results.
let textSearchTop = (address: string): promise<option<placeResult>> =>
  Promise.make((resolve, _reject) => {
    let service = createPlacesService(createElement("div"))
    let request: textSearchRequest = {
      query: address,
      fields: ["place_id", "geometry", "name", "formatted_address"],
    }
    textSearch(service, request, (results, status) => {
      if status == ok {
        resolve(results->Array.get(0))
      } else {
        resolve(None)
      }
    })
  })

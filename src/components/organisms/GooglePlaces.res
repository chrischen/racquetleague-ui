// Google Maps Places API (New) bindings, shared by the location picker and the
// bulk "Create events" resolver.
//
// The Maps JS script is loaded once by the APIProvider in wrapper.tsx with the
// "places" library. Components should gate calls on
// RGMHooks.useMapsLibrary("places") being non-null; the headless helpers below
// simply fail soft if the SDK isn't there yet.

// --- LatLng ---
type latLng
@send external lat: latLng => float = "lat"
@send external lng: latLng => float = "lng"

type latLngLiteral = {lat: float, lng: float}
type circle = {center: latLngLiteral, radius: float}

// --- Place ---
// Fields are `null` when Google has no value and `undefined` when not requested.
type place = {
  id: string,
  displayName: Nullable.t<string>,
  formattedAddress: Nullable.t<string>,
  location: Nullable.t<latLng>,
}

type fetchFieldsRequest = {fields: array<string>}
type fetchFieldsResult = {place: place}
@send
external fetchFields: (place, fetchFieldsRequest) => promise<fetchFieldsResult> = "fetchFields"

type searchByTextRequest = {
  textQuery: string,
  fields: array<string>,
  futureOpeningBusinessesIncluded?: bool,
  maxResultCount?: int,
  language?: string,
  locationBias?: circle,
}
type searchByTextResult = {places: array<place>}
@val @scope(("window", "google", "maps", "places", "Place"))
external searchByText: searchByTextRequest => promise<searchByTextResult> = "searchByText"

// --- Autocomplete ---
// A session token groups the keystrokes of one search with the final details
// fetch for billing; create one per search and drop it after fetchFields.
type sessionToken
@new @scope(("window", "google", "maps", "places"))
external makeSessionToken: unit => sessionToken = "AutocompleteSessionToken"

type autocompleteRequest = {
  input: string,
  sessionToken?: sessionToken,
  // Businesses with a listing but a future opening date are hidden unless set.
  futureOpeningBusinessesIncluded?: bool,
  includedPrimaryTypes?: array<string>,
  language?: string,
  region?: string,
  locationBias?: circle,
}
type formattableText = {text: string}
type placePrediction = {
  placeId: string,
  text: formattableText,
  mainText: Nullable.t<formattableText>,
  secondaryText: Nullable.t<formattableText>,
}
@send external toPlace: placePrediction => place = "toPlace"

type suggestion = {placePrediction: Nullable.t<placePrediction>}
type suggestionsResult = {suggestions: array<suggestion>}
@val @scope(("window", "google", "maps", "places", "AutocompleteSuggestion"))
external fetchAutocompleteSuggestions: autocompleteRequest => promise<suggestionsResult> =
  "fetchAutocompleteSuggestions"

// --- Helpers ---

// What the autocompleteLocation mutation needs to upsert a Location.
let locationFields = ["id", "displayName", "formattedAddress", "location"]

type resolved = {
  placeId: string,
  name: string,
  formattedAddress: string,
  lat: float,
  lng: float,
}

let toResolved = (place: place): option<resolved> =>
  switch (
    place.displayName->Nullable.toOption,
    place.formattedAddress->Nullable.toOption,
    place.location->Nullable.toOption,
  ) {
  | (Some(name), Some(formattedAddress), Some(location)) =>
    Some({placeId: place.id, name, formattedAddress, lat: location->lat, lng: location->lng})
  | _ => None
  }

// Turn a chosen prediction into a saveable place. This is the details fetch
// that closes the autocomplete session, so callers should drop their token.
let fetchResolved = async (prediction: placePrediction): option<resolved> => {
  let {place} = await prediction->toPlace->fetchFields({fields: locationFields})
  toResolved(place)
}

// Headless: resolve a free-text address to the top text-search hit. Resolves to
// None if the SDK isn't loaded, the request errors, or nothing matches.
let textSearchTop = async (query: string): option<resolved> =>
  try {
    let {places} = await searchByText({
      textQuery: query,
      fields: locationFields,
      futureOpeningBusinessesIncluded: true,
      maxResultCount: 1,
    })
    places->Array.get(0)->Option.flatMap(toResolved)
  } catch {
  | Js.Exn.Error(e) => {
      Console.error2("Places text search failed", e)
      None
    }
  }

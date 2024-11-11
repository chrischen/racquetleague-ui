type options = {
  types?: array<string>,
  fields?: array<string>,
}

type location = {
  lat: unit => float,
  lng: unit => float
}
type geometry = {
  location
}
type plus_code = {
  compound_code: string,
  global_code: string
}

type place = {
  formatted_address?: string,
  geometry?: geometry,
  name?: string,
  place_id?: string,
  plus_code?: plus_code
}
@react.component @module("react-google-autocomplete")
external make: (
  ~apiKey: string=?,
  ~onPlaceSelected: place => unit,
  ~options: options=?,
) => React.element = "default"

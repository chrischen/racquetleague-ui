type input = {
  id: string,
  googleMapsApiKey: string,
  libraries?: array<string>,
}
type resp = {
  isLoaded: bool
}
@module("@react-google-maps/api")
external useJsApiLoader: input => resp = "useJsApiLoader"

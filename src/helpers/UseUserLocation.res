type location = RelaySchemaAssets_graphql.input_LocationInput

let tokyoDefault: location = {lat: 35.658581, lng: 139.745438}

// Resolved means the permission prompt has been answered (or geolocation is
// unsupported) — the availability feature gates on resolution, not on grant.
type status =
  | Resolving
  | Resolved({location: location, granted: bool})

type geolocationCoords = {latitude: float, longitude: float}
type geolocationPosition = {coords: geolocationCoords}
type geolocationError

@val @scope(("navigator", "geolocation"))
external getCurrentPosition: (geolocationPosition => unit, geolocationError => unit) => unit =
  "getCurrentPosition"

// Check whether we're in a browser environment (undefined in SSR/Node)
@val external window_: Js.Nullable.t<{..}> = "window"

@val @scope("navigator") @return(nullable)
external geolocationSupport: option<{..}> = "geolocation"

// Module-level singleton store: one getCurrentPosition call (and one browser
// prompt) shared by every component, only ever mutated in the browser.
let current: ref<status> = ref(Resolving)
let listeners: ref<array<unit => unit>> = ref([])
let emit = () => listeners.contents->Array.forEach(l => l())
let started = ref(false)

let start = () => {
  if !started.contents && window_->Js.Nullable.toOption->Option.isSome {
    started := true
    switch geolocationSupport {
    | None =>
      current := Resolved({location: tokyoDefault, granted: false})
      emit()
    | Some(_) =>
      getCurrentPosition(
        pos => {
          current :=
            Resolved({
              location: {lat: pos.coords.latitude, lng: pos.coords.longitude},
              granted: true,
            })
          emit()
        },
        _err => {
          current := Resolved({location: tokyoDefault, granted: false})
          emit()
        },
      )
    }
  }
}

let subscribe = (cb: unit => unit) => {
  listeners := listeners.contents->Array.concat([cb])
  start()
  () => listeners := listeners.contents->Array.filter(l => l !== cb)
}

let useStatus = (): status =>
  React.useSyncExternalStoreWithServerSnapshot(
    ~subscribe,
    ~getSnapshot=() => current.contents,
    ~getServerSnapshot=() => Resolving,
  )

// Always yields a usable location (SetAvailabilityDayInput.location is required).
let use = (): location =>
  switch useStatus() {
  | Resolving => tokyoDefault
  | Resolved({location}) => location
  }

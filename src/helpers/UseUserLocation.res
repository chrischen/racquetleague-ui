type location = RelaySchemaAssets_graphql.input_LocationInput

let tokyoDefault: location = {lat: 35.658581, lng: 139.745438}

// Resolved means the permission prompt has been answered (or geolocation is
// unsupported) — the availability feature gates on resolution, not on grant.
type status =
  | Resolving
  | Resolved({location: location, granted: bool})

type geolocationCoords = {latitude: float, longitude: float}
type geolocationPosition = {coords: geolocationCoords}
// PositionError: 1 = PERMISSION_DENIED, 2 = POSITION_UNAVAILABLE, 3 = TIMEOUT
type geolocationError = {code: int, message: string}
type geolocationOptions = {
  enableHighAccuracy: bool,
  timeout: int,
  maximumAge: int,
}

@val @scope(("navigator", "geolocation"))
external getCurrentPosition: (
  geolocationPosition => unit,
  geolocationError => unit,
  geolocationOptions,
) => unit = "getCurrentPosition"

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
      // A bounded `timeout` is required: with the spec default (infinite), a
      // granted request the OS can't resolve (e.g. Location Services off for
      // the browser) never calls back and every subscriber sits on Resolving.
      // But Safari counts the time the permission prompt stays open toward
      // `timeout` (Chrome pauses the clock), so a TIMEOUT usually just means
      // the user hasn't answered yet — retry, which re-attaches to the still
      // pending grant. maximumAge lets a cached OS position resolve instantly.
      let rec attempt = retriesLeft =>
        getCurrentPosition(
          pos => {
            current :=
              Resolved({
                location: {lat: pos.coords.latitude, lng: pos.coords.longitude},
                granted: true,
              })
            emit()
          },
          err =>
            if err.code == 3 && retriesLeft > 0 {
              attempt(retriesLeft - 1)
            } else {
              Js.Console.warn2("Geolocation unavailable:", err)
              current := Resolved({location: tokyoDefault, granted: false})
              emit()
            },
          {enableHighAccuracy: false, timeout: 15000, maximumAge: 600000},
        )
      attempt(3)
    }
  }
}

// Passive: reflect whatever a prompting surface resolves, without triggering
// acquisition (and thus the browser permission prompt) ourselves.
let subscribePassive = (cb: unit => unit) => {
  listeners := listeners.contents->Array.concat([cb])
  () => listeners := listeners.contents->Array.filter(l => l !== cb)
}

let subscribe = (cb: unit => unit) => {
  let unsubscribe = subscribePassive(cb)
  start()
  unsubscribe
}

// Prompting: mounting this hook starts acquisition, which shows the browser
// permission prompt. Reserve it for surfaces whose job is capturing the
// viewer's location (ViewerLocationPrompt, AvailabilityPage's gate).
let useStatus = (): status =>
  React.useSyncExternalStoreWithServerSnapshot(
    ~subscribe,
    ~getSnapshot=() => current.contents,
    ~getServerSnapshot=() => Resolving,
  )

let usePassiveStatus = (): status =>
  React.useSyncExternalStoreWithServerSnapshot(
    ~subscribe=subscribePassive,
    ~getSnapshot=() => current.contents,
    ~getServerSnapshot=() => Resolving,
  )

// Always yields a usable location (SetAvailabilityDayInput.location is
// required). Passive — never triggers the permission prompt: yields the
// fallback until a prompting surface resolves real coords. The server treats
// the viewer's stored coords as canonical, so the fallback is only ever a
// placeholder for anonymous viewers.
let use = (): location =>
  switch usePassiveStatus() {
  | Resolving => tokyoDefault
  | Resolved({location}) => location
  }

// Plain coordinates — what browser geolocation yields, what the coords-only
// updateViewerLocation mutation stores, and the payload of the resolved-location
// readout. The query scope input (LocationInput) is a separate {coords | region}
// shape, built via the helpers at the bottom of this module.
type coords = {lat: float, lng: float}

let tokyoDefault: coords = {lat: 35.658581, lng: 139.745438}

// Resolved means the permission prompt has been answered (or geolocation is
// unsupported) — the availability feature gates on resolution, not on grant.
type status =
  | Resolving
  | Resolved({coords: coords, granted: bool})

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
      current := Resolved({coords: tokyoDefault, granted: false})
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
                coords: {lat: pos.coords.latitude, lng: pos.coords.longitude},
                granted: true,
              })
            emit()
          },
          err =>
            if err.code == 3 && retriesLeft > 0 {
              attempt(retriesLeft - 1)
            } else {
              Js.Console.warn2("Geolocation unavailable:", err)
              current := Resolved({coords: tokyoDefault, granted: false})
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

// Prompting: subscribing starts acquisition, which shows the browser permission
// prompt on mount. Prefer the on-demand `request` (below) for an explicit user
// gesture like the events "Near me" button; this ambient variant is for surfaces
// that gate on resolution rather than a click.
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

// Always yields usable coords. Passive — never triggers the permission prompt:
// yields the fallback until a prompting surface resolves real coords.
let use = (): coords =>
  switch usePassiveStatus() {
  | Resolving => tokyoDefault
  | Resolved({coords}) => coords
  }

// Passive, precedence-friendly variant: Some only when geolocation actually
// resolved with a grant, None otherwise (unresolved or denied). Pass this as a
// query's optional `location` so an absent value lets the server resolve the
// viewer's stored coords, then the default — instead of forcing the fallback.
let useOption = (): option<coords> =>
  switch usePassiveStatus() {
  | Resolved({coords, granted: true}) => Some(coords)
  | _ => None
  }

type requestOutcome =
  | Located(coords)
  | Denied
  | Unsupported

// On-demand geolocation for an explicit user gesture (the events "Near me"
// button) — as opposed to the ambient start/useStatus flow. Always issues a
// fresh getCurrentPosition (no one-shot guard) and reports the outcome; on
// success it also updates the shared store so passive consumers pick up the
// coords. Retries on a Safari prompt-timeout, same as `start`.
let request = (cb: requestOutcome => unit): unit =>
  switch (window_->Js.Nullable.toOption, geolocationSupport) {
  | (Some(_), Some(_)) =>
    let rec attempt = retriesLeft =>
      getCurrentPosition(
        pos => {
          let c: coords = {lat: pos.coords.latitude, lng: pos.coords.longitude}
          current := Resolved({coords: c, granted: true})
          emit()
          cb(Located(c))
        },
        err =>
          if err.code == 3 && retriesLeft > 0 {
            attempt(retriesLeft - 1)
          } else {
            cb(Denied)
          },
        {enableHighAccuracy: false, timeout: 15000, maximumAge: 600000},
      )
    attempt(2)
  | _ => cb(Unsupported)
  }

// --- Query scope: URL param ⇄ LocationInput ------------------------------
// The `location` URL param holds either a Region name ("tokyo") or "lat,lng"
// coords. The events filter writes it; the SSR loaders read it to build the
// query's LocationInput scope ({coords} for near-me, {region} for a named
// default). Absent, loaders pass nothing and the server resolves the viewer's
// stored coords, then the default.
let locationParamKey = "location"
let tokyoRegionParam = "tokyo"

let coordsToParam = (c: coords): string => Float.toString(c.lat) ++ "," ++ Float.toString(c.lng)

let locationInputOfCoords = (c: coords): RelaySchemaAssets_graphql.input_LocationInput => {
  coords: {lat: c.lat, lng: c.lng},
}

let locationInputFromParam = (s: string): option<RelaySchemaAssets_graphql.input_LocationInput> =>
  if s == tokyoRegionParam {
    Some({region: Tokyo})
  } else {
    switch s->String.split(",") {
    | [lat, lng] =>
      switch (lat->Float.fromString, lng->Float.fromString) {
      | (Some(lat), Some(lng)) => Some(locationInputOfCoords({lat, lng}))
      | _ => None
      }
    | _ => None
    }
  }

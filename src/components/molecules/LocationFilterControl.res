%%raw("import { t } from '@lingui/macro'")

// Connected container for the location filter (renders LocationFilter), used by
// the events list and the availability page. Not viewer-specific: anyone,
// including anonymous users, drives it to scope the view.
//
// Selecting a default location (Tokyo) or using "Near me" pushes the chosen
// coords into the `coords` URL param, which the initial/SSR query reads to scope
// availability — changing it re-runs the route loader. For logged-in viewers it
// additionally persists the coords as their home location via
// updateViewerLocation, so future loads WITHOUT a URL param still scope
// correctly. Logged-out viewers get the URL param only — no persistence.

module Mutation = %relay(`
  mutation LocationFilterControlMutation($input: UpdateViewerLocationInput!) {
    updateViewerLocation(input: $input) {
      viewer {
        id
        coords {
          lat
          lng
        }
      }
      errors {
        message
      }
    }
  }
`)

let tokyoValue = "tokyo"

@react.component
// The server-resolved location scoping the data (Query.resolvedLocation) — the
// single source of truth, precedence lives only on the server. `resolvedRegion`
// is the symbolic named default (e.g. Tokyo) when the server resolved to one; it
// drives the selected option. `resolvedCoords` is always shown for the readout.
let make = (
  ~isLoggedIn: bool,
  ~resolvedCoords: UseUserLocation.coords,
  ~resolvedRegion: option<RelaySchemaAssets_graphql.enum_Region>,
  // Optional event-list filter controls appended after the location cluster
  // (see LocationFilter.eventFilters). The availability page leaves this off.
  ~eventFilters: option<LocationFilter.eventFilters>=?,
) => {
  let (commit, _isMutating) = Mutation.use()
  let (_searchParams, setSearchParams) = Router.useSearchParamsFunc()
  let (status, setStatus) = React.useState(() => LocationFilter.Idle)
  let (errorMessage, setErrorMessage) = React.useState((): option<string> => None)

  // Selected option comes straight from the server's symbolic region: a named
  // default maps to its dropdown value; no region means explicit/stored coords,
  // shown as "near me". No coordinate comparison against a client constant.
  let selectedLocation = switch resolvedRegion {
  | Some(Tokyo) => tokyoValue
  | _ => "near-me"
  }

  // Write (or clear) the `location` URL param — a Region name or "lat,lng". This
  // is what the initial/SSR query reads; changing it re-runs the route loader.
  let setLocationParam = (value: option<string>) =>
    setSearchParams(prev => {
      switch value {
      | Some(v) => prev->Router.SearchParams.set(UseUserLocation.locationParamKey, v)
      | None => prev->Router.SearchParams.delete(UseUserLocation.locationParamKey)
      }
      prev
    })

  // Persist coords as the viewer's home so future loads without a URL param still
  // scope correctly (updateViewerLocation is coords-only). Logged-out viewers skip.
  let persist = (coords: UseUserLocation.coords) =>
    if isLoggedIn {
      commit(
        ~variables={input: {lat: coords.lat, lng: coords.lng}},
      )->RescriptRelay.Disposable.ignore
    }

  // Tokyo default: scope the query to the Tokyo region (non-coords input), and
  // still persist Tokyo's coords as the viewer's home.
  let selectTokyo = () => {
    setStatus(_ => LocationFilter.Idle)
    setErrorMessage(_ => None)
    setLocationParam(Some(UseUserLocation.tokyoRegionParam))
    persist(UseUserLocation.tokyoDefault)
  }

  let onSelectLocation = value =>
    switch value {
    | v if v == tokyoValue => selectTokyo()
    | _ => () // "near-me" is display-only; the button drives near-me
    }

  let onNearMe = () => {
    setStatus(_ => LocationFilter.Loading)
    setErrorMessage(_ => None)
    UseUserLocation.request(outcome => {
      // Back to Idle either way; on success the URL param change re-runs the
      // loader and the new server-resolved location flows back in as a prop.
      // Errors surface via errorMessage.
      setStatus(_ => LocationFilter.Idle)
      switch outcome {
      | Located(coords) =>
        setLocationParam(Some(UseUserLocation.coordsToParam(coords)))
        persist(coords)
      | Denied =>
        setErrorMessage(_ => Some(
          Lingui.UtilString.t`Location access was denied. Allow access or choose a venue.`,
        ))
      | Unsupported =>
        setErrorMessage(_ => Some(
          Lingui.UtilString.t`Current location is not supported by this browser.`,
        ))
      }
    })
  }

  <LocationFilter
    locations=[(tokyoValue, Lingui.UtilString.t`Tokyo`)]
    selectedLocation
    status
    coordinates=Some(resolvedCoords)
    nearbyRadiusKm=10
    errorMessage
    onSelectLocation
    onNearMe
    ?eventFilters
  />
}

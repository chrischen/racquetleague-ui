%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

// Venue search on Places API (New): a plain input driving
// AutocompleteSuggestion, with the details fetch and Location upsert on pick.
// Bindings live in GooglePlaces.

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

type placesLibrary

let debounceMs = 200

@react.component
let make = (
  ~onSelected: string => unit,
  ~error: option<string>=?,
  ~autoSearchAddress: option<string>=?,
) => {
  let {i18n: {locale}} = Lingui.useLingui()
  let placesReady =
    (RGMHooks.useMapsLibrary("places"): Js.Null.t<placesLibrary>)->Js.Null.toOption->Option.isSome

  let (query, setQuery) = React.useState(() => "")
  let (suggestions, setSuggestions) = React.useState((): array<GooglePlaces.placePrediction> => [])
  let (isOpen, setIsOpen) = React.useState(() => false)
  let (focused, setFocused) = React.useState(() => false)
  let (activeIndex, setActiveIndex) = React.useState(() => -1)
  // True while a pick is being resolved and saved.
  let (busy, setBusy) = React.useState(() => false)
  let (searchError, setSearchError) = React.useState((): option<React.element> => None)

  let sessionToken = React.useRef(None)
  // Monotonic request id so a slow response can't overwrite a newer one.
  let requestSeq = React.useRef(0)
  // The text we filled in on pick; don't search for it again.
  let selectedText = React.useRef(None)
  let listId = React.useId()

  let (commitMutationCreate, _) = AutocompleteLocationMutation.use()

  let upsert = (resolved: GooglePlaces.resolved) => {
    setBusy(_ => true)
    commitMutationCreate(
      ~variables={
        input: {
          name: resolved.name,
          formattedAddress: resolved.formattedAddress,
          lat: resolved.lat,
          lng: resolved.lng,
          mapsId: resolved.placeId,
        },
      },
      ~onCompleted=(response, _errors) => {
        setBusy(_ => false)
        switch response.autocompleteLocation.location {
        | Some(location) => onSelected(location.id)
        | None => setSearchError(_ => Some(Lingui.Util.t`Could not save that location`))
        }
      },
      ~onError=_ => {
        setBusy(_ => false)
        setSearchError(_ => Some(Lingui.Util.t`Could not save that location`))
      },
    )->RescriptRelay.Disposable.ignore
  }

  let fetchSuggestions = async (input: string) => {
    let seq = requestSeq.current + 1
    requestSeq.current = seq
    let token = switch sessionToken.current {
    | Some(token) => token
    | None => {
        let token = GooglePlaces.makeSessionToken()
        sessionToken.current = Some(token)
        token
      }
    }
    try {
      let {suggestions} = await GooglePlaces.fetchAutocompleteSuggestions({
        input,
        sessionToken: token,
        language: locale,
        includedPrimaryTypes: ["establishment"],
        futureOpeningBusinessesIncluded: true,
      })
      if requestSeq.current == seq {
        setSuggestions(_ => suggestions->Array.filterMap(s => s.placePrediction->Nullable.toOption))
        setActiveIndex(_ => -1)
        setSearchError(_ => None)
      }
    } catch {
    | Js.Exn.Error(e) =>
      if requestSeq.current == seq {
        Console.error2("Places autocomplete failed", e)
        setSuggestions(_ => [])
        setSearchError(_ => Some(Lingui.Util.t`Location search is unavailable right now`))
      }
    }
  }

  // Debounced search on the typed text once the Places library is loaded.
  React.useEffect(() => {
    let input = query->String.trim
    if !placesReady || input == "" || selectedText.current == Some(query) {
      None
    } else {
      let id = setTimeout(() => fetchSuggestions(input)->ignore, debounceMs)
      Some(() => clearTimeout(id))
    }
  }, (query, placesReady))

  let select = async (prediction: GooglePlaces.placePrediction) => {
    let text = prediction.text.text
    selectedText.current = Some(text)
    setQuery(_ => text)
    setIsOpen(_ => false)
    setSuggestions(_ => [])
    setActiveIndex(_ => -1)
    setBusy(_ => true)
    try {
      let resolved = await GooglePlaces.fetchResolved(prediction)
      // The details fetch closes the billing session; the next search starts a new one.
      sessionToken.current = None
      switch resolved {
      | Some(resolved) => upsert(resolved)
      | None => {
          setBusy(_ => false)
          setSearchError(_ => Some(Lingui.Util.t`Could not load that place`))
        }
      }
    } catch {
    | Js.Exn.Error(e) => {
        Console.error2("Place details failed", e)
        setBusy(_ => false)
        setSearchError(_ => Some(Lingui.Util.t`Could not load that place`))
      }
    }
  }

  // Resolve a caller-supplied address (e.g. from the AI event parser) headlessly.
  React.useEffect(() => {
    switch (autoSearchAddress, placesReady) {
    | (Some(address), true) =>
      GooglePlaces.textSearchTop(address)
      ->Promise.thenResolve(resolved => resolved->Option.forEach(upsert))
      ->ignore
    | _ => ()
    }
    None
  }, (autoSearchAddress, placesReady))

  let count = suggestions->Array.length
  let showList = focused && isOpen && count > 0

  let onKeyDown = e => {
    switch ReactEvent.Keyboard.key(e) {
    | "ArrowDown" if count > 0 => {
        ReactEvent.Keyboard.preventDefault(e)
        setIsOpen(_ => true)
        setActiveIndex(i => mod(i + 1, count))
      }
    | "ArrowUp" if count > 0 => {
        ReactEvent.Keyboard.preventDefault(e)
        setIsOpen(_ => true)
        setActiveIndex(i => i <= 0 ? count - 1 : i - 1)
      }
    | "Enter" if showList => {
        // Pick instead of submitting the surrounding form.
        ReactEvent.Keyboard.preventDefault(e)
        suggestions
        ->Array.get(activeIndex < 0 ? 0 : activeIndex)
        ->Option.forEach(prediction => select(prediction)->ignore)
      }
    | "Escape" => {
        setIsOpen(_ => false)
        setActiveIndex(_ => -1)
      }
    | _ => ()
    }
  }

  let onChange = e => {
    let value = ReactEvent.Form.target(e)["value"]
    selectedText.current = None
    setQuery(_ => value)
    setIsOpen(_ => true)
    setSearchError(_ => None)
    if value->String.trim == "" {
      setSuggestions(_ => [])
    }
  }

  let optionId = i => `${listId}-${i->Int.toString}`

  <div>
    <div className="relative">
      <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
        {busy
          ? <Lucide.Loader2 size=15 className="animate-spin text-gray-400" />
          : <Lucide.Search size=15 className="text-gray-400" />}
      </div>
      <input
        type_="text"
        role="combobox"
        ariaExpanded=showList
        ariaControls=listId
        ariaActivedescendant=?{showList && activeIndex >= 0 ? Some(optionId(activeIndex)) : None}
        autoComplete="off"
        spellCheck=false
        value=query
        disabled=busy
        onChange
        onKeyDown
        onFocus={_ => setFocused(_ => true)}
        onBlur={_ => setFocused(_ => false)}
        className={Util.cx([
          "box-border block h-11 w-full min-w-0 rounded-lg border bg-white pl-9 pr-3 text-sm text-gray-900 outline-none transition-colors placeholder:text-gray-400 focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/40 dark:bg-[#1e1f23] dark:text-gray-100",
          error->Option.isSome
            ? "border-red-300 dark:border-red-700"
            : "border-gray-200 dark:border-[#3a3b40]",
        ])}
        placeholder={ts`Search for a venue or address`}
      />
      {showList
        ? <ul
            id=listId
            role="listbox"
            className="absolute left-0 right-0 z-20 mt-1 max-h-72 overflow-y-auto rounded-lg border border-gray-200 bg-white py-1 shadow-lg dark:border-[#3a3b40] dark:bg-[#1e1f23]">
            {suggestions
            ->Array.mapWithIndex((prediction, i) => {
              let main =
                prediction.mainText
                ->Nullable.toOption
                ->Option.map(t => t.text)
                ->Option.getOr(prediction.text.text)
              let secondary =
                prediction.secondaryText->Nullable.toOption->Option.map(t => t.text)->Option.getOr("")
              <li
                key=prediction.placeId
                id={optionId(i)}
                role="option"
                ariaSelected={i == activeIndex}
                // Keep the input focused (and the list open) through the click.
                onMouseDown={e => ReactEvent.Mouse.preventDefault(e)}
                onMouseEnter={_ => setActiveIndex(_ => i)}
                onClick={_ => select(prediction)->ignore}
                className={Util.cx([
                  "flex cursor-pointer items-start gap-2 px-3 py-2",
                  i == activeIndex ? "bg-gray-100 dark:bg-[#2a2b30]" : "",
                ])}>
                <Lucide.MapPin size=14 className="mt-0.5 shrink-0 text-gray-400" />
                <div className="min-w-0">
                  <div className="truncate text-sm text-gray-900 dark:text-gray-100">
                    {main->React.string}
                  </div>
                  {secondary == ""
                    ? React.null
                    : <div className="truncate text-xs text-gray-500 dark:text-gray-400">
                        {secondary->React.string}
                      </div>}
                </div>
              </li>
            })
            ->React.array}
            <li
              className="mt-1 border-t border-gray-100 px-3 pt-1.5 text-right text-[10px] text-gray-400 dark:border-[#3a3b40]">
              {"Powered by Google"->React.string}
            </li>
          </ul>
        : React.null}
    </div>
    {switch (error, searchError) {
    | (Some(message), _) =>
      <p className="mt-1 text-sm text-red-600 dark:text-red-400"> {message->React.string} </p>
    | (None, Some(message)) =>
      <p className="mt-1 text-sm text-red-600 dark:text-red-400"> message </p>
    | (None, None) => React.null
    }}
  </div>
}

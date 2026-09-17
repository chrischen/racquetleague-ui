// The create-event form opens as a modal over the current page (see
// CreateEventModal). The URL records it with the `create` search param, so
// reload, back and shared links all reproduce it, and any prefill travels in
// the same query. Links are built from the current path without its locale
// prefix, because LangProvider.Router adds that back to every leading-"/" path.
let param = "create"

// Everything CreateEventPage reads from the URL; stripped when the modal
// closes with no history entry to step back to.
let prefillKeys = [
  "clubId",
  "locationId",
  "activitySlug",
  "activityId",
  "date",
  "startHour",
  "endHour",
  "title",
  "details",
  "maxRsvps",
  "minRating",
  "listed",
  "timezone",
  "tags",
  "price",
  "cancelDeadline",
  "startDateTime",
  "endTime",
]

let isOpen = (query: Router.SearchParams.t) =>
  query->Router.SearchParams.get(param)->Option.isSome

let strip = (query: Router.SearchParams.t) => {
  query->Router.SearchParams.delete(param)
  prefillKeys->Array.forEach(key => query->Router.SearchParams.delete(key))
}

// A location club's create links carry its home court, title and player cap
// as prefill (see LocationClub); other clubs add nothing.
let useClubPrefillParams = LocationClub.useCreatePrefillParams

// A link that opens the modal over the page currently shown, with `params`
// as the form's prefill.
let useHref = () => {
  let locale = React.useContext(LangProvider.LocaleContext.context)
  let location = Router.useLocation()
  (params: array<(string, string)>) => {
    let prefix = "/" ++ locale.lang
    let pathname = if location.pathname == prefix {
      "/"
    } else if location.pathname->String.startsWith(prefix ++ "/") {
      location.pathname->String.sliceToEnd(~start=String.length(prefix))
    } else {
      location.pathname
    }
    let query = Router.SearchParams.make(location.search)
    query->Router.SearchParams.set(param, "1")
    params->Array.forEach(((key, value)) => query->Router.SearchParams.set(key, value))
    pathname ++ "?" ++ query->Router.SearchParams.toString
  }
}

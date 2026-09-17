%%raw("import { t } from '@lingui/macro'")

@module("react") external startTransition: (unit => unit) => unit = "startTransition"

module Query = %relay(`
  query CreateEventPageQuery($locationId: ID!, $after: String, $first: Int, $before: String) {
    location(id: $locationId) {
      ...CreateLocationEventForm_location
    }
    viewer {
      user {
        stripeChargesEnabled
      }
    }
    ...ClubActivitySelector_query @arguments(after: $after, first: $first, before: $before)
  }
  `)
// The form and everything around it: hosted by CreateEventModal over the
// current page, or by `make` below as a page of its own for direct links.
module Body = {
  @react.component
  let make = () => {
    open Lingui.Util
    let (params, setParams) = Router.useSearchParamsFuncWith()
    let locationParam = params->Router.SearchParams.get("locationId")
    let clubIdParam = params->Router.SearchParams.get("clubId")
    let activitySlugParam = params->Router.SearchParams.get("activitySlug")
    // Direct Activity id prefill — used by court-opening "Create event" links,
    // whose surfaces know the activity by id rather than slug.
    let activityIdParam = params->Router.SearchParams.get("activityId")
    let dateParam = params->Router.SearchParams.get("date")
    let startHourParam = params->Router.SearchParams.get("startHour")
    let endHourParam = params->Router.SearchParams.get("endHour")
    // Prefill params used when linking here from an event's "copy event" button
    // (see PkEventPage.res) — full-precision date/time, distinct from the
    // coarse date/startHour/endHour slot params above.
    let titleParam = params->Router.SearchParams.get("title")
    let detailsParam = params->Router.SearchParams.get("details")
    let maxRsvpsParam = params->Router.SearchParams.get("maxRsvps")
    let minRatingParam = params->Router.SearchParams.get("minRating")
    let listedParam = params->Router.SearchParams.get("listed")
    let timezoneParam = params->Router.SearchParams.get("timezone")
    let tagsParam = params->Router.SearchParams.get("tags")
    let priceParam = params->Router.SearchParams.get("price")
    let cancelDeadlineParam = params->Router.SearchParams.get("cancelDeadline")
    let startDateTimeParam = params->Router.SearchParams.get("startDateTime")
    let endTimeParam = params->Router.SearchParams.get("endTime")
    let queryData = Query.use(
      ~variables={
        locationId: locationParam->Option.getOr(""),
      },
    )

    // State to hold prefilled event values from AI
    let (prefilledValues, setPrefilledValues) = React.useState(() => None)
    // State to hold AI-suggested location address for auto-search
    let (aiLocationAddress, setAiLocationAddress) = React.useState(() => None)

    let (clubSelection, setClubSelection) = React.useState((): ClubActivitySelector.selection => {
      clubId: clubIdParam,
      activityId: None,
      isAddingClub: false,
    })
    let (shakeCounter, setShakeCounter) = React.useState(() => 0)

    // Create initial prefilled values with clubId, activitySlug, and date from URL if present
    // Everything copied from an existing event except the title and player
    // cap: those two on their own (a location club's links carry "Open Play"
    // and its cap) preset a new event and must not put the form in copy mode,
    // which drops its new-event defaults.
    let isCopy =
      [
        detailsParam,
        minRatingParam,
        listedParam,
        timezoneParam,
        tagsParam,
        priceParam,
        cancelDeadlineParam,
        startDateTimeParam,
        endTimeParam,
      ]->Array.some(Option.isSome)

    let initialPrefilledValues = React.useMemo7(() => {
      // Slot hours are fractional ("18.5" is 18:30), as drafted on the time
      // window pickers. A date with no hours opens a default evening window
      // rather than leaving the end at the form's own fallback.
      let startHour = startHourParam->Option.flatMap(Float.fromString)->Option.getOr(18.0)
      let endHour =
        endHourParam
        ->Option.flatMap(Float.fromString)
        ->Option.getOr(Js.Math.min_float(startHour +. 2.0, 24.0))
      let startDate =
        dateParam->Option.map(isoDate => isoDate ++ "T" ++ TimeWindow.hourToTime(startHour))
      let endDate = switch (endHourParam, dateParam) {
      | (None, None) => None
      | _ => Some(TimeWindow.hourToTime(endHour))
      }
      let maxRsvps = maxRsvpsParam->Option.flatMap(v => Int.fromString(v))
      switch (clubIdParam, activitySlugParam, startDate, titleParam, maxRsvps) {
      | (None, None, None, None, None) => None
      | _ =>
        Some({
          let initial: CreateLocationEventForm.prefilledValues = {
            title: ?titleParam,
            ?maxRsvps,
            clubId: ?clubIdParam,
            activitySlug: ?activitySlugParam,
            ?startDate,
            ?endDate,
          }
          initial
        })
      }
    }, (
      clubIdParam,
      activitySlugParam,
      dateParam,
      startHourParam,
      endHourParam,
      titleParam,
      maxRsvpsParam,
    ))

    // Prefilled values sourced from the "copy event" link (PkEventPage.res) —
    // no query needed, since the source event's data travels via URL params.
    // Distinct from, and higher priority than, the coarse slot-based
    // initialPrefilledValues above.
    let copyPrefilledValues: option<CreateLocationEventForm.prefilledValues> = {
      isCopy
        ? Some({
            let values: CreateLocationEventForm.prefilledValues = {
              title: ?titleParam,
              details: ?detailsParam,
              clubId: ?clubIdParam,
              activitySlug: ?activitySlugParam,
              maxRsvps: ?maxRsvpsParam->Option.flatMap(v => Int.fromString(v)),
              minRating: ?minRatingParam->Option.flatMap(v => Float.fromString(v)),
              listed: ?listedParam->Option.map(v => v == "true"),
              timezone: ?timezoneParam,
              tags: ?tagsParam->Option.map(v => v->String.split(",")),
              price: ?priceParam->Option.flatMap(v => Int.fromString(v)),
              cancelDeadline: ?cancelDeadlineParam->Option.flatMap(v => Int.fromString(v)),
              startDate: ?startDateTimeParam,
              endDate: ?endTimeParam,
              // Copies mirror the source event, so the form must not layer its
              // new-event defaults (e.g. cancel deadline) over the fields the
              // source event left unset.
              fromExistingEvent: true,
            }
            values
          })
        : None
    }

    let handleSingleEventSuggested = (eventDetails: AITypes.eventDetails) => {
      // Convert AITypes.eventDetails to CreateLocationEventForm.prefilledValues
      let startDate = Js.Date.fromString(eventDetails.date)
      let endDate = Js.Date.fromString(eventDetails.time)

      // The remaining CreateEventInput fields ride in `rawFields` (keys match the
      // form's prefilledValues), so new event fields prefill with no change here.
      let rawFields = eventDetails.rawFields->Option.getOr(Js.Dict.empty())
      let getStr = key => rawFields->Js.Dict.get(key)->Option.flatMap(v => v->Js.Json.decodeString)
      let getNum = key => rawFields->Js.Dict.get(key)->Option.flatMap(v => v->Js.Json.decodeNumber)
      let getBool = key =>
        rawFields->Js.Dict.get(key)->Option.flatMap(v => v->Js.Json.decodeBoolean)
      let getIntFromNum = key => getNum(key)->Option.map(Float.toInt)
      let getStrArray = key =>
        rawFields
        ->Js.Dict.get(key)
        ->Option.flatMap(v => v->Js.Json.decodeArray)
        ->Option.map(arr => arr->Belt.Array.keepMap(v => v->Js.Json.decodeString))

      // minRating is intentionally NOT read here: skill level is expressed via
      // `tags` (e.g. "3.5+") and the form derives the numeric minRating from them.
      let price = getIntFromNum("price")
      let cancelDeadline = getIntFromNum("cancelDeadline")
      // `listed` defaults to public per the tool contract: the model omits it for
      // public events, so absence means public (true). Without this the create
      // form would fall back to its own default (private) and the public/private
      // toggle would look "not set".
      let listed = Some(getBool("listed")->Option.getOr(true))
      let timezone = getStr("timezone")
      // The draft's dates are instants; the form wants wall-clock values in the
      // event's zone - the draft's own if it names one, else the browser's.
      let draftTz = timezone->Option.getOr(Util.Timezone.browser())
      let startDateFormatted = Util.Timezone.toWallClock(startDate, draftTz)
      let endTimeFormatted =
        Util.Timezone.toWallClock(endDate, draftTz)->String.slice(~start=11, ~end=16)
      let tags = getStrArray("tags")

      let prefilledData: CreateLocationEventForm.prefilledValues = {
        title: ?Some(eventDetails.title),
        startDate: ?Some(startDateFormatted),
        endDate: ?Some(endTimeFormatted),
        details: ?eventDetails.description,
        maxRsvps: ?eventDetails.maxRsvps,
        activitySlug: ?activitySlugParam,
        clubId: ?clubIdParam,
        ?price,
        ?cancelDeadline,
        ?listed,
        ?timezone,
        ?tags,
      }

      setPrefilledValues(_ => Some(prefilledData))

      // Set the location address for auto-search if provided
      eventDetails.location
      ->Option.map(address => {
        setAiLocationAddress(_ => Some(address))
      })
      ->ignore
    }

    open LangProvider.Router
    <div className="space-y-4">
      <AIAssistantEmbed
        context={{
          activitySlug: ?Some("pickleball"),
          clubId: ?clubIdParam,
          locationAddress: ?None,
        }}
        onSingleEventSuggested=handleSingleEventSuggested
      />
      <ClubActivitySelector
        query=queryData.fragmentRefs
        initialClubId=?clubIdParam
        initialActivitySlug=?activitySlugParam
        initialActivityId=?activityIdParam
        onChange={sel => setClubSelection(_ => sel)}
        triggerShake=shakeCounter
      />
      <CreateLocationEventForm
        location=?{queryData.location->Option.map(location => location.fragmentRefs)}
        onLocationSelected={locationId => {
          // The chosen venue lives in the URL so the page query picks it up;
          // the transition keeps the form, and what is typed in it, mounted
          // while that refetch is in flight.
          startTransition(() => setParams(prevParams => {
              prevParams->Router.SearchParams.set("locationId", locationId)
              prevParams
            }, {Router.replace: true}))
          setAiLocationAddress(_ => None)
        }}
        autoSearchAddress=?aiLocationAddress
        stripeChargesEnabled={queryData.viewer
        ->Option.flatMap(v => v.user)
        ->Option.flatMap(u => u.stripeChargesEnabled)
        ->Option.getOr(false)}
        prefilledValues=?{prefilledValues
        ->Option.orElse(copyPrefilledValues)
        ->Option.orElse(initialPrefilledValues)}
        selectedClub=?clubSelection.clubId
        selectedActivity=?clubSelection.activityId
        isClubFormOpen=clubSelection.isAddingClub
        onClubFormSubmitBlocked={() => setShakeCounter(n => n + 1)}
      />
      <p className="text-center text-xs text-gray-500 dark:text-gray-400">
        <Link
          to="/events/create-bulk"
          className="font-semibold text-[#4d6f12] hover:underline dark:text-[#bdf25d]">
          {t`Create multiple events instead`}
        </Link>
      </p>
    </div>
  }
}

// Direct links (bookmarks, the login return) land here as a page of its own.
@react.component
let make = () => {
  open Lingui.Util
  open LangProvider.Router
  <div
    className="min-h-screen w-full bg-gray-50 text-gray-900 transition-colors dark:bg-[#111111] dark:text-gray-100">
    <div className="border-b border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#1e1f23]">
      <div className="mx-auto flex max-w-2xl items-center justify-between gap-3 px-4 py-3">
        <Link
          to=".."
          relative="path"
          className="inline-flex w-16 items-center gap-1.5 text-xs font-semibold text-gray-500 transition-colors hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-100">
          <Lucide.ArrowLeft size=14 \"aria-hidden"="true" />
          {t`Cancel`}
        </Link>
        <div className="min-w-0 text-center">
          <div
            className="font-mono text-[10px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
            {t`New plan`}
          </div>
          <h1 className="truncate text-base font-semibold"> {t`Create event`} </h1>
        </div>
        <span className="w-16" ariaHidden=true />
      </div>
    </div>
    <div className="mx-auto max-w-2xl px-4 py-6">
      <WaitForMessages> {() => <Body />} </WaitForMessages>
    </div>
  </div>
}

%%raw("import { t } from '@lingui/macro'")

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
@react.component
let make = () => {
  open Lingui.Util
  let (params, setParams) = Router.useSearchParamsFunc()
  let locationParam = params->Router.SearchParams.get("locationId")
  let clubIdParam = params->Router.SearchParams.get("clubId")
  let activitySlugParam = params->Router.SearchParams.get("activitySlug")
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
  let initialPrefilledValues = React.useMemo5(() => {
    let timeStr =
      startHourParam
      ->Option.flatMap(h => h->Int.fromString)
      ->Option.map(h => "T" ++ h->Int.toString->String.padStart(2, "0") ++ ":00")
      ->Option.getOr("T10:00")
    let startDate = dateParam->Option.map(isoDate => isoDate ++ timeStr)
    let endDate =
      endHourParam
      ->Option.flatMap(h => h->Int.fromString)
      ->Option.map(h => h->Int.toString->String.padStart(2, "0") ++ ":00")
    switch (clubIdParam, activitySlugParam, startDate) {
    | (None, None, None) => None
    | _ =>
      Some({
        let initial: CreateLocationEventForm.prefilledValues = {
          clubId: ?clubIdParam,
          activitySlug: ?activitySlugParam,
          ?startDate,
          ?endDate,
        }
        initial
      })
    }
  }, (clubIdParam, activitySlugParam, dateParam, startHourParam, endHourParam))

  // Prefilled values sourced from the "copy event" link (PkEventPage.res) —
  // no query needed, since the source event's data travels via URL params.
  // Distinct from, and higher priority than, the coarse slot-based
  // initialPrefilledValues above.
  let copyPrefilledValues: option<CreateLocationEventForm.prefilledValues> = {
    let hasAny =
      [
        titleParam,
        detailsParam,
        maxRsvpsParam,
        minRatingParam,
        listedParam,
        timezoneParam,
        tagsParam,
        priceParam,
        cancelDeadlineParam,
        startDateTimeParam,
        endTimeParam,
      ]->Array.some(Option.isSome)
    hasAny
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
          }
          values
        })
      : None
  }

  let handleSingleEventSuggested = (eventDetails: AITypes.eventDetails) => {
    // Convert AITypes.eventDetails to CreateLocationEventForm.prefilledValues
    let startDate = Js.Date.fromString(eventDetails.date)
    let endDate = Js.Date.fromString(eventDetails.time)

    let startDateFormatted = startDate->DateFns.formatWithPattern("yyyy-MM-dd'T'HH:mm")
    let endTimeFormatted = endDate->DateFns.formatWithPattern("HH:mm")

    let prefilledData: CreateLocationEventForm.prefilledValues = {
      title: ?Some(eventDetails.title),
      startDate: ?Some(startDateFormatted),
      endDate: ?Some(endTimeFormatted),
      details: ?eventDetails.description,
      maxRsvps: ?eventDetails.maxRsvps,
      activitySlug: ?activitySlugParam,
      clubId: ?clubIdParam,
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
  <div
    className="min-h-screen bg-gray-50 dark:bg-[#111111] w-full text-gray-900 dark:text-gray-100 transition-colors">
    <div
      className="bg-white dark:bg-[#1a1a1a] shadow-sm border-b border-gray-200 dark:border-gray-800 transition-colors">
      <div className="max-w-2xl mx-auto px-4 py-4 flex items-center justify-between">
        <Link
          to={".."}
          relative="path"
          className="inline-flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 transition-colors font-medium">
          <Lucide.ArrowLeft className="w-5 h-5" />
          {t`Cancel`}
        </Link>
        <h1 className="text-lg font-bold"> {t`Create Event`} </h1>
        <Link
          to={"/events/create-bulk"}
          className="text-xs text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 transition-colors w-20 text-right">
          {t`Bulk create`}
        </Link>
      </div>
    </div>
    <div className="max-w-2xl mx-auto px-4 py-8 space-y-6">
      <WaitForMessages>
        {() => <>
          <AIAssistantEmbed
            context={{
              activitySlug: ?Some("pickleball"),
              clubId: ?clubIdParam,
              locationAddress: ?None,
            }}
            onSingleEventSuggested=handleSingleEventSuggested
          />
          <div>
            <label
              className="block text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400 mb-2">
              {t`Location`}
            </label>
            <AutocompleteLocation
              onSelected={location => {
                setParams(prevParams => {
                  prevParams->Router.SearchParams.set("locationId", location)
                  prevParams
                })
                setAiLocationAddress(_ => None)
              }}
              autoSearchAddress=?aiLocationAddress
            />
          </div>
          <FramerMotion.AnimatePresence mode="wait">
            {queryData.location
            ->Option.map(location => <>
              <ClubActivitySelector
                query=queryData.fragmentRefs
                initialClubId=?clubIdParam
                initialActivitySlug=?activitySlugParam
                onChange={sel => setClubSelection(_ => sel)}
                triggerShake=shakeCounter
              />
              <CreateLocationEventForm
                location=location.fragmentRefs
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
            </>)
            ->Option.getOr(React.null)}
          </FramerMotion.AnimatePresence>
        </>}
      </WaitForMessages>
    </div>
  </div>
}

%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query CreateEventPageQuery($locationId: ID!, $after: String, $first: Int, $before: String) {
    location(id: $locationId) {
      ...CreateLocationEventForm_location
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

  let queryData = Query.use(
    ~variables={
      locationId: locationParam->Option.getOr(""),
    },
  )

  let (clubSelection, setClubSelection) = React.useState(() =>
    ({
      clubId: clubIdParam,
      activityId: None,
      isAddingClub: false,
    }: ClubActivitySelector.selection)
  )
  let (shakeCounter, setShakeCounter) = React.useState(() => 0)

  // State to hold prefilled event values from AI
  let (prefilledValues, setPrefilledValues) = React.useState(() => None)
  // State to hold AI-suggested location address for auto-search
  let (aiLocationAddress, setAiLocationAddress) = React.useState(() => None)

  // Create initial prefilled values with clubId, activitySlug, and date from URL if present
  let initialPrefilledValues = React.useMemo3(() => {
    let startDate = dateParam->Option.map(isoDate => isoDate ++ "T10:00")
    switch (clubIdParam, activitySlugParam, startDate) {
    | (None, None, None) => None
    | _ =>
      Some({
        let initial: CreateLocationEventForm.prefilledValues = {
          clubId: ?clubIdParam,
          activitySlug: ?activitySlugParam,
          ?startDate,
        }
        initial
      })
    }
  }, (clubIdParam, activitySlugParam, dateParam))

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
          <ClubActivitySelector
            query=queryData.fragmentRefs
            initialClubId=?clubIdParam
            initialActivitySlug=?activitySlugParam
            onChange={sel => setClubSelection(_ => sel)}
            triggerShake=shakeCounter
          />
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
            ->Option.map(location =>
              switch (prefilledValues, initialPrefilledValues) {
              | (Some(aiValues), _) =>
                <CreateLocationEventForm
                  location=location.fragmentRefs
                  prefilledValues=aiValues
                  selectedClub=?clubSelection.clubId
                  selectedActivity=?clubSelection.activityId
                  isClubFormOpen=clubSelection.isAddingClub
                  onClubFormSubmitBlocked={() => setShakeCounter(n => n + 1)}
                />
              | (None, Some(initial)) =>
                <CreateLocationEventForm
                  location=location.fragmentRefs
                  prefilledValues=initial
                  selectedClub=?clubSelection.clubId
                  selectedActivity=?clubSelection.activityId
                  isClubFormOpen=clubSelection.isAddingClub
                  onClubFormSubmitBlocked={() => setShakeCounter(n => n + 1)}
                />
              | (None, None) =>
                <CreateLocationEventForm
                  location=location.fragmentRefs
                  selectedClub=?clubSelection.clubId
                  selectedActivity=?clubSelection.activityId
                  isClubFormOpen=clubSelection.isAddingClub
                  onClubFormSubmitBlocked={() => setShakeCounter(n => n + 1)}
                />
              }
            )
            ->Option.getOr(React.null)}
          </FramerMotion.AnimatePresence>
        </>}
      </WaitForMessages>
    </div>
  </div>
}

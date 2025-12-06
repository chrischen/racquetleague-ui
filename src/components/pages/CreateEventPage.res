%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query CreateEventPageQuery($locationId: ID!, $after: String, $first: Int, $before: String) {
    location(id: $locationId) {
      ...CreateLocationEventForm_location
    }
    ...CreateLocationEventForm_query @arguments(after: $after, first: $first, before: $before)
  }
  `)
@react.component
let make = () => {
  open Lingui.Util
  let (params, setParams) = Router.useSearchParamsFunc()
  let locationParam = params->Router.SearchParams.get("locationId")
  let clubIdParam = params->Router.SearchParams.get("clubId")
  let activitySlugParam = params->Router.SearchParams.get("activitySlug")

  let queryData = Query.use(
    ~variables={
      locationId: locationParam->Option.getOr(""),
    },
  )

  // State to hold prefilled event values from AI
  let (prefilledValues, setPrefilledValues) = React.useState(() => None)
  // State to hold AI-suggested location address for auto-search
  let (aiLocationAddress, setAiLocationAddress) = React.useState(() => None)

  // Create initial prefilled values with clubId and activitySlug from URL if present
  let initialPrefilledValues = React.useMemo2(() => {
    // Build prefilled values if we have clubId or activitySlug
    switch (clubIdParam, activitySlugParam) {
    | (Some(clubId), Some(activitySlug)) =>
      Some({
        let initial: CreateLocationEventForm.prefilledValues = {
          clubId: ?Some(clubId),
          activitySlug: ?Some(activitySlug),
        }
        initial
      })
    | (Some(clubId), None) =>
      Some({
        let initial: CreateLocationEventForm.prefilledValues = {clubId: ?Some(clubId)}
        initial
      })
    | (None, Some(activitySlug)) =>
      Some({
        let initial: CreateLocationEventForm.prefilledValues = {activitySlug: ?Some(activitySlug)}
        initial
      })
    | (None, None) => None
    }
  }, (clubIdParam, activitySlugParam))

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
  <Layout.Container>
    <Link to={"/events/create-bulk"}> {React.string("Create Bulk Events")} </Link>
    <Grid>
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
          <FormSection
            title={t`event location`}
            description={t`choose the location where this event will be held.`}>
            <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8">
              <AutocompleteLocation
                onSelected={location => {
                  setParams(prevParams => {
                    prevParams->Router.SearchParams.set("locationId", location)
                    prevParams
                  })
                  // Clear the AI location after selection
                  setAiLocationAddress(_ => None)
                }}
                autoSearchAddress=?aiLocationAddress
              />
            </div>
          </FormSection>
          <FramerMotion.AnimatePresence mode="wait">
            {queryData.location
            ->Option.map(location => <>
              {switch (prefilledValues, initialPrefilledValues) {
              | (Some(aiValues), _) =>
                // AI suggestions take precedence
                <CreateLocationEventForm
                  location=location.fragmentRefs
                  query=queryData.fragmentRefs
                  prefilledValues=aiValues
                />
              | (None, Some(initial)) =>
                // Use initial values (clubId from URL)
                <CreateLocationEventForm
                  location=location.fragmentRefs
                  query=queryData.fragmentRefs
                  prefilledValues=initial
                />
              | (None, None) =>
                // No prefilled values
                <CreateLocationEventForm
                  location=location.fragmentRefs query=queryData.fragmentRefs
                />
              }}
            </>)
            ->Option.getOr(React.null)}
          </FramerMotion.AnimatePresence>
        </>}
      </WaitForMessages>
    </Grid>
  </Layout.Container>
}

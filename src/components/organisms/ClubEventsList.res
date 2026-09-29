%%raw("import { t, plural } from '@lingui/macro'")

module Fragment = %relay(`
  fragment ClubEventsListFragment on Club
  @argumentDefinitions (
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 20 }
    afterDate: { type: "Datetime" }
    token: { type: "String" }
    level: { type: "Float" }
  )
  @refetchable(queryName: "ClubEventsListRefetchQuery") {
    id
    slug
    defaultActivity {
      id
    }
    events(
      after: $after
      first: $first
      before: $before
      afterDate: $afterDate
      token: $token
      filters: {level: $level}
    )
      @connection(key: "ClubEventsListFragment_events") {
      edges {
        node {
          id
          startDate
          timezone
          maxRsvps
          listed
          shadow
          deleted
          club { id }
          location { id }
          rsvps(first: 100) {
            edges {
              node {
                id
                listType
              }
            }
          }
          ...PkEventRow_event
        }
      }
      pageInfo { hasNextPage hasPreviousPage endCursor startCursor }
    }
  }
`)

// "Host event" in a day's availability editor normally opens the create-event
// form with that window preset. A location club's events are always open play
// at its home court, so there the same button creates the event on the spot;
// the list refetches to show it.
module CreateEventMutation = %relay(`
  mutation ClubEventsListCreateEventMutation($input: CreateEventInput!) {
    createEvent(input: $input) {
      errors {
        message
      }
      event {
        id
      }
    }
  }
`)

let ts = Lingui.UtilString.t

let mainRsvpCount = (edge: ClubEventsListFragment_graphql.Types.fragment_events_edges_node) =>
  edge.rsvps
  ->Option.flatMap(r => r.edges)
  ->Option.getOr([])
  ->Array.filterMap(e => e)
  ->Array.filterMap(e => e.node)
  ->Array.filter(n => n.listType == None || n.listType == Some(0))
  ->Array.length

let hasOpenSpots = (edge: ClubEventsListFragment_graphql.Types.fragment_events_edges_node) =>
  switch edge.maxRsvps {
  | None => true
  | Some(max) => mainRsvpCount(edge) < max
  }

module Day = {
  @react.component
  let make = (
    ~label: string,
    ~triggerLabel: string,
    ~dateDetails: string,
    ~date: Js.Date.t,
    ~events: array<ClubEventsListFragment_graphql.Types.fragment_events_edges_node>,
    ~viewerUser: option<RescriptRelay.fragmentRefs<[> #PkEventRow_user]>>,
    ~query: RescriptRelay.fragmentRefs<[> #UseProfileGate_query]>,
    ~availabilityData: PkEventsAvailabilityDay_query_graphql.Types.fragment,
    ~onAvailabilityRefetchNeeded: unit => unit,
    ~activityId: string,
    ~isLoggedIn: bool,
    ~requireProfile: (unit => unit) => unit,
    // The day, the drafted window and the level tags the host picked.
    ~onHostEvent: (string, TimeWindow.playIntent, ~tags: array<string>) => unit,
    // Club scope for the players list and heatmap.
    ~clubSlug: option<string>,
    // A location club hosts on the spot, so its editor also picks the level.
    ~showLevelPicker: bool,
    ~onEventClick: option<string => unit>=?,
    ~onHoverLocation: option<option<string> => unit>=?,
    ~selectedLocationId: option<string>=?,
  ) => {
    let isoDate = {
      let y = date->Js.Date.getFullYear->Float.toInt->Int.toString
      let m = (date->Js.Date.getMonth->Float.toInt + 1)->Int.toString->String.padStart(2, "0")
      let d = date->Js.Date.getDate->Float.toInt->Int.toString->String.padStart(2, "0")
      y ++ "-" ++ m ++ "-" ++ d
    }
    let (levelTags, setLevelTags) = React.useState(() => [LevelTagPills.allLevel])
    let hostOptions = showLevelPicker
      ? Some(
          <LevelTagPills
            selected=levelTags
            onChange={tags => setLevelTags(_ => tags)}
            legend={Lingui.Util.t`Skill level`}
          />,
        )
      : None
    // The trigger is the day's "Add to <day>" button: it opens the availability
    // editor, whose "Host event" carries the drafted window to onHostEvent.
    let renderHeader = (trigger: React.element) =>
      <div className="px-4 md:px-6 py-3 flex items-center justify-between">
        <div className="flex items-baseline gap-3">
          <h3 className="font-semibold text-gray-900 dark:text-gray-100">
            {label->React.string}
          </h3>
          <span className="font-mono text-xs text-gray-400 dark:text-gray-500">
            {(dateDetails ++
            " · " ++
            Int.toString(events->Array.filter(e => e.deleted->Option.isNone)->Array.length) ++
            " " ++
            Lingui.UtilString.plural(
              events->Array.filter(e => e.deleted->Option.isNone)->Array.length,
              {one: ts`event`, other: ts`events`},
            ))->React.string}
          </span>
        </div>
        {trigger}
      </div>
    <>
      <PkEventsAvailabilityDay
        data=availabilityData
        localDate=isoDate
        dateGroup=label
        activityId
        onRefetchNeeded=onAvailabilityRefetchNeeded
        isLoggedIn
        onCreateEvent={intent => onHostEvent(isoDate, intent, ~tags=levelTags)}
        renderHeader
        requireProfile
        triggerLabel
        triggerIcon={<Lucide.Plus size=11 />}
        ?clubSlug
        ?hostOptions
      />
      {events
      ->Array.mapWithIndex((edge, idx) => {
        let waitlistCount = switch edge.maxRsvps {
        | None => 0
        | Some(max) => Js.Math.max_int(0, mainRsvpCount(edge) - max)
        }
        <PkEventRow
          key=edge.id
          event=edge.fragmentRefs
          user=viewerUser
          isLastInGroup={idx == Array.length(events) - 1}
          waitlistCount
          query
          ?onEventClick
          ?onHoverLocation
          dimmed={selectedLocationId
          ->Option.map(selId =>
            edge.location
            ->Option.flatMap(l => Some(l.id))
            ->Option.map(lid => lid != selId)
            ->Option.getOr(false)
          )
          ->Option.getOr(false)}
        />
      })
      ->React.array}
    </>
  }
}

@react.component
let make = (
  ~events: RescriptRelay.fragmentRefs<[> #ClubEventsListFragment]>,
  ~query: RescriptRelay.fragmentRefs<[> #UseProfileGate_query | #PkEventsAvailabilityDay_query]>,
  ~viewerUser: option<RescriptRelay.fragmentRefs<[> #PkEventRow_user]>>=?,
  ~onHoverLocation: option<option<string> => unit>=?,
  ~selectedLocationId: option<string>=?,
) => {
  let {data, refetch, hasNext, isLoadingNext: _, isLoadingPrevious} = Fragment.usePagination(events)
  let allEvents = data.events->Fragment.getConnectionNodes
  let pageInfo = data.events.pageInfo
  let hasPrevious = pageInfo.hasPreviousPage

  let ctx = DrawerContext.use()

  // Availability rides in the page's root query; one fragment read is shared by
  // every Day bucket, as in PkEventsList. Sharing availability asks for more of
  // a profile than joining does, hence its own gate.
  let (availabilityData, availabilityRefetch) = PkEventsAvailabilityDay.Fragment.useRefetchable(
    query,
  )
  let availabilityGate = UseProfileGate.use(~query, ~context=ProfileModal.Availability)
  let isLoggedIn = viewerUser->Option.isSome
  let activityId =
    data.defaultActivity->Option.map(a => a.id)->Option.getOr(PlayIntentRow.defaultActivityId)
  let navigate = LangProvider.Router.useNavigate()
  let createHref = CreateEventLink.useHref()
  let (commitCreateEvent, _isCreating) = CreateEventMutation.use()
  let locationClub = LocationClub.ofSlug(data.slug)
  // Translated, so read here in render rather than as a module constant.
  let openPlayTitle = LocationClub.useOpenPlayTitle()
  let clubPrefill = CreateEventLink.useClubPrefillParams(~slug=data.slug)

  // StoreAndNetwork: the store renders (stale) data while the network response
  // brings in nodes Relay can't add to linked arrays itself.
  let onAvailabilityRefetchNeeded = () =>
    availabilityRefetch(
      ~variables=PkEventsAvailabilityDay.Fragment.makeRefetchVariables(),
      ~fetchPolicy=RescriptRelay.StoreAndNetwork,
    )->RescriptRelay.Disposable.ignore

  let onRefresh = () => {
    Js.Promise.make((~resolve, ~reject as _) => {
      let _ = refetch(
        ~variables=Fragment.makeRefetchVariables(~id=data.id),
        ~fetchPolicy=RescriptRelay.NetworkOnly,
        ~onComplete=_err => resolve(),
      )
    })
  }

  // Creates the open-play event straight from the drafted window, mirroring
  // the form's own defaults for a new event (private, 24h cancel deadline, the
  // picked level tags with their derived minimum rating) and its zone handling
  // (the browser's zone, applied to the wall-clock start; the end follows by
  // the window's length).
  let hostInstantly = (
    isoDate: string,
    intent: TimeWindow.playIntent,
    ~tags: array<string>,
    ~club: LocationClub.t,
  ) => {
    let tz = Util.Timezone.browser()
    let startDate = Util.Timezone.fromWallClock(
      isoDate ++ "T" ++ TimeWindow.hourToTime(intent.start),
      tz,
    )
    let endDate = Js.Date.fromFloat(
      startDate->Js.Date.getTime +. (intent.end -. intent.start) *. 3600000.,
    )
    commitCreateEvent(
      ~variables={
        input: {
          title: openPlayTitle,
          details: "",
          activity: activityId,
          locationId: club.homeLocationId,
          clubId: data.id,
          startDate: startDate->Util.Datetime.fromDate,
          endDate: endDate->Util.Datetime.fromDate,
          listed: false,
          timezone: tz,
          maxRsvps: club.maxPlayers,
          tags: tags->Array.filter(t => t != "rec"),
          minRating: ?EventTags.minRatingFromTags(tags),
          cancelDeadline: CreateLocationEventForm.defaultCancelDeadline,
        },
      },
      ~onCompleted=({createEvent}, _errors) =>
        switch createEvent.errors {
        | None | Some([]) => onRefresh()->ignore
        | Some(errors) =>
          errors->Array.forEach(e => Js.Console.error("Failed to host event: " ++ e.message))
        },
    )->RescriptRelay.Disposable.ignore
  }

  let onHostEvent = (isoDate: string, intent: TimeWindow.playIntent, ~tags: array<string>) =>
    switch locationClub {
    | Some(club) => hostInstantly(isoDate, intent, ~tags, ~club)
    | None =>
      navigate(
        createHref(
          [
            ("clubId", data.id),
            ("date", isoDate),
            ("startHour", intent.start->Float.toString),
            ("endHour", intent.end->Float.toString),
          ]->Array.concat(clubPrefill),
        ),
        None,
      )
    }

  let (searchParams, setSearchParams) = Router.useSearchParamsFunc()

  // The filter toolbar, as on Discover: `openSpots` is a client-side filter
  // over the loaded page, `level` re-runs the loader for a server-side match
  // against the events' level tags.
  let showOpenOnly =
    searchParams
    ->Router.ImmSearchParams.fromSearchParams
    ->Router.ImmSearchParams.get("openSpots")
    ->Option.map(v => v == "true")
    ->Option.getOr(false)
  let events = showOpenOnly ? allEvents->Array.filter(hasOpenSpots) : allEvents
  let minimumLevel =
    searchParams
    ->Router.ImmSearchParams.fromSearchParams
    ->Router.ImmSearchParams.get("level")
    ->Option.flatMap(Float.fromString)
  let onMinimumLevelChange = (value: option<float>) =>
    setSearchParams(prevParams => {
      switch value {
      | Some(v) => prevParams->Router.SearchParams.set("level", v->Js.Float.toString)
      | None => prevParams->Router.SearchParams.delete("level")
      }
      prevParams
    })
  // Only ever present as "true"; toggling off removes it so the URL stays clean.
  let onShowOpenOnlyChange = (value: bool) =>
    setSearchParams(prevParams => {
      if value {
        prevParams->Router.SearchParams.set("openSpots", "true")
      } else {
        prevParams->Router.SearchParams.delete("openSpots")
      }
      prevParams
    })
  let locationFilter =
    <EventFiltersToolbar
      filters={
        EventFiltersToolbar.showOpenOnly,
        onShowOpenOnlyChange,
        minimumLevel,
        onMinimumLevelChange,
      }
    />

  let selectedDate =
    searchParams->Router.ImmSearchParams.fromSearchParams->EventsListUtils.Filter.selectedDate

  let onSelectDate = (date: Js.Date.t) => {
    setSearchParams(prevParams => {
      EventsListUtils.Filter.ByAfterDate(date)
      ->EventsListUtils.Filter.updateParams(prevParams->Router.ImmSearchParams.fromSearchParams)
      ->Router.ImmSearchParams.toSearchParams
    })
  }

  let onClearDate = () => {
    setSearchParams(prevParams => {
      prevParams->Router.SearchParams.delete("afterDate")
      prevParams
    })
  }

  let bucketSetup = EventsListUtils.makeBucketSetup()
  let intl = ReactIntl.useIntl()

  let formatDate = (date: Js.Date.t): string =>
    intl->ReactIntl.Intl.formatDateWithOptions(
      date,
      ReactIntl.dateTimeFormatOptions(~month=#short, ~day=#numeric, ()),
    )

  // (heading, date details, date, the day's "Add to <day>" trigger). The
  // trigger is its own message per kind of day, so weekday names keep their
  // capital in English ("Add to Friday") instead of lowercasing the heading.
  let getBucketMeta = (key: string): (string, string, Js.Date.t, string) =>
    switch key {
    | "today" => (
        ts`Today`,
        formatDate(bucketSetup.dateFromOffset(0.)),
        bucketSetup.dateFromOffset(0.),
        ts`Add to today`,
      )
    | "tomorrow" => (
        ts`Tomorrow`,
        formatDate(bucketSetup.dateFromOffset(1.)),
        bucketSetup.dateFromOffset(1.),
        ts`Add to tomorrow`,
      )
    | _ =>
      let (isNextWeek, dayIndex, date) = EventsListUtils.getBucketDateDetails(
        ~setup=bucketSetup,
        key,
      )
      let n = key->Int.fromString->Option.getOr(0)
      let dayName = switch dayIndex {
      | 0 => ts`Sunday`
      | 1 => ts`Monday`
      | 2 => ts`Tuesday`
      | 3 => ts`Wednesday`
      | 4 => ts`Thursday`
      | 5 => ts`Friday`
      | 6 => ts`Saturday`
      | _ => ""
      }
      let (label, triggerLabel) = if n == -1 {
        (ts`Yesterday`, ts`Add to yesterday`)
      } else if isNextWeek {
        (ts`Next ${dayName}`, ts`Add to next ${dayName}`)
      } else {
        (dayName, ts`Add to ${dayName}`)
      }
      (label, formatDate(date), date, triggerLabel)
    }

  let eventDates =
    events->Array.filterMap(e => e.startDate->Option.map(d => d->Util.Datetime.toDate))

  let bucketEventsDict = EventsListUtils.bucketEvents(
    ~setup=bucketSetup,
    ~getStartDate={
      (e: ClubEventsListFragment_graphql.Types.fragment_events_edges_node) => e.startDate
    },
    ~filterByDate=None,
    events,
  )

  let buckets = EventsListUtils.sortBucketKeys(
    bucketEventsDict->Js.Dict.keys,
  )->Array.filterMap(key =>
    bucketEventsDict
    ->Js.Dict.get(key)
    ->Option.map(bucketEvents => {
      let (label, dateDetails, date, triggerLabel) = getBucketMeta(key)
      (
        key,
        <Day
          label
          triggerLabel
          dateDetails
          date
          events=bucketEvents
          viewerUser
          query
          availabilityData
          onAvailabilityRefetchNeeded
          activityId
          isLoggedIn
          requireProfile={availabilityGate.require}
          onHostEvent
          clubSlug=data.slug
          showLevelPicker={locationClub->Option.isSome}
          onEventClick={id => ctx.openDrawer(<PkEventDrawer eventId=id />, "/events/" ++ id)}
          ?onHoverLocation
          ?selectedLocationId
        />,
      )
    })
  )

  let totalEvents = events->Array.length

  let onPrevious = pageInfo.startCursor->Option.map(startCursor => () =>
    setSearchParams(prevParams => {
      EventsListUtils.Filter.ByBefore(startCursor)
      ->EventsListUtils.Filter.updateParams(prevParams->Router.ImmSearchParams.fromSearchParams)
      ->Router.ImmSearchParams.toSearchParams
    }))

  let onNext = pageInfo.endCursor->Option.map(endCursor => () =>
    setSearchParams(prevParams => {
      EventsListUtils.Filter.ByAfter(endCursor)
      ->EventsListUtils.Filter.updateParams(prevParams->Router.ImmSearchParams.fromSearchParams)
      ->Router.ImmSearchParams.toSearchParams
    }))

  <WaitForMessages>
    {() => <>
      <EventsListView
        totalEvents
        buckets
        weekendBucketKey=bucketSetup.weekendBucketKey
        ?selectedDate
        onSelectDate={onSelectDate}
        onClearDate={onClearDate}
        eventDates={eventDates}
        locationFilter
        hasPrevious
        isLoadingPrevious
        ?onPrevious
        hasNext
        ?onNext
        onRefresh
      />
      {availabilityGate.modal}
    </>}
  </WaitForMessages>
}

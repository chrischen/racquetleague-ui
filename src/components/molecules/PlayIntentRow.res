%%raw("import { t, plural } from '@lingui/macro'")

let ts = Lingui.UtilString.t

type userDayInterval = AvailabilityUserRow.userDayInterval
type userDayUser = AvailabilityUserRow.userDayUser
type userDay = AvailabilityUserRow.userDay

module SetAvailabilityMutation = %relay(`
  mutation PlayIntentRowSetAvailabilityMutation($input: SetAvailabilityDayInput!) {
    setAvailabilityDay(input: $input) {
      day {
        ...PlayIntentRow_availabilityDay
        id
        localDate
        user {
          id
          picture
          lineUsername
        }
        intervals {
          startHour
          endHour
        }
      }
      errors {
        message
      }
    }
  }
`)

module Fragment = %relay(`
  fragment PlayIntentRow_availabilityDay on AvailabilityDay {
    id
    localDate
    intervals {
      startHour
      endHour
    }
  }
`)

// TODO: replace with real activity ID lookup
let defaultActivityId = "Activity_414afb54-03e9-11ef-bcea-2b738de6ea61"

@react.component
let make = (
  ~localDate: string,
  ~dateGroup: string,
  ~availabilityDay: option<RescriptRelay.fragmentRefs<[> #PlayIntentRow_availabilityDay]>>=?,
  ~interestedCount: int=0,
  ~activityId: option<string>=?,
  ~clubId: option<string>=?,
  ~userDays: array<userDay>,
  ~courtAvailability: array<TimeWindowPicker.courtAvailability>=[],
  ~onAvailabilityCommitted: option<userDay> => unit,
  ~onChange: array<TimeWindowPicker.playIntent> => unit,
  ~onCreateEvent: option<unit => unit>=?,
  ~onRegisterOpenEditor: option<(unit => unit) => unit>=?,
  ~renderHeader: option<React.element => React.element>=?,
  ~isLoggedIn: bool=false,
) => {
  let (commitSetAvailability, _isMutating) = SetAvailabilityMutation.use()
  let location = UseUserLocation.use()
  let resolvedActivityId = activityId->Option.orElse(Some(defaultActivityId))

  // Compute per-hour counts from all user intervals
  let hourCounts: array<TimeWindowPicker.hourCount> = Belt.Array.makeBy(
    TimeWindowPicker.hourMax - TimeWindowPicker.hourMin,
    i => {
      let hour = TimeWindowPicker.hourMin + i
      let count = userDays->Array.reduce(0, (acc, ud) => {
        let hasHour = ud.intervals->Array.some(iv => iv.startHour <= hour && hour < iv.endHour)
        if hasHour {
          acc + 1
        } else {
          acc
        }
      })
      {TimeWindowPicker.hour, count}
    },
  )

  let maxCount = hourCounts->Array.reduce(0, (acc, hc) => Js.Math.max_int(acc, hc.count))
  let hasAnyDemand = maxCount > 0
  let demandCount = if interestedCount > 0 {
    interestedCount
  } else {
    userDays->Array.length
  }

  // Find the longest contiguous run of hours at max count
  let peak = {
    if maxCount == 0 {
      None
    } else {
      let baseHour = TimeWindowPicker.hourMin
      let totalHours = TimeWindowPicker.hourMax - baseHour
      let getCount = (hour: int) =>
        hourCounts
        ->Array.find(hc => hc.hour == hour)
        ->Option.map(hc => hc.count)
        ->Option.getOr(0)
      let bestStart = ref(-1)
      let bestLen = ref(0)
      let curStart = ref(-1)
      let curLen = ref(0)
      for i in 0 to totalHours - 1 {
        let hour = baseHour + i
        if getCount(hour) == maxCount {
          if curStart.contents == -1 {
            curStart := hour
          }
          curLen := curLen.contents + 1
          if curLen.contents > bestLen.contents {
            bestLen := curLen.contents
            bestStart := curStart.contents
          }
        } else {
          curStart := -1
          curLen := 0
        }
      }
      if bestStart.contents == -1 {
        None
      } else {
        Some((bestStart.contents, bestStart.contents + bestLen.contents))
      }
    }
  }

  let fragmentData = Fragment.useOpt(availabilityDay)
  let intents: array<TimeWindowPicker.playIntent> =
    fragmentData
    ->Option.map(d =>
      d.intervals->Array.mapWithIndex((interval, i): TimeWindowPicker.playIntent => {
        id: i,
        start: interval.startHour->Float.fromInt,
        end: interval.endHour->Float.fromInt,
      })
    )
    ->Option.getOr([])

  let (editing, setEditing) = React.useState(() => false)
  let (draft, setDraft) = React.useState(() => intents)
  let (demandListOpen, setDemandListOpen) = React.useState(() => false)

  let isActive = intents->Array.length > 0
  let dayWord = dateGroup->String.toLowerCase

  let intl = ReactIntl.useIntl()
  let {pathname} = Router.useLocation()
  let navigate = LangProvider.Router.useNavigate()
  let formatHour = (h: int): string =>
    intl->ReactIntl.Intl.formatTimeWithOptions(
      Js.Date.makeWithYMDHMS(
        ~year=2000.,
        ~month=0.,
        ~date=1.,
        ~hours=h->Float.fromInt,
        ~minutes=0.,
        ~seconds=0.,
        (),
      ),
      ReactIntl.dateTimeFormatOptions(~hour=#numeric, ()),
    )

  let openEditor = () => {
    setDraft(_ =>
      if intents->Array.length > 0 {
        intents
      } else {
        [TimeWindowPicker.defaultIntent()]
      }
    )
    setEditing(_ => true)
  }

  // Replace the draft with a court opening's window (picker band or group list).
  let useCourtSlot = (group: TimeWindowPicker.courtSlotGroup) =>
    setDraft(_ => [{id: TimeWindowPicker.wid(), start: group.start, end: group.end}])

  let openEditorRef = React.useRef(openEditor)
  openEditorRef.current = openEditor

  React.useEffect0(() => {
    switch onRegisterOpenEditor {
    | None => ()
    | Some(fn) => fn(() => openEditorRef.current())
    }
    None
  })

  let commitAvailability = (newIntents: array<TimeWindowPicker.playIntent>) => {
    let intervals: array<
      RelaySchemaAssets_graphql.input_IntervalInput,
    > = newIntents->Array.map((
      i: TimeWindowPicker.playIntent,
    ): RelaySchemaAssets_graphql.input_IntervalInput => {
      startHour: i.start->Float.toInt,
      endHour: i.end->Float.toInt,
    })
    let _ = commitSetAvailability(
      ~variables={
        input: {
          localDate,
          activityId: resolvedActivityId->Option.getOr(defaultActivityId),
          location,
          intervals,
        },
      },
      ~onCompleted=(res, _err) => {
        let updatedDay = res.setAvailabilityDay.day->Option.map((d): userDay => {
          id: d.id,
          localDate: d.localDate,
          user: d.user->Option.map(
            (u): userDayUser => {
              id: u.id,
              lineUsername: u.lineUsername,
              picture: u.picture,
            },
          ),
          intervals: d.intervals->Array.map(
            (iv): userDayInterval => {
              startHour: iv.startHour,
              endHour: iv.endHour,
            },
          ),
        })
        onAvailabilityCommitted(updatedDay)
      },
    )
    onChange(newIntents)
  }

  let commit = () => {
    commitAvailability(draft)
    setEditing(_ => false)
  }

  let sortedIntents =
    intents->Array.toSorted((a: TimeWindowPicker.playIntent, b: TimeWindowPicker.playIntent) =>
      a.start -. b.start
    )

  let presets: array<TimeWindowPicker.preset> = [
    {id: "anytime", label: ts`Anytime`, start: 9.0, end: 22.0},
    {id: "morning", label: ts`Morning`, start: 9.0, end: 12.0},
    {id: "afternoon", label: ts`Afternoon`, start: 13.0, end: 16.0},
    {id: "evening", label: ts`Evening`, start: 19.0, end: 22.0},
  ]

  let compactTrigger =
    <button
      onClick={_ =>
        if isLoggedIn {
          openEditor()
        } else {
          navigate("/oauth-login?return=" ++ pathname, None)
        }}
      className="flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-mono text-gray-500 dark:text-gray-400 hover:text-black dark:hover:text-white border border-dashed border-gray-300 dark:border-[#3a3b40] hover:border-gray-400 dark:hover:border-gray-500 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors">
      <Lucide.CalendarClock className="w-[11px] h-[11px]" />
      <span> {(ts`Play today`)->React.string} </span>
    </button>

  // Keep players, the user's availability, and court inventory in one compact
  // discovery row so court-only days still surface useful planning context.
  let availableCourtCount =
    courtAvailability->Array.reduce(0, (acc, c) => acc + c.intents->Array.length)
  let courtNoun = Lingui.UtilString.plural(
    availableCourtCount,
    {
      one: ts`${availableCourtCount->Int.toString} court available`,
      other: ts`${availableCourtCount->Int.toString} courts available`,
    },
  )
  let showDemandRow = hasAnyDemand || isActive || availableCourtCount > 0
  let othersWord = Lingui.UtilString.plural(demandCount, {one: ts`other`, other: ts`others`})
  let headline =
    if isActive {
      if demandCount > 0 {
        ts`You + ${demandCount->Int.toString} ${othersWord} looking to play`
      } else {
        ts`You're available to play`
      }
    } else if demandCount > 0 {
      Lingui.UtilString.plural(
        demandCount,
        {
          one: ts`${demandCount->Int.toString} person looking to play`,
          other: ts`${demandCount->Int.toString} people looking to play`,
        },
      )
    } else {
      courtNoun
    }

  let demandRow =
    if showDemandRow {
      <button
        onClick={_ =>
          if isLoggedIn {
            openEditor()
          } else {
            navigate("/oauth-login?return=" ++ pathname, None)
          }}
        className="w-full px-4 md:px-6 pb-2.5 flex flex-wrap items-center gap-x-2.5 gap-y-1.5 text-left group/demand">
        <div className="flex items-center -space-x-1.5 flex-shrink-0">
          {isActive
            ? <span
                title={ts`You're available`}
                className="relative z-10 inline-flex items-center justify-center w-6 h-6 rounded-full bg-[#bdf25d] text-black ring-2 ring-white dark:ring-[#222326]">
                <Lucide.Check size=11 strokeWidth=2.5 />
              </span>
            : React.null}
          {Belt.Array.slice(userDays, ~offset=0, ~len=4)
          ->Array.map(ud => {
            let name = ud.user->Option.flatMap(u => u.lineUsername)->Option.getOr("?")
            let initials = name->String.slice(~start=0, ~end=2)->String.toUpperCase
            let pictureUrl = ud.user->Option.flatMap(u => u.picture)
            let key = ud.user->Option.map(u => u.id)->Option.getOr(ud.id)
            switch pictureUrl {
            | Some(src) =>
              <img
                key
                src
                alt=name
                title=name
                className="w-6 h-6 rounded-full object-cover ring-2 ring-white dark:ring-[#222326]"
              />
            | None =>
              <span
                key
                title=name
                className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-violet-100 dark:bg-violet-900/50 text-violet-700 dark:text-violet-200 text-[9px] font-semibold ring-2 ring-white dark:ring-[#222326]">
                {initials->React.string}
              </span>
            }
          })
          ->React.array}
          {demandCount > 4
            ? <span
                className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-violet-50 dark:bg-violet-950/60 text-violet-600 dark:text-violet-300 text-[9px] font-semibold ring-2 ring-white dark:ring-[#222326]">
                {("+" ++ (demandCount - 4)->Int.toString)->React.string}
              </span>
            : React.null}
          {availableCourtCount > 0
            ? <span
                title=courtNoun
                className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-cyan-100 dark:bg-cyan-900/50 text-cyan-700 dark:text-cyan-200 ring-2 ring-white dark:ring-[#222326]">
                <Lucide.MapPin size=11 strokeWidth=2.5 />
              </span>
            : React.null}
        </div>
        <span
          className={`min-w-0 text-xs transition-colors ${isActive
              ? "text-[#3f6212] dark:text-[#bdf25d] font-medium"
              : demandCount > 0
              ? "text-violet-700 dark:text-violet-300 group-hover/demand:text-violet-900 dark:group-hover/demand:text-violet-200"
              : "text-cyan-700 dark:text-cyan-300 group-hover/demand:text-cyan-900 dark:group-hover/demand:text-cyan-200"}`}>
          {headline->React.string}
        </span>
        {availableCourtCount > 0 && (demandCount > 0 || isActive)
          ? <span
              className="inline-flex items-center gap-1 font-mono text-[10px] text-cyan-700 dark:text-cyan-300">
              <Lucide.MapPin size=10 strokeWidth=2.5 />
              {courtNoun->React.string}
            </span>
          : React.null}
        {isActive && sortedIntents->Array.length > 0
          ? <span className="flex items-center gap-1 flex-wrap">
              {sortedIntents
              ->Array.map(w =>
                <span
                  key={w.id->Int.toString}
                  className="inline-flex items-center font-mono text-[10px] px-1.5 py-0.5 rounded bg-[#bdf25d]/40 dark:bg-[#bdf25d]/25 text-[#3f6212] dark:text-[#bdf25d]">
                  {(formatHour(w.start->Float.toInt) ++ "–" ++ formatHour(w.end->Float.toInt))
                    ->React.string}
                </span>
              )
              ->React.array}
            </span>
          : React.null}
      </button>
    } else {
      React.null
    }

  let editorBlock =
    <FramerMotion.DivCss
      initial={{opacity: 0.0, height: "0"}}
      animate={{opacity: 1.0, height: "auto"}}
      exit={{opacity: 0.0, height: "0"}}
      className="overflow-hidden mx-4 md:mx-6 my-2 rounded-lg border border-[#bdf25d]/60 dark:border-[#bdf25d]/30 bg-[#bdf25d]/10 dark:bg-[#bdf25d]/5">
      <div className="px-3 py-2.5">
        <div className="flex items-center justify-between mb-2">
          <span
            className="text-[11px] font-mono tracking-wider uppercase text-[#3f6212] dark:text-[#bdf25d]">
            {(ts`When can you play ${dayWord}?`)->React.string}
          </span>
          <button
            onClick={_ => setEditing(_ => false)}
            className="text-gray-400 hover:text-gray-700 dark:hover:text-gray-200"
            title="Cancel">
            <Lucide.X size=14 />
          </button>
        </div>
        <div className="flex flex-wrap gap-1.5 mb-2.5">
          {presets
          ->Array.map(p => {
            let active = TimeWindowPicker.matchPreset(draft) === Some(p.id)
            <button
              key={p.id}
              onClick={_ =>
                setDraft(_ => [{id: TimeWindowPicker.wid(), start: p.start, end: p.end}])}
              className={`inline-flex items-baseline gap-1.5 px-2.5 py-1 text-xs font-medium rounded-md border transition-colors ${active
                  ? "bg-[#bdf25d] border-[#a3d949] text-black"
                  : "bg-white dark:bg-[#1e1f23] border-gray-200 dark:border-[#3a3b40] text-gray-700 dark:text-gray-200 hover:border-[#a3d949] hover:text-black dark:hover:text-white"}`}>
              <span> {p.label->React.string} </span>
              <span className="font-mono text-[10px] opacity-70">
                {(formatHour(p.start->Float.toInt) ++ "–" ++ formatHour(p.end->Float.toInt))
                  ->React.string}
              </span>
            </button>
          })
          ->React.array}
        </div>
        <React.Suspense
          fallback={<TimeWindowPicker
            intents=draft
            onChange={intents => setDraft(_ => intents)}
            courtAvailability
            onUseCourtSlot=useCourtSlot
          />}>
          <TimePickerWithHeatmap
            localDate
            draft
            onChange={intents => setDraft(_ => intents)}
            activityId=?resolvedActivityId
            ?clubId
            courtAvailability
            onUseCourtSlot=useCourtSlot
          />
        </React.Suspense>
        // The picker always shows the day's full context; overlap filtering is
        // summary-only.
        {userDays->Array.length > 0 || courtAvailability->Array.length > 0
          ? <div
              className="mt-2 flex flex-wrap items-center gap-x-3 gap-y-1 font-mono text-[9px] uppercase tracking-wider text-gray-500 dark:text-gray-400">
              <span className="inline-flex items-center gap-1">
                <span className="h-2 w-2 rounded-sm bg-[#bdf25d]" />
                {(ts`You`)->React.string}
              </span>
              {userDays->Array.length > 0
                ? <span className="inline-flex items-center gap-1">
                    <span className="h-2 w-2 rounded-sm bg-violet-400" />
                    {(ts`Players`)->React.string}
                  </span>
                : React.null}
              {courtAvailability->Array.length > 0
                ? <span className="inline-flex items-center gap-1">
                    <span className="h-2 w-2 rounded-sm bg-cyan-400" />
                    {(ts`Courts`)->React.string}
                  </span>
                : React.null}
            </div>
          : React.null}
        {draft->Array.length > 0
          ? <div className="mt-2 flex flex-wrap gap-1.5">
              {draft
              ->Array.toSorted((a: TimeWindowPicker.playIntent, b: TimeWindowPicker.playIntent) =>
                a.start -. b.start
              )
              ->Array.map(w =>
                <TimeRangeChip key={w.id->Int.toString} startHour=w.start endHour={w.end} />
              )
              ->React.array}
            </div>
          : React.null}
        {
          // Court openings that overlap the user's drafted time windows.
          let overlappingCourts = TimeWindowPicker.filterCourtAvailabilityByOverlap(
            courtAvailability,
            draft,
          )
          overlappingCourts->Array.length > 0
            ? <div className="mt-2">
                <CourtAvailabilityGroups
                  title={ts`Courts available during your time`}
                  courtAvailability=overlappingCourts
                  onUseSlot=useCourtSlot
                />
              </div>
            : React.null
        }
        {userDays->Array.length > 0
          ? <div className="mt-2">
              <button
                onClick={_ => setDemandListOpen(v => !v)}
                className="w-full flex items-center justify-between gap-2 text-[11px] text-violet-700 dark:text-violet-300 hover:text-violet-900 dark:hover:text-violet-200 transition-colors">
                <span className="inline-flex items-center gap-1.5 font-medium">
                  <Lucide.Users size=11 />
                  {(Lingui.UtilString.plural(
                    userDays->Array.length,
                    {
                      one: ts`${userDays->Array.length->Int.toString} person`,
                      other: ts`${userDays->Array.length->Int.toString} people`,
                    },
                  ) ++
                  peak
                  ->Option.map(((s, e)) => ts` · peak ${formatHour(s)}–${formatHour(e)}`)
                  ->Option.getOr(""))->React.string}
                </span>
                <Lucide.ChevronDown
                  size=13 className={`transition-transform ${demandListOpen ? "rotate-180" : ""}`}
                />
              </button>
              <AvailabilityDemandList userDays open_=demandListOpen innerClassName="space-y-1.5 mt-2" />
            </div>
          : React.null}
        <div className="mt-3">
          <div className="flex items-center justify-between gap-2 flex-wrap">
            {isActive
              ? <button
                  onClick={_ => {
                    commitAvailability([])
                    setDraft(_ => [])
                    setEditing(_ => false)
                  }}
                  className="px-2.5 py-1 text-xs font-medium rounded-md text-gray-600 dark:text-gray-300 hover:text-red-600 dark:hover:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 transition-colors">
                  {(ts`Remove all`)->React.string}
                </button>
              : <span />}
            <div className="flex items-center gap-1.5">
              {onCreateEvent
              ->Option.map(cb =>
                <button
                  onClick={_ => {
                    setEditing(_ => false)
                    cb()
                  }}
                  disabled={draft->Array.length !== 1}
                  title={if draft->Array.length !== 1 {
                    ts`Pick one time window to host an event`
                  } else {
                    ts`Host an event at this time`
                  }}
                  className="inline-flex items-center gap-1 px-3 py-1 text-xs font-semibold rounded-md border border-gray-300 dark:border-[#3a3b40] text-gray-800 dark:text-gray-200 hover:border-gray-400 dark:hover:border-gray-500 hover:bg-white dark:hover:bg-[#2a2b30] transition-colors disabled:opacity-40 disabled:cursor-not-allowed">
                  <Lucide.Plus size=12 strokeWidth=2.5 />
                  {(ts`Host event`)->React.string}
                </button>
              )
              ->Option.getOr(React.null)}
              <button
                onClick={_ => commit()}
                disabled={draft->Array.length === 0}
                className="inline-flex items-center gap-1 px-3 py-1 text-xs font-semibold rounded-md bg-[#bdf25d] hover:bg-[#aee050] text-black transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                <Lucide.Check size=12 strokeWidth=2.5 />
                {(ts`Mark available`)->React.string}
              </button>
            </div>
          </div>
        </div>
      </div>
    </FramerMotion.DivCss>

  let activeBlock =
    <div
      className="mx-4 md:mx-6 my-2 rounded-lg border border-[#bdf25d]/70 dark:border-[#bdf25d]/40 bg-[#bdf25d]/15 dark:bg-[#bdf25d]/10 overflow-hidden">
      <div className="px-3 py-2 flex items-center gap-2.5">
        <div
          className="w-6 h-6 rounded-full bg-[#bdf25d] flex items-center justify-center flex-shrink-0">
          <Lucide.Sparkles size=12 strokeWidth=2.5 className="text-black" />
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-sm text-gray-900 dark:text-gray-100 font-medium leading-tight">
            {(ts`You want to play ${dayWord}`)->React.string}
          </div>
          <div className="flex flex-wrap items-center gap-1.5 mt-1">
            {sortedIntents
            ->Array.map(w =>
              <TimeRangeChip
                key={w.id->Int.toString}
                startHour=w.start
                endHour={w.end}
                className="inline-flex items-center"
              />
            )
            ->React.array}
          </div>
          {demandCount > 0
            ? <button
                onClick={_ => setDemandListOpen(v => !v)}
                className="text-[11px] text-violet-600 dark:text-violet-400 mt-1 flex items-center gap-1 hover:text-violet-800 dark:hover:text-violet-200 transition-colors">
                <Lucide.Users size=10 />
                {(Lingui.UtilString.plural(
                  demandCount,
                  {
                    one: ts`${demandCount->Int.toString} person wants to play`,
                    other: ts`${demandCount->Int.toString} people want to play`,
                  },
                ) ++
                peak
                ->Option.map(((s, e)) => ts` · peak ${formatHour(s)}–${formatHour(e)}`)
                ->Option.getOr(""))->React.string}
                <Lucide.ChevronDown
                  size=11
                  className={`transition-transform ${demandListOpen ? "rotate-180" : ""}`}
                />
              </button>
            : React.null}
        </div>
        <button
          onClick={_ => openEditor()}
          className="text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-white p-1 flex-shrink-0"
          title="Change times">
          <Lucide.Pencil size=12 />
        </button>
        <button
          onClick={_ => commitAvailability([])}
          className="text-gray-400 hover:text-red-600 dark:text-gray-500 dark:hover:text-red-400 p-1 flex-shrink-0"
          title="Remove all">
          <Lucide.X size=14 />
        </button>
      </div>
      <AvailabilityDemandList userDays open_=demandListOpen />
    </div>

  switch renderHeader {
  | Some(headerFn) =>
    <div className="flex flex-col">
      {if editing { headerFn(React.null) } else { headerFn(compactTrigger) }}
      {if editing { React.null } else { demandRow }}
      {if editing { editorBlock } else { React.null }}
    </div>
  | None =>
    if editing {
      editorBlock
    } else if isActive {
      activeBlock
    } else {
      demandRow
    }
  }
}

%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util

let ts = Lingui.UtilString.t

// ─── DOM bindings ────────────────────────────────────────────────────────────

type keyboardEv
@get external keyEvKey: keyboardEv => string = "key"
@val @scope("window")
external addKeyListener: (string, keyboardEv => unit) => unit = "addEventListener"
@val @scope("window")
external removeKeyListener: (string, keyboardEv => unit) => unit = "removeEventListener"

type dayOption = {
  id: string,
  label: string,
  sub: string,
  localDate: string,
}

// ─── Component ───────────────────────────────────────────────────────────────

@react.component
let make = (
  ~isOpen: bool,
  ~onClose: unit => unit,
  ~onMarkAvailable: (string, array<TimeWindow.playIntent>) => unit,
  ~onCreateEvent: (string, TimeWindow.playIntent) => unit,
) => {
  let intl = ReactIntl.useIntl()

  let buildDayOptions = () => {
    let now = Js.Date.make()
    Belt.Array.makeBy(4, i => {
      let d = Js.Date.fromFloat(now->Js.Date.getTime +. Float.fromInt(i * 86400000))
      let y = d->Js.Date.getFullYear->Float.toInt->Int.toString
      let mo = (d->Js.Date.getMonth->Float.toInt + 1)->Int.toString->String.padStart(2, "0")
      let day = d->Js.Date.getDate->Float.toInt->Int.toString->String.padStart(2, "0")
      let localDate = y ++ "-" ++ mo ++ "-" ++ day
      let dateStr =
        intl->ReactIntl.Intl.formatDateWithOptions(
          d,
          ReactIntl.dateTimeFormatOptions(~month=#numeric, ~day=#numeric, ()),
        )
      let weekdayStr =
        intl->ReactIntl.Intl.formatDateWithOptions(
          d,
          ReactIntl.dateTimeFormatOptions(~weekday=#short, ()),
        )
      let (label, sub) = switch i {
      | 0 => (ts`Today`, weekdayStr ++ " · " ++ dateStr)
      | 1 => (ts`Tomorrow`, weekdayStr ++ " · " ++ dateStr)
      | _ => (weekdayStr, dateStr)
      }
      {id: localDate, label, sub, localDate}
    })
  }

  let dayOpts = buildDayOptions()

  let (localDate, setLocalDate) = React.useState(() => (dayOpts->Array.getUnsafe(0): dayOption).id)
  let (draft, setDraft) = React.useState(() => [TimeWindowPicker.defaultIntent()])

  let presets: array<TimeWindowPicker.preset> = [
    {id: "anytime", label: ts`Anytime`, start: 9.0, end: 22.0},
    {id: "morning", label: ts`Morning`, start: 9.0, end: 12.0},
    {id: "afternoon", label: ts`Afternoon`, start: 13.0, end: 16.0},
    {id: "evening", label: ts`Evening`, start: 19.0, end: 22.0},
  ]

  // Reset state when modal opens
  React.useEffect1(() => {
    if isOpen {
      let opts = buildDayOptions()
      setLocalDate(_ => (opts->Array.getUnsafe(0): dayOption).id)
      setDraft(_ => [TimeWindowPicker.defaultIntent()])
    }
    None
  }, [isOpen])

  // Close on Escape
  let onCloseRef = React.useRef(onClose)
  onCloseRef.current = onClose
  React.useEffect1(() => {
    if !isOpen {
      None
    } else {
      let onKey = (e: keyboardEv) =>
        if e->keyEvKey === "Escape" {
          onCloseRef.current()
        }
      addKeyListener("keydown", onKey)
      Some(() => removeKeyListener("keydown", onKey))
    }
  }, [isOpen])

  let sortedDraft =
    draft->Array.toSorted((a: TimeWindow.playIntent, b: TimeWindow.playIntent) =>
      a.start -. b.start
    )
  let canHost = draft->Array.length === 1
  let canCommit = draft->Array.length > 0

  let handleMarkAvailable = _ => {
    onMarkAvailable(localDate, draft)
    onClose()
  }

  let handleHost = _ => {
    if canHost {
      onCreateEvent(localDate, draft->Array.getUnsafe(0))
      onClose()
    }
  }

  <WaitForMessages>
    {_ =>
      <FramerMotion.AnimatePresence>
        {isOpen
          ? <>
              <FramerMotion.DivCss
                key="backdrop"
                initial={{opacity: 0.0}}
                animate={{opacity: 1.0}}
                exit={{opacity: 0.0}}
                transition={{duration: 0.18}}
                onClick={_ => onClose()}
                className="fixed inset-0 z-40 bg-black/40"
              />
              <div
                key="positioner"
                className="fixed z-50 inset-0 flex items-stretch md:items-center justify-center pt-16 pb-[calc(env(safe-area-inset-bottom)+72px)] px-3 md:p-4 pointer-events-none">
                <FramerMotion.DivCss
                  key="modal"
                  initial={{opacity: 0.0, y: 16.0, scale: 0.98}}
                  animate={{opacity: 1.0, y: 0.0, scale: 1.0}}
                  exit={{opacity: 0.0, y: 10.0, scale: 0.98}}
                  transition={{type_: "spring", stiffness: 500, damping: 35}}
                  role="dialog"
                  \"aria-modal"="true"
                  \"aria-labelledby"="new-plan-title"
                  className="pointer-events-auto w-full md:w-[min(560px,calc(100vw-2rem))] max-h-full md:max-h-[90vh] bg-white dark:bg-[#1e1f23] rounded-xl border border-gray-200 dark:border-[#2a2b30] shadow-2xl overflow-hidden flex flex-col">
                  // Header
                  <div
                    className="px-4 py-3 border-b border-gray-100 dark:border-[#2a2b30] flex items-center justify-between flex-shrink-0">
                    <div>
                      <div
                        className="font-mono text-[10px] tracking-wider text-gray-400 dark:text-gray-500 uppercase">
                        {t`New plan`}
                      </div>
                      <h2
                        id="new-plan-title"
                        className="text-base font-semibold text-gray-900 dark:text-gray-100">
                        {t`When do you want to play?`}
                      </h2>
                    </div>
                    <button
                      onClick={_ => onClose()}
                      className="p-1 rounded-md text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-[#2a2b30] transition-colors"
                      ariaLabel="Close">
                      <Lucide.X size=16 />
                    </button>
                  </div>
                  // Body
                  <div className="flex-1 overflow-y-auto px-4 py-3 space-y-4">
                    // Step 1 — Day
                    <section>
                      <div className="flex items-center gap-1.5 mb-2">
                        <span
                          className="font-mono text-[10px] tracking-wider text-gray-400 dark:text-gray-500 uppercase">
                          {t`1 · Day`}
                        </span>
                      </div>
                      <div className="grid grid-cols-4 gap-1.5">
                        {dayOpts
                        ->Array.map(d => {
                          let active = localDate === d.id
                          <button
                            key={d.id}
                            onClick={_ => setLocalDate(_ => d.id)}
                            className={`flex flex-col items-center justify-center py-2 rounded-md border text-center transition-colors ${active
                                ? "bg-[#bdf25d] border-[#a3d949] text-black"
                                : "bg-white dark:bg-[#1e1f23] border-gray-200 dark:border-[#3a3b40] text-gray-700 dark:text-gray-200 hover:border-[#a3d949] hover:text-black dark:hover:text-white"}`}>
                            <span className="text-sm font-semibold"> {React.string(d.label)} </span>
                            <span
                              className={`font-mono text-[10px] mt-0.5 ${active
                                  ? "text-black/70"
                                  : "text-gray-400 dark:text-gray-500"}`}>
                              {React.string(d.sub)}
                            </span>
                          </button>
                        })
                        ->React.array}
                      </div>
                    </section>
                    // Step 2 — Time
                    <section>
                      <div className="flex items-center gap-1.5 mb-2">
                        <span
                          className="font-mono text-[10px] tracking-wider text-gray-400 dark:text-gray-500 uppercase">
                          {t`2 · Time`}
                        </span>
                      </div>
                      <div className="flex flex-wrap gap-1.5 mb-2.5">
                        {presets
                        ->Array.map(p => {
                          let active = TimeWindowPicker.matchPreset(draft) === Some(p.id)
                          <button
                            key={p.id}
                            onClick={_ =>
                              setDraft(_ => [
                                {id: TimeWindowPicker.wid(), start: p.start, end: p.end},
                              ])}
                            className={`inline-flex items-baseline gap-1.5 px-2.5 py-1 text-xs font-medium rounded-md border transition-colors ${active
                                ? "bg-[#bdf25d] border-[#a3d949] text-black"
                                : "bg-white dark:bg-[#1e1f23] border-gray-200 dark:border-[#3a3b40] text-gray-700 dark:text-gray-200 hover:border-[#a3d949] hover:text-black dark:hover:text-white"}`}>
                            <span> {React.string(p.label)} </span>
                            <span className="font-mono text-[10px] opacity-70">
                              {(intl->ReactIntl.Intl.formatTimeWithOptions(
                                Js.Date.makeWithYMDHMS(
                                  ~year=2000.,
                                  ~month=0.,
                                  ~date=1.,
                                  ~hours=p.start,
                                  ~minutes=0.,
                                  ~seconds=0.,
                                  (),
                                ),
                                ReactIntl.dateTimeFormatOptions(~hour=#numeric, ()),
                              ) ++
                              "–" ++
                              intl->ReactIntl.Intl.formatTimeWithOptions(
                                Js.Date.makeWithYMDHMS(
                                  ~year=2000.,
                                  ~month=0.,
                                  ~date=1.,
                                  ~hours=p.end,
                                  ~minutes=0.,
                                  ~seconds=0.,
                                  (),
                                ),
                                ReactIntl.dateTimeFormatOptions(~hour=#numeric, ()),
                              ))->React.string}
                            </span>
                          </button>
                        })
                        ->React.array}
                      </div>
                      <React.Suspense
                        fallback={<TimeWindowPicker
                          intents=draft onChange={ws => setDraft(_ => ws)}
                        />}>
                        <TimePickerWithHeatmap localDate draft onChange={ws => setDraft(_ => ws)} />
                      </React.Suspense>
                    </section>
                    // Step 3 — Outcome
                    <section>
                      <div className="flex items-center gap-1.5 mb-2">
                        <span
                          className="font-mono text-[10px] tracking-wider text-gray-400 dark:text-gray-500 uppercase">
                          {t`3 · What kind?`}
                        </span>
                      </div>
                      <div className="grid sm:grid-cols-2 gap-2">
                        <button
                          onClick=handleMarkAvailable
                          disabled={!canCommit}
                          className="group flex flex-col items-start text-left p-3 rounded-lg border-2 border-[#bdf25d]/70 dark:border-[#bdf25d]/40 bg-[#bdf25d]/15 dark:bg-[#bdf25d]/10 hover:bg-[#bdf25d]/25 dark:hover:bg-[#bdf25d]/20 hover:border-[#bdf25d] transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                          <div className="flex items-center gap-1.5 mb-1">
                            <div
                              className="w-5 h-5 rounded-full bg-[#bdf25d] flex items-center justify-center">
                              <Lucide.Sparkles size=11 strokeWidth=2.5 className="text-black" />
                            </div>
                            <span
                              className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                              {t`Mark available`}
                            </span>
                          </div>
                          <p className="text-[11px] text-gray-600 dark:text-gray-400 leading-snug">
                            {t`Tell others you're down to play. Players with overlapping times can invite you.`}
                          </p>
                          <span
                            className="inline-flex items-center gap-1 mt-2 font-mono text-[10px] font-semibold text-[#3f6212] dark:text-[#bdf25d] group-hover:gap-1.5 transition-all">
                            <Lucide.Check size=11 strokeWidth=2.5 />
                            {t`Save`}
                          </span>
                        </button>
                        <button
                          onClick=handleHost
                          disabled={!canHost}
                          title={!canHost
                            ? Lingui.UtilString.t`Select exactly one time window to host an event`
                            : ""}
                          className="group flex flex-col items-start text-left p-3 rounded-lg border-2 border-gray-200 dark:border-[#3a3b40] bg-white dark:bg-[#1e1f23] hover:bg-gray-50 dark:hover:bg-[#2a2b30] hover:border-gray-400 dark:hover:border-gray-500 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                          <div className="flex items-center gap-1.5 mb-1">
                            <div
                              className="w-5 h-5 rounded-full bg-gray-100 dark:bg-[#2a2b30] border border-gray-200 dark:border-[#3a3b40] flex items-center justify-center">
                              <Lucide.Plus
                                size=11 strokeWidth=2.5 className="text-gray-700 dark:text-gray-300"
                              />
                            </div>
                            <span
                              className="text-sm font-semibold text-gray-900 dark:text-gray-100">
                              {t`Host an event`}
                            </span>
                          </div>
                          <p className="text-[11px] text-gray-600 dark:text-gray-400 leading-snug">
                            {t`Create a hosted event at this time. Others can join, you pick venue and rules.`}
                          </p>
                          <span
                            className="inline-flex items-center gap-1 mt-2 font-mono text-[10px] font-semibold text-gray-700 dark:text-gray-300 group-hover:gap-1.5 transition-all">
                            {t`Continue`}
                            <Lucide.ArrowRight size=11 strokeWidth=2.5 />
                          </span>
                        </button>
                      </div>
                      {!canHost && draft->Array.length > 1
                        ? <p
                            className="text-[10px] text-amber-700 dark:text-amber-400 mt-1.5 font-mono">
                            {t`Hosting an event needs exactly one time window — pick one.`}
                          </p>
                        : React.null}
                    </section>
                  </div>
                </FramerMotion.DivCss>
              </div>
            </>
          : React.null}
      </FramerMotion.AnimatePresence>}
  </WaitForMessages>
}

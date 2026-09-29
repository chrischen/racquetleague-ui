%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// The "New plan" modal from Magic Patterns (NewPlanModal with its
// NewPlanIntentChooser), opened by the top bar's New event button and the
// mobile tab bar's New. Creating an event by hand hands over to
// CreateEventModal; the rest explains the other way in, sending a court
// booking email that the backend's inbox turns into an unlisted event (see
// ReservationImport there), and links the calendar feed those events land in.

module Query = %relay(`
  query NewPlanChooserModalQuery {
    viewer {
      eventsForwardingAddress
      eventsInboxAddress
      user {
        id
        email
      }
    }
  }
`)

@val @scope(("navigator", "clipboard"))
external writeText: string => promise<unit> = "writeText"

module CopyableAddress = {
  @react.component
  let make = (~address: string, ~copied: bool, ~onCopy: string => unit) => {
    let ts = Lingui.UtilString.t
    <span className="inline-flex max-w-full items-center gap-1 align-middle">
      <code
        title=address
        className="max-w-[210px] truncate rounded bg-gray-100 px-1.5 py-0.5 font-mono text-xs font-semibold text-gray-800 dark:bg-[#191a1d] dark:text-gray-100">
        {address->React.string}
      </code>
      <button
        type_="button"
        onClick={_ => onCopy(address)}
        className="inline-flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-md text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:hover:bg-[#34353a] dark:hover:text-white"
        ariaLabel={ts`Copy ${address}`}>
        {copied
          ? <Lucide.Check size=14 \"aria-hidden"="true" />
          : <Lucide.Copy size=14 \"aria-hidden"="true" />}
      </button>
    </span>
  }
}

module StepNumber = {
  @react.component
  let make = (~children: React.element) =>
    <span
      className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-[#bdf25d] font-mono text-xs font-bold text-black">
      children
    </span>
}

let stepTextClass = "min-w-0 text-sm font-medium leading-relaxed text-gray-800 dark:text-gray-100"

// The steps need the viewer's addresses, so they are fetched when the modal
// opens rather than with every page's layout query. `frame` wraps them in the
// guide's section; signed out there are no steps, so no section either.
module EmailSteps = {
  @react.component
  let make = (~frame: React.element => React.element) => {
    let ts = Lingui.UtilString.t
    let {viewer} = Query.use(~variables=(), ~fetchPolicy=RescriptRelay.StoreOrNetwork)
    let (copiedAddress, setCopiedAddress) = React.useState((): option<string> => None)
    let (calendarSynced, setCalendarSynced) = React.useState(() => false)
    let (calendarMenuOpen, setCalendarMenuOpen) = React.useState(() => false)

    React.useEffect(() =>
      copiedAddress->Option.map(_ => {
        let timer = setTimeout(() => setCopiedAddress(_ => None), 1600)
        () => clearTimeout(timer)
      })
    , [copiedAddress])

    let copy = async address =>
      try {
        await writeText(address)
        setCopiedAddress(_ => Some(address))
      } catch {
      | _ => setCopiedAddress(_ => None)
      }
    let copyable = address =>
      <CopyableAddress
        address copied={copiedAddress == Some(address)} onCopy={a => copy(a)->ignore}
      />

    switch viewer {
    | Some({user: Some(user), eventsForwardingAddress, eventsInboxAddress}) =>
      frame(<>
        <li className="flex gap-3 p-4">
          <StepNumber> {"1"->React.string} </StepNumber>
          {
            let yourEmail = Lingui.slot("yourEmail")
            let emailElement =
              <strong className="break-words font-semibold">
                {user.email->Option.getOr("")->React.string}
              </strong>
            <div className="min-w-0 flex-1 space-y-3">
              <div className="flex items-start gap-2">
                <Lucide.Forward
                  size=16 className="mt-0.5 flex-shrink-0 text-gray-400" \"aria-hidden"="true"
                />
                <p className=stepTextClass>
                  {
                    let forwardingAddress = Lingui.slot("forwardingAddress")
                    Lingui.fillSlots(
                      ts`Forward your booking confirmation to ${forwardingAddress} from your email ${yourEmail}.`,
                      [
                        ("forwardingAddress", copyable(eventsForwardingAddress)),
                        ("yourEmail", emailElement),
                      ],
                    )
                  }
                </p>
              </div>
              {eventsInboxAddress
              ->Option.map(inboxAddress =>
                <div className="flex items-start gap-2">
                  <Lucide.AtSign
                    size=16 className="mt-0.5 flex-shrink-0 text-gray-400" \"aria-hidden"="true"
                  />
                  <p className=stepTextClass>
                    {
                      let bookingAddress = Lingui.slot("bookingAddress")
                      Lingui.fillSlots(
                        ts`Or use this email ${bookingAddress} when booking. We’ll forward the confirmation to ${yourEmail}.`,
                        [("bookingAddress", copyable(inboxAddress)), ("yourEmail", emailElement)],
                      )
                    }
                  </p>
                </div>
              )
              ->Option.getOr(React.null)}
              <p
                className="rounded-lg bg-gray-50 px-3 py-2.5 text-xs leading-relaxed text-gray-600 dark:bg-[#191a1d] dark:text-gray-300">
                {t`You can include any additional event details like the level, max players, price, etc. in the email that you forward.`}
              </p>
            </div>
          }
        </li>
        <li className="flex gap-3 p-4">
          <StepNumber> {"2"->React.string} </StepNumber>
          <div className="min-w-0 flex-1">
            <div className="flex items-start gap-2">
              <Lucide.CalendarDays
                size=17 className="mt-0.5 flex-shrink-0 text-gray-400" \"aria-hidden"="true"
              />
              <div className="min-w-0">
                <p className=stepTextClass>
                  {t`Sync your Pkuru calendar so new events appear automatically in your calendar app.`}
                </p>
                // Apple and Google, as in AddToCalendar. They open inline rather
                // than in a popover: the dialog's Radix layer blocks pointer
                // events outside itself, and the popover package bundles a
                // different copy of that layer, so a portalled menu is dead.
                <button
                  type_="button"
                  ariaExpanded=calendarMenuOpen
                  onClick={_ => setCalendarMenuOpen(isOpen => !isOpen)}
                  className={`mt-3 inline-flex h-9 items-center gap-2 rounded-lg px-3 text-sm font-semibold transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 ${calendarSynced
                      ? "bg-[#bdf25d]/20 text-[#4d6f12] dark:text-[#bdf25d]"
                      : "bg-[#bdf25d] text-black hover:bg-[#aee050]"}`}>
                  {calendarSynced
                    ? <Lucide.CalendarCheck size=16 \"aria-hidden"="true" />
                    : <Lucide.CalendarDays size=16 \"aria-hidden"="true" />}
                  {calendarSynced ? t`Calendar synced` : t`Sync calendar`}
                </button>
                {calendarMenuOpen
                  ? <div
                      className="mt-2 w-full max-w-[16rem] rounded-xl border border-gray-200 bg-white p-1 shadow-sm dark:border-[#3a3b40] dark:bg-[#1e1f23]">
                      {AddToCalendar.providers(user.id)
                      ->Array.map(provider =>
                        <a
                          key=provider.label
                          href=provider.url
                          target=?{provider.url->String.startsWith("https:")
                            ? Some("_blank")
                            : None}
                          rel="noopener noreferrer"
                          onClick={_ => {
                            setCalendarSynced(_ => true)
                            setCalendarMenuOpen(_ => false)
                          }}
                          className="flex items-center gap-2.5 rounded-lg px-2.5 py-2 text-sm font-medium text-gray-800 transition-colors hover:bg-gray-100 focus:bg-gray-100 focus:outline-none dark:text-gray-100 dark:hover:bg-[#2a2b30] dark:focus:bg-[#2a2b30]">
                          <span
                            className="flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-full bg-purple-500 text-[11px] font-semibold text-white">
                            {provider.initials->React.string}
                          </span>
                          {provider.label->React.string}
                        </a>
                      )
                      ->React.array}
                    </div>
                  : React.null}
              </div>
            </div>
          </div>
        </li>
      </>)
    | _ => React.null
    }
  }
}

@react.component
let make = (~onClose: unit => unit, ~onCreateEvent: unit => unit) => {
  let ts = Lingui.UtilString.t
  let emailGuide = steps =>
    <section
      ariaLabelledby="email-event-guide-title"
      className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-[#3a3b40] dark:bg-[#222326]">
      <header className="border-b border-gray-100 px-4 py-3.5 dark:border-[#34353a]">
        <div className="flex items-center gap-2.5">
          <span
            className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg bg-gray-100 text-gray-600 dark:bg-[#2a2b30] dark:text-gray-300">
            <Lucide.Mail size=16 \"aria-hidden"="true" />
          </span>
          <h3
            id="email-event-guide-title"
            className="text-base font-semibold text-gray-900 dark:text-gray-100">
            {t`Create events by email`}
          </h3>
        </div>
      </header>
      <ol className="divide-y divide-gray-100 dark:divide-[#34353a]"> steps </ol>
      <p
        className="border-t border-[#94c93a]/25 bg-[#bdf25d]/10 px-4 py-3 text-xs leading-relaxed text-gray-700 dark:border-[#bdf25d]/15 dark:bg-[#bdf25d]/[0.06] dark:text-gray-300">
        {
          let myEvents = Lingui.slot("myEvents")
          Lingui.fillSlots(
            ts`Events are added privately to ${myEvents}. Make an event public whenever you need to find players.`,
            [("myEvents", <strong> {t`My Events`} </strong>)],
          )
        }
      </p>
    </section>
  <RouteModal
    eyebrow={t`New plan`}
    title={t`Create an event`}
    description={t`Create an event yourself, or from a court booking email.`}
    onClose>
    <div className="space-y-5">
      <button
        type_="button"
        onClick={_ => onCreateEvent()}
        className="group flex w-full items-center gap-3 rounded-xl border border-[#94c93a] bg-[#bdf25d] p-4 text-left text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2">
        <span
          className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-black/10">
          <Lucide.CalendarPlus size=19 \"aria-hidden"="true" />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block text-sm font-semibold"> {t`Create Event Manually`} </span>
          <span className="mt-0.5 block text-xs leading-relaxed text-black/65">
            {t`Enter the event details yourself or ask the assistant to fill them in.`}
          </span>
        </span>
        <Lucide.ArrowRight
          size=17
          className="flex-shrink-0 transition-transform duration-150 ease-[cubic-bezier(0.23,1,0.32,1)] group-hover:translate-x-0.5"
          \"aria-hidden"="true"
        />
      </button>
      <React.Suspense
        fallback={emailGuide(
          <li className="p-4">
            <div className="h-24 animate-pulse rounded-lg bg-gray-100 dark:bg-[#2a2b30]" />
          </li>,
        )}>
        <EmailSteps frame=emailGuide />
      </React.Suspense>
    </div>
  </RouteModal>
}

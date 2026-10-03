%%raw("import { t } from '@lingui/macro'")

// The note that goes out with an invite, delivered as a private message the
// invitee can reply to. Send stays disabled until the note passes
// InviteNote.check: long enough to say something, and not a copy of the
// previous note (`previousMessage`, held by whoever sends the invites). Shared
// by the inline chip menu and the swipe deck, and portalled above both (the
// deck itself sits at z-[70]).

let ts = Lingui.UtilString.t

@val @scope(("window", "document")) external documentBody: Dom.element = "body"
@val @scope("document") external activeElement: Js.Nullable.t<Dom.element> = "activeElement"
@send external focusEl: Dom.element => unit = "focus"

type keyboardEv
@get external keyEvKey: keyboardEv => string = "key"
@val @scope("window")
external addKeyListener: (string, keyboardEv => unit) => unit = "addEventListener"
@val @scope("window")
external removeKeyListener: (string, keyboardEv => unit) => unit = "removeEventListener"

let maxLength = 300

@react.component
let make = (
  ~playerName: string,
  ~eventTitle: string,
  ~submitting: bool=false,
  // The note sent with the previous invite, which this one may not repeat.
  ~previousMessage: option<string>=?,
  ~onSubmit: string => unit,
  ~onCancel: unit => unit,
) => {
  let (message, setMessage) = React.useState(() => "")
  let textareaRef = React.useRef(Js.Nullable.null)

  let trimmed = message->String.trim
  let problem = InviteNote.check(~message, ~previous=previousMessage)
  let canSend = problem->Option.isNone && !submitting

  // Typing a note per player is the slow part of a swipe run, so offer a few
  // openers to edit rather than forcing a blank page each time.
  let suggestions = [
    ts`We're short a player — can you make it?`,
    ts`Thought you'd be a good fit for this one.`,
    ts`Come play with us!`,
  ]

  React.useEffect0(() => {
    let previouslyFocused = activeElement->Js.Nullable.toOption
    textareaRef.current->Js.Nullable.toOption->Option.forEach(focusEl)
    Some(
      () => {
        let _ = Js.Global.setTimeout(() => previouslyFocused->Option.forEach(focusEl), 0)
      },
    )
  })

  let onCancelRef = React.useRef(onCancel)
  onCancelRef.current = onCancel
  React.useEffect0(() => {
    let onKey = (e: keyboardEv) =>
      if e->keyEvKey === "Escape" {
        onCancelRef.current()
      }
    addKeyListener("keydown", onKey)
    Some(() => removeKeyListener("keydown", onKey))
  })

  let submit = () =>
    if canSend {
      onSubmit(trimmed)
    }

  ReactDOM.createPortal(
    <div className="fixed inset-0 z-[80] flex items-end sm:items-center justify-center">
      <div
        className="absolute inset-0 bg-black/40"
        onClick={_ => onCancel()}
        ariaHidden=true
      />
      <div
        role="dialog"
        ariaModal=true
        ariaLabelledby="invite-message-title"
        className="relative w-full sm:max-w-md rounded-t-2xl sm:rounded-2xl border border-gray-200 dark:border-[#3a3b40] bg-white dark:bg-[#1e1f23] shadow-xl p-5">
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="min-w-0">
            <h2
              id="invite-message-title"
              className="text-sm font-semibold text-gray-900 dark:text-gray-100">
              {(ts`Invite ${playerName}`)->React.string}
            </h2>
            <p className="mt-0.5 font-mono text-[10px] text-gray-500 dark:text-gray-400 truncate">
              {eventTitle->React.string}
            </p>
          </div>
          <button
            type_="button"
            onClick={_ => onCancel()}
            className="-mr-1 -mt-1 rounded-lg p-1.5 text-gray-400 hover:bg-gray-100 hover:text-gray-900 dark:hover:bg-[#2a2b30] dark:hover:text-gray-100 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500"
            ariaLabel={ts`Cancel invite`}>
            <Lucide.X size=16 \"aria-hidden"="true" />
          </button>
        </div>
        <textarea
          ref={ReactDOM.Ref.domRef(textareaRef)}
          value=message
          rows=3
          maxLength
          onChange={e => setMessage(_ => ReactEvent.Form.target(e)["value"])}
          placeholder={ts`Add a personal note — they'll see this in their invite.`}
          className="w-full resize-none rounded-lg border border-gray-200 dark:border-[#3a3b40] bg-white dark:bg-[#222326] px-3 py-2 text-sm text-gray-900 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-violet-500"
        />
        <div className="mt-2 flex flex-wrap gap-1.5">
          {suggestions
          ->Array.mapWithIndex((s, i) =>
            <button
              key={Int.toString(i)}
              type_="button"
              onClick={_ => setMessage(_ => s)}
              className="rounded-full border border-gray-200 dark:border-[#3a3b40] px-2.5 py-1 text-[10px] text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500">
              {s->React.string}
            </button>
          )
          ->React.array}
        </div>
        <div className="mt-4 flex items-center justify-between gap-3">
          <span
            className={switch problem {
            | Some(SameAsPrevious) | Some(TooShort(_)) => "font-mono text-[10px] text-amber-600 dark:text-amber-400"
            | _ => "font-mono text-[10px] text-gray-400 dark:text-gray-500"
            }}>
            {switch problem {
            | Some(Empty) => ts`A message is required`
            | Some(TooShort(needed)) => ts`${Int.toString(needed)} more characters needed`
            | Some(SameAsPrevious) => ts`Same as your last invite. Write this one for them.`
            | None => ts`${Int.toString(maxLength - message->String.length)} characters left`
            }->React.string}
          </span>
          <div className="flex items-center gap-2">
            <button
              type_="button"
              onClick={_ => onCancel()}
              className="rounded-lg border border-gray-200 dark:border-[#3a3b40] px-3 py-2 text-xs font-medium text-gray-700 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500">
              {(ts`Cancel`)->React.string}
            </button>
            <button
              type_="button"
              disabled={!canSend}
              onClick={_ => submit()}
              className="inline-flex items-center gap-1.5 rounded-lg bg-violet-600 px-3 py-2 text-xs font-semibold text-white transition-colors hover:bg-violet-700 disabled:cursor-not-allowed disabled:opacity-40 focus:outline-none focus-visible:ring-2 focus-visible:ring-violet-500 focus-visible:ring-offset-2">
              <Lucide.Send className="w-3 h-3" />
              {(submitting ? ts`Sending…` : ts`Send invite`)->React.string}
            </button>
          </div>
        </div>
      </div>
    </div>,
    documentBody,
  )
}

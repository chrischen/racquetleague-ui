%%raw("import { t } from '@lingui/macro'")

// The viewer's conversation with one person: their private messages both
// ways, oldest first, and a box to reply. An invite note shows the event it
// was for inside its own bubble, so two invites from the same person each
// show their own event; a conversation about an event no invite note shows
// gets a card for it under the messages.
//
// Private messages are one-to-one. The server clears them out after 30 days
// to keep the inbox small; that is housekeeping, not something promised to
// users, so the page does not mention it. A reply answers the latest message
// the other person sent; until they have written to the viewer there is
// nothing to reply to (see src/lib/DirectMessage.res).

module SendMutation = %relay(`
  mutation MessageThreadSendMutation($input: SendDirectMessageInput!) {
    sendDirectMessage(input: $input) {
      message {
        id
        topic
        payload
        createdAt
      }
      errors {
        message
      }
    }
  }
`)

// The server's error codes, in words.
let errorText = (code: string): string => {
  let ts = Lingui.UtilString.t
  switch code {
  | "EMPTY_MESSAGE" => ts`Write a message first.`
  | "MESSAGE_TOO_LONG" => ts`That message is too long.`
  | "MESSAGE_NOT_FOUND" => ts`That message is no longer available, so it can't be answered.`
  | "NOT_LOGGED_IN" => ts`Sign in to reply.`
  | _ => ts`Your reply couldn't be sent. Please try again.`
  }
}

let maxLength = 2000

// The other person, as the page knows them: from their profile when it
// loaded, else from the messages.
type person = {name: string, picture: option<string>}

let initialsOf = (name: string) => {
  let parts = name->String.trim->String.split(" ")->Array.filter(p => p != "")
  switch parts {
  | [] => "?"
  | [single] => single->String.slice(~start=0, ~end=2)->String.toUpperCase
  | _ =>
    parts
    ->Array.map(p => p->String.slice(~start=0, ~end=1))
    ->Array.slice(~start=0, ~end=2)
    ->Array.join("")
    ->String.toUpperCase
  }
}

// A stable colour per person for their initials.
let avatarColors = [
  "bg-violet-500",
  "bg-sky-500",
  "bg-emerald-500",
  "bg-amber-500",
  "bg-rose-500",
  "bg-indigo-500",
]
let avatarColorOf = (id: string) => {
  let sum = ref(0)
  for i in 0 to id->String.length - 1 {
    sum := sum.contents + id->String.charCodeAt(i)->Float.toInt
  }
  avatarColors->Array.get(mod(sum.contents, avatarColors->Array.length))->Option.getOr("bg-gray-500")
}

let firstNameOf = (name: string) =>
  name->String.trim->String.split(" ")->Array.get(0)->Option.getOr(name)

module PersonAvatar = {
  @react.component
  let make = (~id: string, ~person: person) =>
    switch person.picture {
    | Some(src) =>
      <img
        src
        alt=""
        className="h-10 w-10 flex-shrink-0 rounded-full object-cover"
        ariaHidden=true
      />
    | None =>
      <span
        className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full text-sm font-semibold text-white ${avatarColorOf(
            id,
          )}`}
        ariaHidden=true>
        {initialsOf(person.name)->React.string}
      </span>
    }
}

module Composer = {
  @react.component
  let make = (~replyTo: DirectMessage.t, ~person: person, ~onSent: DirectMessage.t => unit) => {
    let ts = Lingui.UtilString.t
    let (body, setBody) = React.useState(() => "")
    let (error, setError) = React.useState((): option<string> => None)
    let (commit, inFlight) = SendMutation.use()
    let trimmed = body->String.trim
    let canSend = trimmed != "" && !inFlight
    let fieldId = "reply-" ++ replyTo.id
    let name = person.name

    let submit = () =>
      if canSend {
        setError(_ => None)
        commit(
          ~variables={input: {body: trimmed, replyToMessageId: replyTo.id}},
          ~onCompleted=(response, _) =>
            switch response.sendDirectMessage {
            | {errors: Some(errors)} if errors->Array.length > 0 =>
              setError(_ => errors->Array.get(0)->Option.map(e => errorText(e.message)))
            | {message: Some(m)} =>
              switch DirectMessage.decode(
                ~id=m.id,
                ~topic=m.topic,
                ~payload=m.payload,
                ~createdAt=m.createdAt,
              ) {
              | Some(sent) => onSent(sent)
              | None => ()
              }
              setBody(_ => "")
            | _ => setError(_ => Some(errorText("SEND_FAILED")))
            },
          ~onError=_ => setError(_ => Some(errorText("SEND_FAILED"))),
        )->RescriptRelay.Disposable.ignore
      }

    <form
      className="mt-4"
      onSubmit={e => {
        e->ReactEvent.Form.preventDefault
        submit()
      }}>
      <div className="flex items-end gap-2">
        <label htmlFor=fieldId className="sr-only"> {(ts`Reply to ${name}`)->React.string} </label>
        <textarea
          id=fieldId
          value=body
          maxLength
          rows=1
          placeholder={ts`Write a reply`}
          onChange={e => {
            let value = (e->ReactEvent.Form.target)["value"]
            setBody(_ => value)
          }}
          onKeyDown={e =>
            // Cmd/Ctrl+Enter sends; plain Enter is a new line.
            if (
              e->ReactEvent.Keyboard.key == "Enter" &&
                (e->ReactEvent.Keyboard.metaKey || e->ReactEvent.Keyboard.ctrlKey)
            ) {
              e->ReactEvent.Keyboard.preventDefault
              submit()
            }}
          className="min-h-10 min-w-0 flex-1 resize-none rounded-lg border border-gray-200 bg-white px-3 py-2.5 text-sm text-gray-900 outline-none transition-colors placeholder:text-gray-400 focus:border-[#94c93a] focus:ring-2 focus:ring-[#bdf25d]/30 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-100"
        />
        <button
          type_="submit"
          disabled={!canSend}
          className="inline-flex h-10 items-center gap-1.5 rounded-lg bg-[#bdf25d] px-3.5 text-sm font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] disabled:cursor-not-allowed disabled:opacity-40">
          <Lucide.Send size=14 \"aria-hidden"="true" />
          <span className="hidden sm:inline">
            {(inFlight ? ts`Sending` : ts`Send`)->React.string}
          </span>
        </button>
      </div>
      {switch error {
      | Some(message) =>
        <p className="mt-2 text-xs text-red-600 dark:text-red-400"> {message->React.string} </p>
      | None => React.null
      }}
    </form>
  }
}

// An event's details for a message: title, when, where and how full. A
// message only names the event, so the rest is fetched here (and cached, so
// an event mentioned twice is fetched once).
module EventSummary = {
  module Query = %relay(`
    query MessageThreadEventQuery($eventId: ID!) {
      event(id: $eventId) {
        id
        title
        startDate
        endDate
        timezone
        maxRsvps
        location {
          name
        }
        rsvps(first: 100) {
          edges {
            node {
              listType
            }
          }
        }
      }
    }
  `)

  type t = {
    title: option<string>,
    // Start date and time, with the duration when the event has an end.
    when_: option<string>,
    venue: option<string>,
    // Going players, over the cap when there is one: "6/8".
    capacity: string,
  }

  let durationOf = (minutes: float) => {
    let hours = Js.Math.floor_float(minutes /. 60.)
    let rest = mod(minutes->Float.toInt, 60)
    if hours > 0. && rest > 0 {
      Float.toString(hours) ++ "h " ++ Int.toString(rest) ++ "m"
    } else if hours > 0. {
      Float.toString(hours) ++ "h"
    } else {
      Int.toString(rest) ++ "m"
    }
  }

  let use = (~eventId: string): option<t> => {
    let intl = ReactIntl.useIntl()
    let {event} = Query.use(~variables={eventId: eventId}, ~fetchPolicy=StoreOrNetwork)
    event->Option.map(event => {
      let start = event.startDate->Option.map(Util.Datetime.toDate)
      let duration = switch (start, event.endDate) {
      | (Some(start), Some(end_)) =>
        Some(end_->Util.Datetime.toDate->DateFns.differenceInMinutes(start)->durationOf)
      | _ => None
      }
      let when_ = start->Option.map(start =>
        intl->ReactIntl.Intl.formatDateWithOptions(
          start,
          ReactIntl.dateTimeFormatOptions(
            ~timeZone=?event.timezone,
            ~weekday=#short,
            ~month=#short,
            ~day=#numeric,
            ~hour=#numeric,
            ~minute=#"2-digit",
            (),
          ),
        ) ++ duration->Option.mapOr("", d => " · " ++ d)
      )
      // Going players: an RSVP with no list type, or the confirmed list.
      let going =
        event.rsvps
        ->Option.flatMap(c => c.edges)
        ->Option.getOr([])
        ->Array.filter(edge =>
          edge
          ->Option.flatMap(e => e.node)
          ->Option.mapOr(false, n => n.listType == None || n.listType == Some(0))
        )
        ->Array.length
      {
        title: event.title,
        when_,
        venue: event.location->Option.flatMap(l => l.name),
        capacity: switch event.maxRsvps {
        | Some(max) => Int.toString(going) ++ "/" ++ Int.toString(max)
        | None => Int.toString(going)
        },
      }
    })
  }
}

// The when · where · how-full line under an event's title.
module EventMeta = {
  @react.component
  let make = (~summary: EventSummary.t, ~className: string, ~iconSize: int) =>
    <span className>
      {switch summary.when_ {
      | Some(when_) =>
        <span className="inline-flex items-center gap-1">
          <Lucide.Clock3 size=iconSize \"aria-hidden"="true" />
          {when_->React.string}
        </span>
      | None => React.null
      }}
      {switch summary.venue {
      | Some(venue) =>
        <span className="inline-flex min-w-0 items-center gap-1">
          <Lucide.MapPin size=iconSize \"aria-hidden"="true" />
          <span className="truncate"> {venue->React.string} </span>
        </span>
      | None => React.null
      }}
      <span className="inline-flex items-center gap-1">
        <Lucide.Users size=iconSize \"aria-hidden"="true" />
        {summary.capacity->React.string}
      </span>
    </span>
}

// The event an invite note is for, attached to the bottom of its bubble. The
// bubble's colours carry through: on your own lime bubble it is a darker band,
// on theirs a light one.
module InviteEventStrip = {
  module View = {
    @react.component
    let make = (
      ~eventId: string,
      ~title: string,
      ~summary: option<EventSummary.t>,
      ~outgoing: bool,
    ) => {
      let ts = Lingui.UtilString.t
      <LangProvider.Router.Link
        to={"/events/" ++ eventId}
        className={"group flex w-full items-center gap-3 border-t px-3.5 py-3 text-left transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[#5b8218] " ++ (
          // The bubble's text colour, set here: links are otherwise tinted.
          outgoing
            ? "border-black/10 bg-black/[0.05] text-black hover:bg-black/[0.09] hover:text-black"
            : "border-gray-200 bg-gray-50 text-gray-800 hover:bg-[#bdf25d]/10 hover:text-gray-800 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-100 dark:hover:bg-[#bdf25d]/10 dark:hover:text-gray-100"
        )}>
        <span
          className={"flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg " ++ (
            outgoing ? "bg-black/10 text-black" : "bg-[#bdf25d]/20 text-[#5b8218] dark:text-[#bdf25d]"
          )}>
          <Lucide.CalendarDays size=17 \"aria-hidden"="true" />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate font-semibold"> {title->React.string} </span>
          {switch summary {
          | Some(summary) =>
            <EventMeta
              summary
              iconSize=11
              className={"mt-0.5 flex flex-wrap items-center gap-x-2.5 gap-y-1 text-[11px] " ++ (
                outgoing ? "text-black/65" : "text-gray-500 dark:text-gray-400"
              )}
            />
          | None => React.null
          }}
        </span>
        <span className="inline-flex flex-shrink-0 items-center gap-1 text-xs font-semibold">
          {(ts`View`)->React.string}
          <Lucide.ArrowRight size=13 \"aria-hidden"="true" />
        </span>
      </LangProvider.Router.Link>
    }
  }

  module Loaded = {
    @react.component
    let make = (~eventId: string, ~eventName: string, ~outgoing: bool) => {
      let summary = EventSummary.use(~eventId)
      let title = summary->Option.flatMap(s => s.title)->Option.getOr(eventName)
      <View eventId title summary outgoing />
    }
  }

  // Shows the event's name at once, and its details once they arrive.
  @react.component
  let make = (~eventId: string, ~eventName: string, ~outgoing: bool) =>
    <React.Suspense fallback={<View eventId title=eventName summary=None outgoing />}>
      <Loaded eventId eventName outgoing />
    </React.Suspense>
}

module Bubble = {
  @react.component
  let make = (~message: DirectMessage.t) => {
    let outgoing = message.copy == DirectMessage.Sent
    // An invite note carries its event inside the bubble, so each invite in
    // a conversation shows the event it was for.
    let invitedTo = switch (DirectMessage.isInvite(message), message.eventId, message.eventName) {
    | (true, Some(eventId), Some(eventName)) => Some((eventId, eventName))
    | _ => None
    }
    <div className={outgoing ? "flex justify-end" : "flex justify-start"}>
      <div
        className={(
          invitedTo->Option.isSome ? "max-w-[96%] md:max-w-[82%]" : "max-w-[88%] md:max-w-[72%]"
        ) ++ (outgoing ? " text-right" : "")}>
        <div
          className={"overflow-hidden rounded-xl text-left text-sm leading-relaxed " ++ (
            outgoing
              ? "rounded-br-sm bg-[#bdf25d] text-black"
              : "rounded-bl-sm bg-white text-gray-800 shadow-sm ring-1 ring-gray-200 dark:bg-[#292a2f] dark:text-gray-100 dark:ring-[#3a3b40]"
          )}>
          <p className="whitespace-pre-wrap break-words px-3.5 py-2.5">
            {message.body->React.string}
          </p>
          {switch invitedTo {
          | Some((eventId, eventName)) => <InviteEventStrip eventId eventName outgoing />
          | None => React.null
          }}
        </div>
        <span className="mt-1 block font-mono text-[10px] text-gray-400 dark:text-gray-500">
          {NotificationRow.relativeTimeStr(message.createdAt)->React.string}
        </span>
      </div>
    </div>
  }
}

// The event a conversation is about, as a card under the messages: for a
// conversation whose event no invite note in it already shows.
module EventLink = {
  module Loaded = {
    @react.component
    let make = (~eventId: string, ~eventName: string) => {
      let ts = Lingui.UtilString.t
      let summary = EventSummary.use(~eventId)
      let title = summary->Option.flatMap(s => s.title)->Option.getOr(eventName)
      <LangProvider.Router.Link
        to={"/events/" ++ eventId}
        className="group flex w-full items-center gap-3 px-4 py-4 text-left transition-colors hover:bg-[#bdf25d]/10 focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[#94c93a] md:px-5">
        <span
          className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-lg bg-[#bdf25d]/20 text-[#5b8218] dark:text-[#bdf25d]">
          <Lucide.CalendarDays size=20 \"aria-hidden"="true" />
        </span>
        <span className="min-w-0 flex-1">
          <span className="block truncate text-base font-semibold text-gray-900 dark:text-gray-100">
            {title->React.string}
          </span>
          {switch summary {
          | Some(summary) =>
            <EventMeta
              summary
              iconSize=12
              className="mt-1 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-gray-500 dark:text-gray-400"
            />
          | None => React.null
          }}
        </span>
        <span
          className="inline-flex flex-shrink-0 items-center gap-1.5 rounded-lg bg-[#bdf25d] px-3.5 py-2 text-sm font-semibold text-black shadow-sm transition-colors group-hover:bg-[#aee050]">
          {(ts`View event`)->React.string}
          <Lucide.ArrowRight size=15 \"aria-hidden"="true" />
        </span>
      </LangProvider.Router.Link>
    }
  }

  @react.component
  let make = (~eventId: string, ~eventName: string) =>
    <React.Suspense fallback=React.null>
      <Loaded eventId eventName />
    </React.Suspense>
}

@react.component
let make = (~withUserId: string, ~person: option<person>, ~messages: array<DirectMessage.t>) => {
  let ts = Lingui.UtilString.t
  // Replies sent from this page, shown at once rather than after a reload.
  let (sent, setSent) = React.useState((): array<DirectMessage.t> => [])
  let onSent = message => setSent(prev => Array.concat(prev, [message]))
  let conversation =
    DirectMessage.conversations(Array.concat(messages, sent))->Array.find(c =>
      c.withUserId == withUserId
    )
  // Their profile when it loaded; else the name the messages carry.
  let person = switch (person, conversation) {
  | (Some(person), _) => Some(person)
  | (None, Some(c)) => Some({name: c.withUserName, picture: None})
  | (None, None) => None
  }
  // An invite note either way marks the conversation as an invitation.
  let inviteFrom =
    conversation->Option.flatMap(c =>
      c.messages->Array.toReversed->Array.find(DirectMessage.isInvite)->Option.map(m => m.copy)
    )

  <section ariaLabelledby="thread-title">
    <header className="mb-5">
      <p className="font-mono text-[10px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
        {(inviteFrom->Option.isSome ? ts`Invitation thread` : ts`Message thread`)->React.string}
      </p>
      <h1
        id="thread-title"
        className="mt-1 truncate text-2xl font-semibold text-gray-900 dark:text-gray-100">
        {person->Option.mapOr("", p => p.name)->React.string}
      </h1>
    </header>
    {switch (conversation, person) {
    | (Some(conversation), Some(person)) =>
      let name = person.name
      let firstName = firstNameOf(name)
      <article
        className="overflow-hidden rounded-xl border border-gray-200 bg-white dark:border-[#34353a] dark:bg-[#1e1f23]">
        <header className="flex items-center gap-3 px-4 py-3.5 md:px-5">
          <PersonAvatar id=withUserId person />
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <h2 className="truncate text-sm font-semibold text-gray-900 dark:text-gray-100">
                {name->React.string}
              </h2>
              <span
                className="inline-flex items-center gap-1 text-[11px] font-medium text-gray-500 dark:text-gray-400">
                {switch inviteFrom {
                | Some(Received) =>
                  <>
                    <Lucide.UserPlus size=12 \"aria-hidden"="true" />
                    {(ts`Invited you`)->React.string}
                  </>
                | Some(Sent) =>
                  <>
                    <Lucide.UserPlus size=12 \"aria-hidden"="true" />
                    {(ts`You invited them`)->React.string}
                  </>
                | None =>
                  <>
                    <Lucide.MessageCircle size=12 \"aria-hidden"="true" />
                    {(ts`Message`)->React.string}
                  </>
                }}
              </span>
            </div>
            <p className="mt-0.5 font-mono text-[10px] text-gray-400 dark:text-gray-500">
              {NotificationRow.relativeTimeStr(conversation.latestAt)->React.string}
            </p>
          </div>
        </header>
        <div
          className="border-y border-gray-100 bg-gray-50/70 px-4 py-4 dark:border-[#2a2b30] dark:bg-[#191a1d] md:px-5">
          <div className="space-y-3" ariaLabel={ts`Messages with ${name}`}>
            {conversation.messages
            ->Array.map(message => <Bubble key=message.id message />)
            ->React.array}
          </div>
          {switch conversation.replyTarget {
          | Some(replyTo) => <Composer replyTo person onSent />
          | None =>
            <p className="mt-4 text-xs text-gray-500 dark:text-gray-400">
              {(ts`You can reply once ${firstName} writes back.`)->React.string}
            </p>
          }}
        </div>
        {switch conversation.event {
        // An invite note already shows its event in its bubble.
        | Some((eventId, eventName))
          if !(
            conversation.messages->Array.some(m =>
              DirectMessage.isInvite(m) && m.eventId == Some(eventId)
            )
          ) =>
          <EventLink eventId eventName />
        | _ => React.null
        }}
      </article>
    | _ =>
      <div
        className="flex flex-col items-center justify-center rounded-xl border border-dashed border-gray-200 py-16 text-center dark:border-[#3a3b40]">
        <span
          className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-gray-100 dark:bg-[#2a2b30]">
          <Lucide.MessageCircle className="h-[18px] w-[18px] text-gray-400 dark:text-gray-500" />
        </span>
        <p className="text-sm text-gray-500 dark:text-gray-400">
          {(ts`No recent messages with this person.`)->React.string}
        </p>
      </div>
    }}
  </section>
}

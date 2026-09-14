%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

module Fragment = %relay(`
  fragment PkEventMessages_query on Query
  @argumentDefinitions(
    topic: { type: "String!" }
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 80 }
  ) {
    __id
    messagesByTopic(topic: $topic, after: $after, first: $first, before: $before)
      @connection(key: "PkEventMessages_messagesByTopic") {
      edges {
        node {
          id
          createdAt
          payload
          topic
        }
      }
    }
  }
`)

module SendMessageMutation = %relay(`
  mutation PkEventMessagesSendMutation($connections: [ID!]!, $input: UpdateViewerRsvpMessageInput!) {
    updateViewerRsvpMessage(input: $input) {
      edge @prependEdge(connections: $connections) {
        node {
          id
          payload
          createdAt
          topic
        }
      }
    }
  }
`)

@module("date-fns")
external differenceInHoursRaw: (Js.Date.t, Js.Date.t) => int = "differenceInHours"

let relativeTimeStr = (dateStr: string): string => {
  let date = dateStr->Js.Date.fromString
  let now = Js.Date.make()
  let hours = differenceInHoursRaw(now, date)
  if hours < 1 {
    let mins = DateFns.differenceInMinutes(now, date)->Float.toInt
    if mins < 1 {
      "just now"
    } else {
      Int.toString(mins) ++ "m ago"
    }
  } else if hours < 24 {
    Int.toString(hours) ++ "h ago"
  } else {
    Int.toString(hours / 24) ++ "d ago"
  }
}

type payloadType = {
  actorUserName: option<string>,
  activityType: option<string>,
  details: option<string>,
}

let decodePayload = (s: string): option<payloadType> =>
  try {
    switch s->Js.Json.parseExn->Js.Json.decodeObject {
    | Some(d) =>
      Some({
        actorUserName: d->Js.Dict.get("actorUserName")->Option.flatMap(Js.Json.decodeString(_)),
        activityType: d->Js.Dict.get("activityType")->Option.flatMap(Js.Json.decodeString(_)),
        details: d->Js.Dict.get("details")->Option.flatMap(Js.Json.decodeString(_)),
      })
    | None => None
    }
  } catch {
  | _ => None
  }

let makeInitials = (name: string) =>
  name
  ->String.split(" ")
  ->Array.slice(~start=0, ~end=2)
  ->Array.map(w => String.slice(w, ~start=0, ~end=1))
  ->Array.join("")
  ->String.toUpperCase

// Chat messages written by people, as opposed to the system's RSVP and edit
// rows. The footer's collapsed row previews the newest of these.
let isChatMessage = activityType =>
  switch activityType {
  | "host_message" | "comment_added" => true
  | _ => false
  }

type message = {
  id: string,
  actor: string,
  activityType: string,
  details: option<string>,
  timeStr: string,
}

let toMessage = (node: Fragment.Types.fragment_messagesByTopic_edges_node): message => {
  let payload = node.payload->Option.flatMap(decodePayload)
  {
    id: node.id,
    actor: payload->Option.flatMap(p => p.actorUserName)->Option.getOr("?"),
    activityType: payload->Option.flatMap(p => p.activityType)->Option.getOr(""),
    details: payload->Option.flatMap(p => p.details),
    timeStr: relativeTimeStr(node.createdAt),
  }
}

// Newest first, matching the connection's prepend order.
let messagesOf = (data: Fragment.Types.fragment) =>
  data.messagesByTopic->Fragment.getConnectionNodes->Array.map(toMessage)

module ActivityRow = {
  @react.component
  let make = (~message: message) => {
    let ts = Lingui.UtilString.t
    let {actor, activityType, details, timeStr} = message
    let time =
      <span className="ml-1.5 text-[10px] text-gray-400 dark:text-gray-500">
        {timeStr->React.string}
      </span>
    // System rows: a toned icon disc and one line of small text.
    let systemRow = (~icon, ~tone, ~textClass, ~body: React.element) =>
      <div className="flex gap-2.5">
        <div
          className={"mt-0.5 flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full " ++
          tone}>
          icon
        </div>
        <div className="min-w-0 flex-1">
          <p className={"pt-1 text-xs leading-relaxed " ++ textClass}>
            body
            time
          </p>
        </div>
      </div>
    let actorRow = (~icon, ~tone, ~text: string) =>
      systemRow(
        ~icon,
        ~tone,
        ~textClass="text-gray-600 dark:text-gray-400",
        ~body=<>
          <span className="font-semibold text-gray-800 dark:text-gray-200">
            {(actor ++ " ")->React.string}
          </span>
          {text->React.string}
        </>,
      )
    let emerald = "bg-emerald-50 text-emerald-600 dark:bg-emerald-900/20 dark:text-emerald-400"
    let red = "bg-red-50 text-red-500 dark:bg-red-900/20 dark:text-red-400"
    let amber = "bg-amber-50 text-amber-600 dark:bg-amber-900/20 dark:text-amber-400"
    let blue = "bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-400"
    let violet = "bg-violet-50 text-violet-600 dark:bg-violet-900/20 dark:text-violet-400"

    switch activityType {
    | "host_message" | "comment_added" =>
      <div className="flex gap-2.5">
        <div
          className="mt-0.5 flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full border border-gray-200 bg-white text-[10px] font-semibold text-gray-600 dark:border-[#3a3b40] dark:bg-[#2a2b30] dark:text-gray-300">
          {makeInitials(actor)->React.string}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-baseline gap-2">
            <span className="text-sm font-semibold text-gray-900 dark:text-gray-100">
              {actor->React.string}
            </span>
            <span className="text-[11px] text-gray-400 dark:text-gray-500">
              {timeStr->React.string}
            </span>
          </div>
          {details
          ->Option.map(d =>
            <p className="mt-0.5 text-sm leading-relaxed text-gray-700 dark:text-gray-300">
              {d->React.string}
            </p>
          )
          ->Option.getOr(React.null)}
        </div>
      </div>
    | "update" =>
      systemRow(
        ~icon=<Lucide.Pencil size=13 \"aria-hidden"="true" />,
        ~tone=amber,
        ~textClass="text-amber-700 dark:text-amber-400",
        ~body={details->Option.getOr(ts`Event updated`)->React.string},
      )
    | "rsvp_created" =>
      actorRow(
        ~icon=<Lucide.UserPlus size=13 \"aria-hidden"="true" />,
        ~tone=emerald,
        ~text=ts`joined the event`,
      )
    | "rsvp_added" =>
      actorRow(
        ~icon=<Lucide.UserPlus size=13 \"aria-hidden"="true" />,
        ~tone=emerald,
        ~text=ts`was added to the event by admin`,
      )
    // The actor is the invitee, not the inviter — the invite still needs
    // them to join before it counts toward the event.
    | "rsvp_invited" =>
      actorRow(
        ~icon=<Lucide.Mail size=13 \"aria-hidden"="true" />,
        ~tone=violet,
        ~text=ts`was invited to the event`,
      )
    | "rsvp_promoted" =>
      actorRow(
        ~icon=<Lucide.ArrowUpCircle size=13 \"aria-hidden"="true" />,
        ~tone=blue,
        ~text=ts`joined from waitlist`,
      )
    | "rsvp_deleted" | "rsvp_removed" =>
      actorRow(
        ~icon=<Lucide.UserMinus size=13 \"aria-hidden"="true" />,
        ~tone=red,
        ~text=ts`left the event`,
      )
    | _ =>
      actorRow(
        ~icon=<Lucide.AlertCircle size=13 \"aria-hidden"="true" />,
        ~tone=amber,
        ~text=details->Option.getOr(""),
      )
    }
  }
}

// The activity feed. `prominent` is the sticky-footer variant: a tinted
// full-bleed panel titled "Event chat" rather than a card in the page flow.
module Section = {
  @react.component
  let make = (
    ~queryRef: RescriptRelay.fragmentRefs<[> #PkEventMessages_query]>,
    ~eventId: string,
    ~canPost: bool,
    ~prominent: bool=false,
  ) => {
    let ts = Lingui.UtilString.t
    let data = Fragment.use(queryRef)
    let (showAll, setShowAll) = React.useState(() => false)
    let (messageInput, setMessageInput) = React.useState(() => "")
    let (sendMessage, sendingMessage) = SendMessageMutation.use()

    let allMessages = messagesOf(data)
    let totalCount = allMessages->Array.length
    let totalCountStr = Int.toString(totalCount)
    let messageCountStr =
      allMessages->Array.filter(m => isChatMessage(m.activityType))->Array.length->Int.toString
    let visible = showAll ? allMessages : allMessages->Array.slice(~start=0, ~end=5)
    let hasText = messageInput->String.trim != ""

    let onSendMessage = () => {
      let trimmed = messageInput->String.trim
      if trimmed != "" && !sendingMessage {
        let messagesConnectionId =
          data.__id->Fragment.Operation.makeConnectionId(~topic=eventId ++ ".updated")
        sendMessage(
          ~variables={
            connections: [messagesConnectionId],
            input: {eventId, message: trimmed},
          },
        )->ignore
        setMessageInput(_ => "")
      }
    }

    <section
      className={Util.cx([
        "px-5 py-5",
        prominent
          ? "border-b border-gray-100 bg-[#fbfdf7] dark:border-[#2a2b30] dark:bg-[#20231d]"
          : "mx-3 mt-3 rounded-xl border border-gray-200 bg-white dark:border-[#2a2b30] dark:bg-[#1e1f23]",
      ])}
      ariaLabelledby="event-chat-title">
      <div className={prominent ? "mx-auto w-full max-w-2xl" : ""}>
        <div className="mb-4 flex items-center justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <span
              className="flex h-9 w-9 items-center justify-center rounded-full bg-[#bdf25d]/25 text-[#547817] dark:bg-[#bdf25d]/15 dark:text-[#bdf25d]">
              <Lucide.MessageCircle size=18 \"aria-hidden"="true" />
            </span>
            <div>
              <h2
                id="event-chat-title"
                className="text-base font-semibold text-gray-900 dark:text-gray-100">
                {prominent ? t`Event chat` : t`Activity`}
              </h2>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {canPost
                  ? t`${messageCountStr} messages · ${totalCountStr} updates`
                  : t`Join this event to take part in the chat`}
              </p>
            </div>
          </div>
        </div>
        <div className="space-y-3.5">
          {visible->Array.map(message => <ActivityRow key=message.id message />)->React.array}
        </div>
        {totalCount > 5
          ? <button
              type_="button"
              onClick={_ => setShowAll(v => !v)}
              className="mt-3 text-xs font-semibold text-[#5f8618] underline-offset-2 transition-colors hover:text-[#476412] hover:underline focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:text-[#bdf25d] dark:hover:text-[#d3ff85]">
              {showAll ? t`Show less` : t`View all ${totalCountStr} updates`}
            </button>
          : React.null}
        {canPost
          ? <div
              className="mt-4 flex items-center gap-2 rounded-lg border border-gray-300 bg-white px-3 py-2.5 shadow-sm transition-colors focus-within:border-[#94c93a] focus-within:ring-2 focus-within:ring-[#bdf25d]/30 dark:border-[#3a3b40] dark:bg-[#222326]">
              <input
                type_="text"
                value=messageInput
                onChange={e => setMessageInput(_ => ReactEvent.Form.target(e)["value"])}
                onKeyDown={e =>
                  if ReactEvent.Keyboard.key(e) == "Enter" {
                    onSendMessage()
                  }}
                placeholder={ts`Message everyone in this event…`}
                ariaLabel={ts`Message everyone in this event`}
                className="min-w-0 flex-1 border-0 bg-transparent p-0 text-sm text-gray-900 outline-none placeholder:text-gray-400 focus:outline-none focus:ring-0 dark:text-gray-100 dark:placeholder:text-gray-500"
              />
              <button
                type_="button"
                disabled={!hasText || sendingMessage}
                onClick={_ => onSendMessage()}
                ariaLabel={ts`Send message`}
                className={Util.cx([
                  "flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-md transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a]",
                  hasText
                    ? "bg-[#bdf25d] text-black hover:bg-[#aee050]"
                    : "bg-gray-100 text-gray-300 dark:bg-[#2a2b30] dark:text-gray-600",
                ])}>
                <Lucide.Send size=15 \"aria-hidden"="true" />
              </button>
            </div>
          : React.null}
      </div>
    </section>
  }
}

// Joined viewers get the chat in the sticky footer: a one-line preview of the
// newest message that expands into the full activity section above it.
module FooterChat = {
  @react.component
  let make = (
    ~queryRef: RescriptRelay.fragmentRefs<[> #PkEventMessages_query]>,
    ~eventId: string,
  ) => {
    let data = Fragment.use(queryRef)
    let (expanded, setExpanded) = React.useState(() => false)
    let latest = messagesOf(data)->Array.find(m => isChatMessage(m.activityType))

    <>
      {expanded
        ? <div
            className="max-h-[46vh] overflow-y-auto border-b border-gray-200 dark:border-[#2a2b30]">
            <Section queryRef eventId canPost=true prominent=true />
          </div>
        : React.null}
      <button
        type_="button"
        onClick={_ => setExpanded(v => !v)}
        ariaExpanded=expanded
        className="block w-full border-b border-gray-200 bg-[#fbfdf7] text-left transition-colors hover:bg-[#f5f9ed] focus:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[#94c93a] dark:border-[#2a2b30] dark:bg-[#20231d] dark:hover:bg-[#25291f]">
        <span className="mx-auto flex w-full max-w-2xl items-center gap-2.5 px-5 py-2.5">
          <span
            className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full bg-[#bdf25d]/25 text-[#547817] dark:bg-[#bdf25d]/15 dark:text-[#bdf25d]">
            <Lucide.MessageCircle size=14 \"aria-hidden"="true" />
          </span>
          <span className="min-w-0 flex-1">
            {switch latest {
            | Some(m) =>
              <>
                <span className="block text-xs font-semibold text-gray-900 dark:text-gray-100">
                  {m.actor->React.string}
                  <span className="ml-1.5 font-normal text-gray-400 dark:text-gray-500">
                    {m.timeStr->React.string}
                  </span>
                </span>
                <span className="block truncate text-xs text-gray-600 dark:text-gray-300">
                  {m.details->Option.getOr("")->React.string}
                </span>
              </>
            | None =>
              <>
                <span className="block text-xs font-semibold text-gray-900 dark:text-gray-100">
                  {t`Event chat`}
                </span>
                <span className="block truncate text-xs text-gray-600 dark:text-gray-300">
                  {t`No messages yet`}
                </span>
              </>
            }}
          </span>
          <Lucide.ChevronRight
            size=14
            className={"flex-shrink-0 text-gray-400 transition-transform duration-200 " ++ (
              expanded ? "rotate-90" : "-rotate-90"
            )}
            \"aria-hidden"="true"
          />
        </span>
      </button>
    </>
  }
}

// The in-page activity card. Only viewers who haven't joined see it here;
// joined viewers get FooterChat instead.
@react.component
let make = (
  ~queryRef: RescriptRelay.fragmentRefs<[> #PkEventMessages_query]>,
  ~eventId: string,
  ~isJoined: bool,
) => <Section queryRef eventId canPost=isJoined />

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

@react.component
let make = (
  ~queryRef: RescriptRelay.fragmentRefs<[> #PkEventMessages_query]>,
  ~eventId: string,
  ~isJoined: bool,
) => {
  let ts = Lingui.UtilString.t
  let data = Fragment.use(queryRef)
  let (showAllActivity, setShowAllActivity) = React.useState(() => false)
  let (messageInput, setMessageInput) = React.useState(() => "")
  let (sendMessage, sendingMessage) = SendMessageMutation.use()

  let allMessages = data.messagesByTopic->Fragment.getConnectionNodes

  let displayedMessages = showAllActivity ? allMessages : allMessages->Array.slice(~start=0, ~end=5)

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

  <div className="px-5 py-4">
    <div className="flex items-center justify-between mb-3">
      <h2
        className="font-mono text-[10px] tracking-wider text-gray-400 dark:text-gray-500 uppercase">
        {(ts`Activity`)->React.string}
      </h2>
      <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
        {(Int.toString(allMessages->Array.length) ++ " items")->React.string}
      </span>
    </div>
    <div className="space-y-3">
      {displayedMessages
      ->Array.map(msg => {
        let payload = msg.payload->Option.flatMap(decodePayload)
        let activityType = payload->Option.flatMap(p => p.activityType)->Option.getOr("")
        let actor = payload->Option.flatMap(p => p.actorUserName)->Option.getOr("?")
        let details = payload->Option.flatMap(p => p.details)
        let timeStr = relativeTimeStr(msg.createdAt)
        switch activityType {
        | "host_message" | "comment_added" =>
          <div key=msg.id className="flex gap-2.5">
            <div
              className="w-7 h-7 rounded-full bg-gray-100 dark:bg-[#2a2b30] flex items-center justify-center text-[9px] font-medium text-gray-600 dark:text-gray-300 flex-shrink-0 mt-0.5">
              {makeInitials(actor)->React.string}
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline gap-1.5">
                <span className="text-xs font-medium text-gray-900 dark:text-gray-100">
                  {actor->React.string}
                </span>
                <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
                  {timeStr->React.string}
                </span>
              </div>
              {details
              ->Option.map(d =>
                <p className="text-xs text-gray-600 dark:text-gray-400 mt-0.5 leading-relaxed">
                  {d->React.string}
                </p>
              )
              ->Option.getOr(React.null)}
            </div>
          </div>
        | "update" =>
          <div key=msg.id className="flex gap-2.5">
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 bg-amber-50 dark:bg-amber-900/20 text-amber-600 dark:text-amber-400">
              <Lucide.Pencil className="w-3 h-3" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline gap-1.5">
                <span className="text-xs text-amber-700 dark:text-amber-400">
                  {details->Option.getOr(ts`Event updated`)->React.string}
                </span>
                <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
                  {timeStr->React.string}
                </span>
              </div>
            </div>
          </div>
        | "rsvp_created" =>
          <div key=msg.id className="flex gap-2.5">
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400">
              <Lucide.UserPlus className="w-3 h-3" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline gap-1.5">
                <span className="text-xs text-gray-700 dark:text-gray-300">
                  <span className="font-medium"> {actor->React.string} </span>
                  {" joined the event"->React.string}
                </span>
                <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
                  {timeStr->React.string}
                </span>
              </div>
            </div>
          </div>
        | "rsvp_added" =>
          <div key=msg.id className="flex gap-2.5">
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 bg-green-50 dark:bg-green-900/20 text-green-600 dark:text-green-400">
              <Lucide.UserPlus className="w-3 h-3" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline gap-1.5">
                <span className="text-xs text-gray-700 dark:text-gray-300">
                  <span className="font-medium"> {actor->React.string} </span>
                  {" was added to the event by admin"->React.string}
                </span>
                <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
                  {timeStr->React.string}
                </span>
              </div>
            </div>
          </div>
        | "rsvp_promoted" =>
          <div key=msg.id className="flex gap-2.5">
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400">
              <Lucide.ArrowUpCircle className="w-3 h-3" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline gap-1.5">
                <span className="text-xs text-gray-700 dark:text-gray-300">
                  <span className="font-medium"> {actor->React.string} </span>
                  {" joined from waitlist"->React.string}
                </span>
                <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
                  {timeStr->React.string}
                </span>
              </div>
            </div>
          </div>
        | "rsvp_deleted" | "rsvp_removed" =>
          <div key=msg.id className="flex gap-2.5">
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 bg-red-50 dark:bg-red-900/20 text-red-500 dark:text-red-400">
              <Lucide.UserX className="w-3 h-3" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline gap-1.5">
                <span className="text-xs text-gray-700 dark:text-gray-300">
                  <span className="font-medium"> {actor->React.string} </span>
                  {" left the event"->React.string}
                </span>
                <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
                  {timeStr->React.string}
                </span>
              </div>
            </div>
          </div>
        | _ =>
          <div key=msg.id className="flex gap-2.5">
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 mt-0.5 bg-amber-50 dark:bg-amber-900/20 text-amber-600 dark:text-amber-400">
              <Lucide.AlertCircle className="w-3 h-3" />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-baseline gap-1.5">
                <span className="text-xs text-gray-700 dark:text-gray-300">
                  <span className="font-medium"> {actor->React.string} </span>
                  {details->Option.map(d => " " ++ d)->Option.getOr("")->React.string}
                </span>
                <span className="font-mono text-[10px] text-gray-400 dark:text-gray-500">
                  {timeStr->React.string}
                </span>
              </div>
            </div>
          </div>
        }
      })
      ->React.array}
    </div>
    {allMessages->Array.length > 5
      ? <button
          className="mt-3 font-mono text-[11px] text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 transition-colors"
          onClick={_ => setShowAllActivity(v => !v)}>
          {(
            showAllActivity
              ? ts`Show less`
              : ts`Show all ${Int.toString(allMessages->Array.length)} items`
          )->React.string}
        </button>
      : React.null}
    /* Message input */
    <div
      className="mt-4 flex items-center gap-2 border border-gray-200 dark:border-[#3a3b40] rounded-lg px-2.5 py-1.5 focus-within:border-gray-400 dark:focus-within:border-gray-500 transition-colors">
      <input
        className="flex-1 bg-transparent text-sm text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 border-0 outline-none focus:outline-none focus:ring-0"
        placeholder={ts`Add a message...`}
        value=messageInput
        onChange={e => setMessageInput(_ => ReactEvent.Form.target(e)["value"])}
        onKeyDown={e => {
          if ReactEvent.Keyboard.key(e) == "Enter" && isJoined {
            onSendMessage()
          }
        }}
      />
      <button
        className={Util.cx([
          "flex-shrink-0 transition-colors",
          isJoined && messageInput->String.trim != ""
            ? "text-[#65a30d] dark:text-[#bdf25d] hover:text-[#4d7c0f]"
            : "text-gray-300 dark:text-gray-600",
        ])}
        disabled={!isJoined || sendingMessage || messageInput->String.trim == ""}
        onClick={_ => onSendMessage()}>
        <Lucide.Send className="w-3.5 h-3.5" />
      </button>
    </div>
  </div>
}

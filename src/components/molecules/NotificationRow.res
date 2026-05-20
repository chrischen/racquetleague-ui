%%raw("import { t } from '@lingui/macro'")

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
  } else if hours < 48 {
    "Yesterday"
  } else {
    Int.toString(hours / 24) ++ "d ago"
  }
}

type decodedPayload = {
  actorUserName: option<string>,
  activityType: option<string>,
  details: option<string>,
  eventId: option<string>,
  eventName: option<string>,
  clubSlug: option<string>,
}

let decodeId = (json: Js.Json.t): option<string> =>
  switch json->Js.Json.decodeArray {
  | Some(arr) =>
    switch (
      arr->Array.get(0)->Option.flatMap(v => Js.Json.decodeString(v)),
      arr->Array.get(1)->Option.flatMap(v => Js.Json.decodeString(v)),
    ) {
    | (Some(prefix), Some(rawId)) => Some(prefix ++ "_" ++ rawId)
    | _ => None
    }
  | None => None
  }

let decodePayload = (s: string): option<decodedPayload> =>
  try {
    switch s->Js.Json.parseExn->Js.Json.decodeObject {
    | Some(d) =>
      Some({
        actorUserName: d->Js.Dict.get("actorUserName")->Option.flatMap(Js.Json.decodeString(_)),
        activityType: d->Js.Dict.get("activityType")->Option.flatMap(Js.Json.decodeString(_)),
        details: d->Js.Dict.get("details")->Option.flatMap(Js.Json.decodeString(_)),
        eventId: d->Js.Dict.get("eventId")->Option.flatMap(decodeId),
        eventName: d->Js.Dict.get("eventName")->Option.flatMap(Js.Json.decodeString(_)),
        clubSlug: d->Js.Dict.get("clubSlug")->Option.flatMap(Js.Json.decodeString(_)),
      })
    | None => None
    }
  } catch {
  | _ => None
  }

let activityTypeFromTopic = (topic: string): string => {
  let parts = topic->Js.String2.split(".")
  parts->Array.get(1)->Option.getOr(topic)
}

let entityUrl = (activityType: string, decoded: option<decodedPayload>): option<string> =>
  switch activityType {
  | "user_joined_club" =>
    decoded->Option.flatMap(p => p.clubSlug)->Option.map(slug => "/clubs/" ++ slug ++ "/members")
  | _ => decoded->Option.flatMap(p => p.eventId)->Option.map(id => "/events/" ++ id)
  }

let synthesizeTitle = (activityType: string, ~details: option<string>): string => {
  let ts = Lingui.UtilString.t
  switch activityType {
  | "host_message" => ts`Host Message`
  | "comment_added" => ts`New Comment`
  | "rsvp_created" => ts`Joined`
  | "rsvp_added" => ts`Added to Event`
  | "rsvp_promoted" => ts`Off Waitlist`
  | "rsvp_deleted" => ts`Left Event`
  | "rsvp_removed" => ts`Removed from Event`
  | "user_joined_club" => ts`Joined Club`
  | "event_status" =>
    switch details {
    | Some("canceled") => ts`Event Canceled`
    | _ => ts`Event Uncanceled`
    }
  | _ => ts`Notification`
  }
}

module Icon = {
  @react.component
  let make = (~activityType: string, ~details: option<string>, ~compact: bool=false) => {
    let iconSize = compact ? "w-3 h-3" : "w-3.5 h-3.5"
    let wrapperSize = compact ? "w-7 h-7" : "w-8 h-8"
    let (bg, fg, icon) = switch activityType {
    | "rsvp_created" => (
        "bg-emerald-100 dark:bg-emerald-900/30",
        "text-emerald-600 dark:text-emerald-400",
        <Lucide.CheckCircle2 className=iconSize />,
      )
    | "rsvp_added" => (
        "bg-emerald-100 dark:bg-emerald-900/30",
        "text-emerald-600 dark:text-emerald-400",
        <Lucide.UserPlus className=iconSize />,
      )
    | "rsvp_promoted" => (
        "bg-blue-100 dark:bg-blue-900/30",
        "text-blue-600 dark:text-blue-400",
        <Lucide.ArrowUpCircle className=iconSize />,
      )
    | "rsvp_deleted" => (
        "bg-red-100 dark:bg-red-900/30",
        "text-red-600 dark:text-red-400",
        <Lucide.X className=iconSize />,
      )
    | "rsvp_removed" => (
        "bg-orange-100 dark:bg-orange-900/30",
        "text-orange-600 dark:text-orange-400",
        <Lucide.X className=iconSize />,
      )
    | "host_message" => (
        "bg-indigo-100 dark:bg-indigo-900/30",
        "text-indigo-600 dark:text-indigo-400",
        <Lucide.MessageCircle className=iconSize />,
      )
    | "comment_added" => (
        "bg-sky-100 dark:bg-sky-900/30",
        "text-sky-600 dark:text-sky-400",
        <Lucide.MessageCircle className=iconSize />,
      )
    | "user_joined_club" => (
        "bg-violet-100 dark:bg-violet-900/30",
        "text-violet-600 dark:text-violet-400",
        <Lucide.Users className=iconSize />,
      )
    | "event_status" =>
      switch details {
      | Some("canceled") => (
          "bg-red-100 dark:bg-red-900/30",
          "text-red-600 dark:text-red-400",
          <Lucide.Calendar className=iconSize />,
        )
      | _ => (
          "bg-emerald-100 dark:bg-emerald-900/30",
          "text-emerald-600 dark:text-emerald-400",
          <Lucide.Calendar className=iconSize />,
        )
      }
    | _ => (
        "bg-gray-100 dark:bg-[#2a2b30]",
        "text-gray-500 dark:text-gray-400",
        <Lucide.Bell className=iconSize />,
      )
    }
    <div
      className={`${wrapperSize} rounded-full ${bg} ${fg} flex items-center justify-center flex-shrink-0`}>
      {icon}
    </div>
  }
}

// compact=false  → full inbox row (Link navigation, dismiss button)
// compact=true   → popover row (onClick navigation, no dismiss)
// onDismiss      → shows dismiss button when provided (non-compact)
// onNavigate     → called with the resolved URL when the row is clicked (compact)
@react.component
let make = (
  ~topic: string,
  ~payload: option<string>,
  ~createdAt: string,
  ~compact: bool=false,
  ~onDismiss: unit => unit=?,
  ~onNavigate: string => unit=?,
) => {
  let decoded = payload->Option.flatMap(decodePayload)
  let actor = decoded->Option.flatMap(d => d.actorUserName)
  let details = decoded->Option.flatMap(d => d.details)->Option.getOr("")
  let eventName = decoded->Option.flatMap(d => d.eventName)
  let activityType =
    decoded
    ->Option.flatMap(d => d.activityType)
    ->Option.getOr(activityTypeFromTopic(topic))
  let url = entityUrl(activityType, decoded)
  let title = synthesizeTitle(activityType, ~details=decoded->Option.flatMap(d => d.details))
  let timeStr = relativeTimeStr(createdAt)

  let subInfo =
    <>
      {actor
      ->Option.map(a =>
        <p
          className={compact
            ? "text-[11px] font-medium text-gray-700 dark:text-gray-300 mt-0.5 leading-snug"
            : "text-xs font-medium text-gray-700 dark:text-gray-300 mt-0.5"}>
          {a->React.string}
        </p>
      )
      ->Option.getOr(React.null)}
      {eventName
      ->Option.map(name =>
        <p
          className="font-mono text-[10px] text-gray-400 dark:text-gray-500 mt-0.5 inline-flex items-center gap-1">
          <Lucide.Calendar size={compact ? 9 : 10} />
          {name->React.string}
        </p>
      )
      ->Option.getOr(React.null)}
      {details != ""
        ? <p
            className={compact
              ? "text-[11px] text-gray-600 dark:text-gray-400 mt-0.5 line-clamp-2 leading-snug"
              : "text-xs text-gray-600 dark:text-gray-400 mt-0.5 leading-snug"}>
            {details->React.string}
          </p>
        : React.null}
    </>

  let info = if compact {
    <div className="flex-1 min-w-0">
      <div className="flex items-start justify-between gap-2">
        <h4 className="text-xs font-medium text-gray-900 dark:text-gray-100 leading-snug truncate">
          {title->React.string}
        </h4>
        <span
          className="font-mono text-[10px] text-gray-400 dark:text-gray-500 flex-shrink-0 whitespace-nowrap">
          {timeStr->React.string}
        </span>
      </div>
      {subInfo}
    </div>
  } else {
    <div className="flex-1 min-w-0">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          <h3 className="text-sm font-medium text-gray-900 dark:text-gray-100 leading-snug">
            {title->React.string}
          </h3>
          {subInfo}
        </div>
        <span
          className="font-mono text-[10px] text-gray-400 dark:text-gray-500 flex-shrink-0 pt-0.5 whitespace-nowrap">
          {timeStr->React.string}
        </span>
      </div>
    </div>
  }

  let content =
    <>
      <Icon activityType details={decoded->Option.flatMap(d => d.details)} compact />
      {info}
    </>

  if compact {
    let baseClass = "relative flex items-start gap-2.5 px-4 py-3 transition-colors hover:bg-gray-50 dark:hover:bg-[#2a2b30]"
    switch (url, onNavigate) {
    | (Some(u), Some(nav)) =>
      <div className={baseClass ++ " cursor-pointer"} onClick={_ => nav(u)}>
        {content}
      </div>
    | _ =>
      <div className=baseClass>
        {content}
      </div>
    }
  } else {
    <div
      className="group relative flex items-start gap-3 px-4 py-3.5 transition-colors hover:bg-gray-50 dark:hover:bg-[#2a2b30]">
      {switch url {
      | Some(u) =>
        <LangProvider.Router.Link to=u className="flex items-start gap-3 flex-1 min-w-0">
          {content}
        </LangProvider.Router.Link>
      | None => <div className="flex items-start gap-3 flex-1 min-w-0"> {content} </div>
      }}
      {switch onDismiss {
      | Some(dismiss) =>
        <button
          onClick={e => {
            e->ReactEvent.Mouse.stopPropagation
            dismiss()
          }}
          className="opacity-0 group-hover:opacity-100 transition-opacity text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 flex-shrink-0 mt-0.5"
          title="Dismiss">
          <Lucide.X size=13 />
        </button>
      | None => React.null
      }}
    </div>
  }
}

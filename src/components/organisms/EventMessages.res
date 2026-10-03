%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
module Fragment = %relay(`
  fragment EventMessages_query on Query
  @argumentDefinitions(topic: { type: "String!" }, 
    after: { type: "String" }
    before: { type: "String" }
    first: { type: "Int", defaultValue: 80 }) {
    __id
    messagesByTopic(topic: $topic, after: $after, first: $first, before: $before) @connection(key: "EventMessages_messagesByTopic") {
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

// Mutation to update the viewer's RSVP status message
module EventMessagesUpdateViewerRsvpMessageMutation = %relay(`
  mutation EventMessagesUpdateViewerRsvpMessageMutation($connections: [ID!]!, $input: UpdateViewerRsvpMessageInput!) {
    updateViewerRsvpMessage(input: $input) {
      rsvp {
        id
        message
      }
      edge @prependEdge(connections: $connections)  {
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

// Temporarily patch this binding as it's not in the nodejs package
@module("date-fns")
external differenceInHours: (Js.Date.t, Js.Date.t) => int = "differenceInHours"

type payloadType = {
  actorUserName: option<string>,
  activityType: option<string>,
  details: option<string>,
}

// Helper function to safely decode the payload
let decodePayload = (payloadString: string): option<payloadType> => {
  try {
    let json = payloadString->Js.Json.parseExn
    switch json->Js.Json.decodeObject {
    | Some(dict) =>
      Some({
        actorUserName: dict->Js.Dict.get("actorUserName")->Option.flatMap(Js.Json.decodeString(_)),
        activityType: dict->Js.Dict.get("activityType")->Option.flatMap(Js.Json.decodeString(_)),
        details: dict->Js.Dict.get("details")->Option.flatMap(Js.Json.decodeString(_)),
      })
    | None => None
    }
  } catch {
  | _ => None // Handle JSON parsing errors
  }
}

// Message component for updating viewer's RSVP status message
module Message = {
  @react.component
  let make = (~eventId: string) => {
    let ts = Lingui.UtilString.t
    let (editedMessage, setEditedMessage) = React.useState(() => "")
    let (commitUpdate, _inFlight) = EventMessagesUpdateViewerRsvpMessageMutation.use()

    let onSave = () => {
      let trimmedMessage = editedMessage->String.trim
      if trimmedMessage != "" {
        let connectionId =
          "client:root"
          ->RescriptRelay.makeDataId
          ->Fragment.Operation.makeConnectionId(~topic=eventId ++ ".updated")
        commitUpdate(
          ~variables={connections: [connectionId], input: {eventId, message: trimmedMessage}},
        )->RescriptRelay.Disposable.ignore
        setEditedMessage(_ => "")
      }
    }

    let onSubmit = e => {
      ReactEvent.Form.preventDefault(e)
      onSave()
    }

    <div className="mb-4">
      <label className="block text-sm font-medium text-gray-700 dark:text-gray-300">
        {(ts`Status message`)->React.string}
      </label>
      <form onSubmit={onSubmit} className="mt-1 flex gap-2">
        <input
          value=editedMessage
          onChange={e => setEditedMessage(ReactEvent.Form.target(e)["value"])}
          className="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6 dark:bg-[#222326] dark:text-gray-100 dark:ring-[#3a3b40] dark:placeholder:text-gray-500"
          placeholder={ts`Type a status message for people to see... such as 'I will arrive at 19:00.'`}
        />
        <button
          type_="submit"
          className="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600">
          {(ts`Send`)->React.string}
        </button>
      </form>
    </div>
  }
}

@react.component
let make = (
  ~queryRef: RescriptRelay.fragmentRefs<[> #EventMessages_query]>,
  ~eventStartDate: Js.Date.t,
  ~eventId: string,
  ~viewerHasRsvp: option<bool>=?,
) => {
  let ts = Lingui.UtilString.t
  let data = Fragment.use(queryRef)
  let messages = data.messagesByTopic->Fragment.getConnectionNodes

  <div
    className="bg-white rounded-lg shadow-sm p-4 md:p-5 mt-4 dark:bg-[#1e1f23] dark:ring-1 dark:ring-[#2a2b30]">
    <h2 className="text-lg font-semibold mb-4 text-gray-900 dark:text-gray-100">
      {t`Activity`}
    </h2>
    {viewerHasRsvp
    ->Option.map(has => has ? <Message eventId /> : React.null)
    ->Option.getOr(React.null)}
    {messages->Array.length == 0
      ? <div className="text-center py-8">
          <div className="text-gray-400 dark:text-gray-500 mb-2">
            <Lucide.MessageCircle className="size-12 mx-auto opacity-50" />
          </div>
          <p className="text-gray-500 dark:text-gray-400 text-sm">
            {(ts`No activity yet`)->React.string}
          </p>
        </div>
      : <div className="space-y-4">
          {messages
          ->Array.map(message => {
            let decodedPayload = message.payload->Option.flatMap(decodePayload)
            let actorUserName =
              decodedPayload->Option.flatMap(p => p.actorUserName)->Option.getOr("Unknown User")
            let activityTypeOpt = decodedPayload->Option.flatMap(p => p.activityType)
            let detailsOpt = decodedPayload->Option.flatMap(p => p.details)

            let (iconElem, iconWrapperClass) = switch activityTypeOpt->Option.getOr("") {
            | "host_message" => (
                <Lucide.MessageCircle className="size-4 text-indigo-600 dark:text-indigo-400" />,
                "bg-indigo-100 dark:bg-indigo-900/30",
              )
            | "user_message" => (
                <Lucide.MessageCircle className="size-4 text-slate-600 dark:text-slate-300" />,
                "bg-slate-100 dark:bg-slate-700/40",
              )
            | "rsvp_created" => (
                <Lucide.Check className="size-4 text-green-600 dark:text-green-400" />,
                "bg-green-100 dark:bg-green-900/30",
              )
            | "rsvp_added" => (
                <Lucide.UserPlus className="size-4 text-green-600 dark:text-green-400" />,
                "bg-green-100 dark:bg-green-900/30",
              )
            | "rsvp_invited" => (
                <Lucide.Mail className="size-4 text-violet-600 dark:text-violet-400" />,
                "bg-violet-100 dark:bg-violet-900/30",
              )
            | "rsvp_promoted" => (
                <Lucide.ArrowUpCircle className="size-4 text-blue-600 dark:text-blue-400" />,
                "bg-blue-100 dark:bg-blue-900/30",
              )
            | "rsvp_deleted" => (
                <Lucide.X className="size-4 text-red-600 dark:text-red-400" />,
                "bg-red-100 dark:bg-red-900/30",
              )
            | "rsvp_removed" => (
                <Lucide.X className="size-4 text-orange-600 dark:text-orange-400" />,
                "bg-orange-100 dark:bg-orange-900/30",
              )
            | "update" => (
                <Lucide.Bell className="size-4 text-blue-600 dark:text-blue-400" />,
                "bg-blue-100 dark:bg-blue-900/30",
              )
            | _ => (
                <Lucide.User className="size-4 text-gray-600 dark:text-gray-300" />,
                "bg-gray-100 dark:bg-gray-700/40",
              )
            }

            let mainMessageText = switch activityTypeOpt {
            | Some("host_message") | Some("user_message") => detailsOpt->Option.getOr("")
            | Some("rsvp_created") => detailsOpt->Option.getOr(ts`joined the event`)
            | Some("rsvp_added") => detailsOpt->Option.getOr(ts`was added to the event by admin`)
            // The inviter's note is a private message, never shown here.
            | Some("rsvp_invited") => ts`was invited to the event`
            | Some("rsvp_promoted") => detailsOpt->Option.getOr(ts`joined from waitlist`)
            | Some("rsvp_deleted") => detailsOpt->Option.getOr(ts`left the event`)
            | Some("rsvp_removed") =>
              detailsOpt->Option.getOr(ts`was removed from the event by admin`)
            | _ => detailsOpt->Option.getOr("")
            }

            let actorNameEl = switch activityTypeOpt {
            | Some("host_message") =>
              <span className="font-medium text-indigo-600 dark:text-indigo-400">
                {React.string(actorUserName)}
              </span>
            | _ =>
              <span className="font-medium text-gray-900 dark:text-gray-100">
                {React.string(actorUserName)}
              </span>
            }

            // time color class (only varies for rsvp_deleted and rsvp_removed)
            let timeClassName = switch activityTypeOpt {
            | Some("rsvp_deleted") | Some("rsvp_removed") =>
              switch message.createdAt->Js.Json.string->Util.Datetime.parse->Util.Datetime.toDate {
              | messageCreatedAtDate =>
                let diffHours = differenceInHours(eventStartDate, messageCreatedAtDate)
                if diffHours < 24 {
                  "text-red-600 dark:text-red-400 font-medium"
                } else if diffHours < 48 {
                  "text-yellow-600 dark:text-yellow-500 font-medium"
                } else {
                  "text-gray-500 dark:text-gray-400"
                }
              }
            | _ => "text-gray-500 dark:text-gray-400"
            }

            let dt = message.createdAt->Js.Json.string->Util.Datetime.parse->Util.Datetime.toDate

            <div key=message.id className="flex">
              <div className="mr-3 mt-1">
                <div className={Util.cx([iconWrapperClass, "p-2 rounded-full"])}> {iconElem} </div>
              </div>
              <div className="flex-1">
                {mainMessageText == ""
                  ? React.null
                  : <p className="text-gray-700 dark:text-gray-300">
                      {React.string(mainMessageText)}
                    </p>}
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                  {actorNameEl}
                  {React.string(" • ")}
                  <span className={timeClassName}>
                    <ReactIntl.FormattedDate value={dt} month=#short day=#numeric />
                    {React.string(" ")}
                    <ReactIntl.FormattedTime value={dt} />
                  </span>
                </p>
              </div>
            </div>
          })
          ->React.array}
        </div>}
  </div>
}

%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
module Fragment = %relay(`
  fragment EventMessages_query on Query
  @argumentDefinitions(topic: { type: "String!" }) {
    messagesByTopic(topic: $topic) {
      id
      createdAt
      payload
      topic
    }
  }
`)

type payloadType = {
  actorUserName: option<string>,
  activityType: option<string>,
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
      })
    | None => None
    }
  } catch {
  | _ => None // Handle JSON parsing errors
  }
}

@react.component
let make = (~queryRef: RescriptRelay.fragmentRefs<[> #EventMessages_query]>) => {
  let ts = Lingui.UtilString.t
  let data = Fragment.use(queryRef)
  let messages = data.messagesByTopic

  messages->Array.length > 0
    ? <div className="flow-root mt-4">
        <ul role="list" className="-mb-8">
          {messages
          ->Array.mapWithIndex((message, index) => {
            // Decode the payload for each message
            let decodedPayload = message.payload->Option.flatMap(decodePayload)

            // Extract actorUserName, default to "Unknown User"
            let actorUserName =
              decodedPayload
              ->Option.flatMap(p => p.actorUserName)
              ->Option.getOr("Unknown User")

            // Default icon for messages
            let (icon, iconBackground, description) = switch decodedPayload->Option.flatMap(p =>
              p.activityType
            ) {
            | Some("rsvp_deleted") => (
                <Lucide.X className="size-5 text-white" />, // Red X icon
                "bg-red-500", // Red background
                Some(ts`left the event`), // Description text
              )
            | _ => (<Lucide.User className="size-5 text-white" />, "bg-gray-400", None) // Default User icon // Default gray background // No description by default
            }

            <li key=message.id>
              <div className="relative pb-8">
                {index !== messages->Array.length - 1
                  ? <span
                      ariaHidden=true
                      className="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200"
                    />
                  : React.null}
                <div className="relative flex space-x-3">
                  <div>
                    <span
                      className={Util.cx([
                        iconBackground,
                        "flex size-8 items-center justify-center rounded-full ring-8 ring-white",
                      ])}>
                      {icon}
                    </span>
                  </div>
                  <div className="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
                    <div>
                      <p className="text-sm text-gray-900 font-medium">
                        {actorUserName->React.string}
                      </p>
                      {description
                      ->Option.map(desc =>
                        <p className="text-sm text-gray-500 italic"> {desc->React.string} </p>
                      )
                      ->Option.getOr(React.null)}
                    </div>
                    <div className="whitespace-nowrap text-right text-sm text-gray-500">
                      <time dateTime={message.createdAt}>
                        <ReactIntl.FormattedRelativeTime
                          value={message.createdAt
                          ->Js.Json.string
                          ->Util.Datetime.parse
                          ->Util.Datetime.toDate
                          ->DateFns.differenceInMinutes(Js.Date.make())}
                          unit=#minute
                          numeric=#always
                          updateIntervalInSeconds=60.
                        />
                      </time>
                    </div>
                  </div>
                </div>
              </div>
            </li>
          })
          ->React.array}
        </ul>
      </div>
    : React.null
}

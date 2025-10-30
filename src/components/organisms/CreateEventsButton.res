%%raw("import { t } from '@lingui/macro'")

// Mutation for creating events
module Mutation = %relay(`
 mutation CreateEventsButtonMutation(
   $connections: [ID!]!
   $input: CreateEventsInput!
 ) {
   createEvents(input: $input) {
     events @appendNode(connections: $connections, edgeTypeName: "EventEdge") {
       __typename
       id
       title
       details
       activity {
         id
         name
         slug
       }
       startDate
       endDate
       listed
     }
   }
 }
`)

external alert: string => unit = "alert"

@react.component
let make = (
  ~events: array<AITypes.eventDetails>,
  ~activitySlug: string,
  ~clubId: option<string>=?,
  ~onEventsCreated: option<unit => unit>=?,
) => {
  let ts = Lingui.UtilString.t
  let (commitMutation, _isMutationInFlight) = Mutation.use()
  let navigate = Router.useNavigate()

  let eventCount = events->Array.length

  // Determine button text based on event count
  let buttonText = if eventCount == 1 {
    ts`Create This Event`
  } else {
    ts`Create All Events`
  }

  // Helper function to convert events to the text format expected by CreateClubEventsForm
  let formatEventsForBulkCreate = (events: array<AITypes.eventDetails>): string => {
    events
    ->Array.map(event => {
      // Parse start and end date strings
      let startDateObj = Js.Date.fromString(event.date)
      let endDateObj = Js.Date.fromString(event.time)

      let month = Float.toInt(startDateObj->Js.Date.getMonth +. 1.0)
      let day = Float.toInt(startDateObj->Js.Date.getDate)

      let startHours = Float.toInt(startDateObj->Js.Date.getHours)
      let startMinutes = Float.toInt(startDateObj->Js.Date.getMinutes)
      let endHours = Float.toInt(endDateObj->Js.Date.getHours)
      let endMinutes = Float.toInt(endDateObj->Js.Date.getMinutes)

      // Format time range: "5-6pm" or "10:30am-12pm"
      let formatTime = (hours, minutes) => {
        let period = hours >= 12 ? "pm" : "am"
        let displayHours = hours > 12 ? hours - 12 : hours == 0 ? 12 : hours

        if minutes == 0 {
          `${displayHours->Int.toString}${period}`
        } else {
          let padZero = num => num < 10 ? `0${num->Int.toString}` : num->Int.toString
          `${displayHours->Int.toString}:${padZero(minutes)}${period}`
        }
      }

      // Date line: "10/1 5-6pm"
      let startTime = formatTime(startHours, startMinutes)
      let endTime = formatTime(endHours, endMinutes)
      let dateLine = `${month->Int.toString}/${day->Int.toString} ${startTime}-${endTime}`

      // Build lines array
      let lines = [dateLine]

      // Add location if present
      event.location->Option.forEach(loc => {
        lines->Array.push(loc)->ignore
      })

      // Add title
      lines->Array.push(event.title)->ignore

      // Add description if present
      event.description->Option.forEach(desc => {
        lines->Array.push(desc)->ignore
      })

      // Add maxRsvps if present
      event.maxRsvps->Option.forEach(max => {
        lines->Array.push(`Max ${max->Int.toString} people.`)->ignore
      })

      lines->Array.join("\n")
    })
    ->Array.join("\n\n")
  }

  <button
    onClick={_ => {
      let formattedText = formatEventsForBulkCreate(events)
      Js.log2("Formatted events for bulk create:", formattedText)

      // Get connection ID for updating the events list
      let connectionId = RescriptRelay.ConnectionHandler.getConnectionID(
        "client:root"->RescriptRelay.makeDataId,
        "EventsListFragment_events",
        (),
      )

      // Call the mutation
      commitMutation(
        ~variables={
          input: {
            input: formattedText,
            activitySlug,
            listed: true,
            ?clubId,
          },
          connections: [connectionId],
        },
        ~onCompleted=(mutationResponse, _errors) => {
          let createdEvents = mutationResponse.createEvents.events->Option.getOr([])
          let count = createdEvents->Array.length

          // Call the callback to notify parent (e.g., to dismiss dialog)
          onEventsCreated->Option.forEach(callback => callback())

          if count == 1 {
            // Redirect to the event page if only one event was created
            createdEvents[0]->Option.forEach(event => {
              navigate(`/events/${event.id}`, None)
            })
          } else {
            alert(ts`${count->Int.toString} events created!`)
          }
        },
        ~onError=_error => {
          alert(ts`Error creating events. Please try again.`)
        },
      )->RescriptRelay.Disposable.ignore
    }}
    className="w-full px-6 py-3 bg-gradient-to-r from-purple-500 to-blue-500 hover:from-purple-600 hover:to-blue-600 text-white rounded-2xl font-medium transition-all shadow-lg shadow-purple-500/25">
    {React.string(buttonText)}
  </button>
}

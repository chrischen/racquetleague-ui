%%raw("import { t } from '@lingui/macro'")

// A draft's times are instants; show them in the zone the draft names, as the
// create form will after prefill. Without one the IntlProvider default
// (Asia/Tokyo) applies, which is also the form's fallback.
let draftTimezone = (rawFields: option<Js.Dict.t<Js.Json.t>>) =>
  rawFields
  ->Option.flatMap(fields => fields->Js.Dict.get("timezone"))
  ->Option.flatMap(value => value->Js.Json.decodeString)

@react.component
let make = (
  ~response: AITypes.aiResponse,
  // A single draft fills the create form; a batch is accepted as its schedule.
  // Nothing is created until that form is submitted.
  ~onFillForm: AITypes.eventDetails => unit,
  ~onAcceptEvents: array<AITypes.eventDetails> => unit,
  ~summaryClassName="rounded-xl border border-gray-200 bg-white px-3.5 py-3 text-sm leading-relaxed text-gray-700 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-300",
) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let actionClass = "inline-flex items-center gap-1.5 rounded-lg bg-[#bdf25d] px-3 py-2 text-xs font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a]"
  let createAction = (events: array<AITypes.eventDetails>) =>
    switch events {
    | [event] =>
      <button type_="button" onClick={_ => onFillForm(event)} className=actionClass>
        <Lucide.Pencil size=13 \"aria-hidden"="true" />
        <span> {t`Fill form`} </span>
      </button>
    | _ =>
      <button type_="button" onClick={_ => onAcceptEvents(events)} className=actionClass>
        <Lucide.Check size=13 strokeWidth=2.5 \"aria-hidden"="true" />
        <span> {(ts`Accept ${events->Array.length->Int.toString} events`)->React.string} </span>
      </button>
    }
  <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-300">
    // AI Summary
    <p className=summaryClassName> {response.summary->React.string} </p>
    // Event Details Card
    {response.eventDetails
    ->Option.map(details => {
      <div
        className="space-y-3 rounded-xl border border-gray-200 bg-white p-4 dark:border-[#3a3b40] dark:bg-[#222326]">
        <h3
          className="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-gray-100">
          <Lucide.Calendar className="w-4 h-4" />
          {t`Event Details`}
        </h3>
        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400"> {t`Title:`} </span>
            <span className="font-medium text-gray-900 dark:text-gray-100">
              {details.title->React.string}
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400"> {t`Date:`} </span>
            <span className="font-medium text-gray-900 dark:text-gray-100">
              {
                let startDate = Js.Date.fromString(details.date)
                let endDate = Js.Date.fromString(details.time)
                let tz = draftTimezone(details.rawFields)
                <>
                  <ReactIntl.FormattedDate
                    day=#"2-digit"
                    month=#numeric
                    year={#"2-digit"}
                    weekday=#long
                    value={startDate}
                    timeZone=?tz
                  />
                  {" "->React.string}
                  <ReactIntl.FormattedTime value={startDate} timeZone=?tz />
                  {" -> "->React.string}
                  <ReactIntl.FormattedTime value={endDate} timeZone=?tz />
                </>
              }
            </span>
          </div>
          {details.location
          ->Option.map(location => {
            <div className="flex justify-between">
              <span className="text-gray-500 dark:text-gray-400"> {t`Location:`} </span>
              <span className="font-medium text-gray-900 dark:text-gray-100">
                {location->React.string}
              </span>
            </div>
          })
          ->Option.getOr(React.null)}
          {details.description
          ->Option.map(description => {
            <div className="border-t border-gray-100 pt-2 dark:border-[#34353a]">
              <span className="text-gray-500 dark:text-gray-400 block mb-1">
                {t`Description:`}
              </span>
              <p className="text-gray-700 dark:text-gray-300"> {description->React.string} </p>
            </div>
          })
          ->Option.getOr(React.null)}
        </div>
        {createAction([details])}
      </div>
    })
    ->Option.getOr(React.null)}
    // Suggested Events List
    {response.suggestedEvents
    ->Option.map(events => {
      events->Array.length > 0
        ? <div className="space-y-3">
            <h3
              className="flex items-center gap-2 text-sm font-semibold text-gray-900 dark:text-gray-100">
              <Lucide.Calendar className="w-4 h-4" />
              {t`Suggested Events`}
            </h3>
            {createAction(events)}
            {events
            ->Array.mapWithIndex((event, index) => {
              <div
                key={index->Int.toString}
                className="space-y-2 rounded-xl border border-gray-200 bg-white p-4 dark:border-[#3a3b40] dark:bg-[#222326]">
                <h4 className="font-semibold text-gray-900 dark:text-gray-100">
                  {event.title->React.string}
                </h4>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-500 dark:text-gray-400"> {t`Date:`} </span>
                    <span className="font-medium text-gray-900 dark:text-gray-100">
                      {
                        let startDate = Js.Date.fromString(event.date)
                        let endDate = Js.Date.fromString(event.time)
                        let tz = draftTimezone(event.rawFields)
                        <>
                          <ReactIntl.FormattedDate
                            day=#"2-digit"
                            month=#numeric
                            year={#"2-digit"}
                            weekday=#long
                            value={startDate}
                            timeZone=?tz
                          />
                          {" "->React.string}
                          <ReactIntl.FormattedTime value={startDate} timeZone=?tz />
                          {" -> "->React.string}
                          <ReactIntl.FormattedTime value={endDate} timeZone=?tz />
                        </>
                      }
                    </span>
                  </div>
                  {event.location
                  ->Option.map(
                    location => {
                      <div className="flex justify-between">
                        <span className="text-gray-500 dark:text-gray-400"> {t`Location:`} </span>
                        <span className="font-medium text-gray-900 dark:text-gray-100">
                          {location->React.string}
                        </span>
                      </div>
                    },
                  )
                  ->Option.getOr(React.null)}
                  {event.description
                  ->Option.map(
                    description => {
                      <div className="border-t border-gray-100 pt-2 dark:border-[#34353a]">
                        <p className="text-gray-600 dark:text-gray-400 text-xs">
                          {description->React.string}
                        </p>
                      </div>
                    },
                  )
                  ->Option.getOr(React.null)}
                </div>
              </div>
            })
            ->React.array}
          </div>
        : React.null
    })
    ->Option.getOr(React.null)}
  </div>
}

%%raw("import { t } from '@lingui/macro'")

@react.component
let make = (
  ~response: AITypes.aiResponse,
  ~activitySlug: string,
  ~clubId: option<string>=?,
  ~locationAddress: option<string>=?,
  ~onEventsCreated: option<unit => unit>=?,
) => {
  open Lingui.Util
  <div className="space-y-4 animate-in fade-in slide-in-from-bottom-4 duration-300">
    // AI Summary
    <div
      className="p-4 bg-gradient-to-br from-purple-50/80 to-blue-50/80 dark:from-purple-900/20 dark:to-blue-900/20 backdrop-blur-sm rounded-2xl border border-purple-200/50 dark:border-purple-700/30">
      <p className="text-gray-700 dark:text-gray-300 leading-relaxed">
        {response.summary->React.string}
      </p>
    </div>
    // Event Details Card
    {response.eventDetails
    ->Option.map(details => {
      <div
        className="p-5 bg-white/60 dark:bg-gray-800/60 backdrop-blur-sm rounded-2xl border border-gray-200/50 dark:border-gray-700/50 space-y-3">
        <h3 className="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
          <Lucide.Calendar className="w-4 h-4" />
          {t`Event Details`}
        </h3>
        <div className="space-y-2 text-sm">
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400"> {t`Title:`} </span>
            <span className="font-medium text-gray-900 dark:text-white">
              {details.title->React.string}
            </span>
          </div>
          <div className="flex justify-between">
            <span className="text-gray-500 dark:text-gray-400"> {t`Date:`} </span>
            <span className="font-medium text-gray-900 dark:text-white">
              {
                let startDate = Js.Date.fromString(details.date)
                let endDate = Js.Date.fromString(details.time)
                <>
                  <ReactIntl.FormattedDate
                    day=#"2-digit" month=#numeric year={#"2-digit"} weekday=#long value={startDate}
                  />
                  {" "->React.string}
                  <ReactIntl.FormattedTime value={startDate} />
                  {" -> "->React.string}
                  <ReactIntl.FormattedTime value={endDate} />
                </>
              }
            </span>
          </div>
          {details.location
          ->Option.map(location => {
            <div className="flex justify-between">
              <span className="text-gray-500 dark:text-gray-400"> {t`Location:`} </span>
              <span className="font-medium text-gray-900 dark:text-white">
                {location->React.string}
              </span>
            </div>
          })
          ->Option.getOr(React.null)}
          {details.description
          ->Option.map(description => {
            <div className="pt-2 border-t border-gray-200/50 dark:border-gray-700/50">
              <span className="text-gray-500 dark:text-gray-400 block mb-1">
                {t`Description:`}
              </span>
              <p className="text-gray-700 dark:text-gray-300"> {description->React.string} </p>
            </div>
          })
          ->Option.getOr(React.null)}
        </div>
        <CreateEventsButton events=[details] activitySlug ?clubId ?onEventsCreated />
      </div>
    })
    ->Option.getOr(React.null)}
    // Suggested Events List
    {response.suggestedEvents
    ->Option.map(events => {
      events->Array.length > 0
        ? <div className="space-y-3">
            <h3 className="font-semibold text-gray-900 dark:text-white flex items-center gap-2">
              <Lucide.Calendar className="w-4 h-4" />
              {t`Suggested Events`}
            </h3>
            <CreateEventsButton events activitySlug ?clubId ?onEventsCreated />
            {events
            ->Array.mapWithIndex((event, index) => {
              <div
                key={index->Int.toString}
                className="p-4 bg-white/60 dark:bg-gray-800/60 backdrop-blur-sm rounded-2xl border border-gray-200/50 dark:border-gray-700/50 space-y-2">
                <h4 className="font-semibold text-gray-900 dark:text-white">
                  {event.title->React.string}
                </h4>
                <div className="space-y-1 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-500 dark:text-gray-400"> {t`Date:`} </span>
                    <span className="font-medium text-gray-900 dark:text-white">
                      {
                        let startDate = Js.Date.fromString(event.date)
                        let endDate = Js.Date.fromString(event.time)
                        <>
                          <ReactIntl.FormattedDate
                            day=#"2-digit"
                            month=#numeric
                            year={#"2-digit"}
                            weekday=#long
                            value={startDate}
                          />
                          {" "->React.string}
                          <ReactIntl.FormattedTime value={startDate} />
                          {" -> "->React.string}
                          <ReactIntl.FormattedTime value={endDate} />
                        </>
                      }
                    </span>
                  </div>
                  {event.location
                  ->Option.map(
                    location => {
                      <div className="flex justify-between">
                        <span className="text-gray-500 dark:text-gray-400"> {t`Location:`} </span>
                        <span className="font-medium text-gray-900 dark:text-white">
                          {location->React.string}
                        </span>
                      </div>
                    },
                  )
                  ->Option.getOr(React.null)}
                  {event.description
                  ->Option.map(
                    description => {
                      <div className="pt-2 border-t border-gray-200/50 dark:border-gray-700/50">
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

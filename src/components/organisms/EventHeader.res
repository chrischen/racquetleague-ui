%%raw("import { t } from '@lingui/macro'")
open LangProvider.Router

module Fragment = %relay(`
  fragment EventHeader_event on Event {
    title
    startDate
    endDate
    timezone
    tags
    listed
    deleted
    shadow
    activity {
      name
      slug
    }
    club {
      name
      slug
    }
    location {
      id
      name
    }
  }
`)

@react.component
let make = (~event: RescriptRelay.fragmentRefs<[> #EventHeader_event]>) => {
  let ts = Lingui.UtilString.t
  let td = Lingui.UtilString.dynamic
  let data = Fragment.use(event)

  let until = data.startDate->Option.map(startDate =>
    startDate
    ->Util.Datetime.toDate
    ->DateFns.differenceInMinutes(Js.Date.make())
  )

  let duration = data.startDate->Option.flatMap(startDate =>
    data.endDate->Option.map(endDate =>
      endDate
      ->Util.Datetime.toDate
      ->DateFns.differenceInMinutes(startDate->Util.Datetime.toDate)
    )
  )
  let durationText = duration->Option.map(duration => {
    let hours = Js.Math.floor_float(duration /. 60.)
    let minutes = mod(duration->Float.toInt, 60)
    if minutes == 0 {
      ts`${hours->Float.toString} hours`
    } else {
      ts`${hours->Float.toString} hours and ${minutes->Int.toString} minutes`
    }
  })

  let activityComponent =
    data.activity
    ->Option.flatMap(activity =>
      activity.name->Option.map(name =>
        <Link to={"/?activity=" ++ activity.slug->Option.getOr("")}>
          {td(name)->React.string}
        </Link>
      )
    )
    ->Option.getOr("---"->React.string)

  let title = data.title->Option.getOr("Event")

  <WaitForMessages>
    {() =>
      <div className="bg-white shadow-md">
        <div className="p-4 md:p-6 border-b">
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900">
            <div className="flex items-center gap-x-3">
              {data.deleted
              ->Option.map(_ => <span className="mr-2"> {(ts`CANCELED`)->React.string} </span>)
              ->Option.getOr(React.null)}
              {data.tags
              ->Option.getOr([])
              ->Array.includes("comp")
                ? <div className="flex-none text-yellow-500">
                    <Lucide.Trophy className="h-6 w-6" />
                  </div>
                : React.null}
              <span className={Util.cx([data.deleted->Option.isSome ? "line-through" : ""])}>
                {activityComponent}
                {" / "->React.string}
                {title->React.string}
              </span>
            </div>
          </h1>
          <div className="flex flex-col sm:flex-row sm:items-center mt-1 text-gray-600">
            <div className="flex items-center">
              <Lucide.Users className="mr-1" />
              <span>
                {data.club
                ->Option.flatMap(club =>
                  club.name->Option.map(name =>
                    <Link to={"/clubs/" ++ club.slug->Option.getOr("")}>
                      {name->React.string}
                    </Link>
                  )
                )
                ->Option.getOr((ts`Unknown club`)->React.string)}
              </span>
            </div>
            {data.tags
            ->Option.map(tags => {
              let levelTags = ["all level", "3.0+", "3.5+", "4.0+", "4.5+", "5.0+"]
              let hasLevelTags = tags->Array.some(tag => levelTags->Array.includes(tag))
              let displayTags = hasLevelTags ? tags : tags->Array.concat(["all level"])
              let displayTags = switch data.listed {
              | Some(false) => displayTags->Array.concat(["unlisted"])
              | _ => displayTags
              }
              displayTags
            })
            ->Option.filter(tags => tags->Array.length > 0)
            ->Option.map(tags => <EventTag.TagList tags className="mt-2 sm:mt-0 sm:ml-3" />)
            ->Option.getOr(React.null)}
          </div>
        </div>
        <div className="p-4 md:p-6 bg-blue-50 border-b">
          <div className="md:flex md:justify-between">
            <div className="flex items-start mb-3 md:mb-0">
              <Lucide.CalendarClock className="text-blue-600 mt-1 mr-3 flex-shrink-0" />
              <div>
                <div className="font-semibold text-gray-900">
                  {data.startDate
                  ->Option.map(startDate =>
                    <ReactIntl.FormattedDate
                      day=#"2-digit"
                      month=#numeric
                      weekday=#long
                      value={startDate->Util.Datetime.toDate}
                      timeZone={data.timezone->Option.getOr("Asia/Tokyo")}
                    />
                  )
                  ->Option.getOr("Date TBD"->React.string)}
                  {" "->React.string}
                  {until
                  ->Option.map(until =>
                    <ReactIntl.FormattedRelativeTime
                      value={until} unit=#minute updateIntervalInSeconds=1.
                    />
                  )
                  ->Option.getOr(React.null)}
                  <AddToCalendar>
                    <Lucide.CalendarPlus
                      className="mr-1.5 h-5 w-5 flex-shrink-0 text-gray-500" \"aria-hidden"="true"
                    />
                  </AddToCalendar>
                </div>
                <div className="text-lg font-bold text-blue-700">
                  {data.startDate
                  ->Option.flatMap(startDate =>
                    data.endDate->Option.map(endDate => <>
                      <ReactIntl.FormattedTime
                        value={startDate->Util.Datetime.toDate}
                        timeZone={data.timezone->Option.getOr("Asia/Tokyo")}
                      />
                      {" -> "->React.string}
                      <ReactIntl.FormattedTime
                        value={endDate->Util.Datetime.toDate}
                        timeZone={data.timezone->Option.getOr("Asia/Tokyo")}
                      />
                    </>)
                  )
                  ->Option.getOr("Time TBD"->React.string)}
                  {durationText
                  ->Option.map(duration => <>
                    {" ("->React.string}
                    {duration->React.string}
                    {")"->React.string}
                  </>)
                  ->Option.getOr(React.null)}
                </div>
              </div>
            </div>
            <div className="flex items-center">
              <Lucide.MapPin className="text-blue-600 mr-3 flex-shrink-0" />
              <div>
                <div className="font-semibold text-gray-900">
                  {data.location
                  ->Option.flatMap(location =>
                    location.name->Option.map(name =>
                      data.shadow->Option.getOr(false)
                        ? name->React.string
                        : <Link to={"/locations/" ++ location.id}> {name->React.string} </Link>
                    )
                  )
                  ->Option.getOr((ts`Unknown location`)->React.string)}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>}
  </WaitForMessages>
}

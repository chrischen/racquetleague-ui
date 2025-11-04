module Fragment = %relay(`
	fragment EventDetails_event on Event {
		details
		shadow
		location {
            id
            name
            details
			...MediaList_location
			...EventLocation_location
		}
	}
`)

@react.component
let make = (~event) => {
  // Function to format text with line breaks as paragraphs
  let formatTextWithParagraphs = (text: string) => {
    text
    ->Js.String2.split("\n")
    ->Array.map(paragraph => paragraph->Js.String2.trim)
    ->Array.filter(paragraph => paragraph !== "")
    ->Array.mapWithIndex((paragraph, index) =>
      <p key={index->Int.toString} className="mb-2 last:mb-0"> {paragraph->React.string} </p>
    )
    ->React.array
  }
  let event = Fragment.use(event)
  let (activeTab, setActiveTab) = React.useState(() => "details")

  <div className="bg-white rounded-lg shadow-sm p-4 md:p-5 mt-4">
    <div className="flex border-b mb-4">
      <button
        className={Util.cx([
          "py-2 px-4 font-medium text-sm",
          activeTab == "details"
            ? "text-blue-600 border-b-2 border-blue-600"
            : "text-gray-500 hover:text-gray-700",
        ])}
        onClick={_ => setActiveTab(_ => "details")}>
        {React.string("Event Details")}
      </button>
      <button
        className={Util.cx([
          "py-2 px-4 font-medium text-sm",
          activeTab == "location"
            ? "text-blue-600 border-b-2 border-blue-600"
            : "text-gray-500 hover:text-gray-700",
        ])}
        onClick={_ => setActiveTab(_ => "location")}>
        {React.string("Location Details")}
      </button>
    </div>
    {activeTab == "details"
      ? <div className="flex">
          <Lucide.Info className="text-blue-600 mt-1 mr-3 flex-shrink-0" />
          <div className="text-gray-700 flex-1">
            {event.details
            ->Option.map(details => formatTextWithParagraphs(details))
            ->Option.getOr(React.null)}
          </div>
        </div>
      : React.null}
    {activeTab == "location"
      ? <div className="flex">
          <Lucide.MapPin className="text-blue-600 mt-1 mr-3 flex-shrink-0" />
          <div className="flex-1">
            {event.location
            ->Option.map(location => {
              let ref = location.fragmentRefs
              <>
                <EventLocation location=ref hideAddress={event.shadow->Option.getOr(false)} />
                <div className="mt-4">
                  <MediaList media=ref />
                </div>
              </>
            })
            ->Option.getOr(React.null)}
          </div>
        </div>
      : React.null}
  </div>
}

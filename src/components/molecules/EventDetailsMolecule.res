%%raw("import { t } from '@lingui/macro'")
// EventDetails molecule in ReScript React
// Props: event with organizerDetails and locationDetails

type event = {
  organizerDetails: string,
  locationDetails: string,
}

@react.component
let make = (~event: event) => {
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
            <PreformattedParagraph text={event.organizerDetails} />
          </div>
        </div>
      : React.null}
    {activeTab == "location"
      ? <div className="flex">
          <Lucide.MapPin className="text-blue-600 mt-1 mr-3 flex-shrink-0" />
          <div className="text-gray-700 flex-1">
            <PreformattedParagraph text={event.locationDetails} />
          </div>
        </div>
      : React.null}
  </div>
}

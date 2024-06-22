module Fragment = %relay(`
	fragment EventLocation_location on Location {
		name
		details
		address
		links
	}
`)
@react.component
let make = (~location) => {
  let location = Fragment.use(location)
  let defaultLink = location.links->Option.flatMap(links => links->Array.get(0))
  <>
    <div className="font-bold flex items-center mt-4 lg:text-xl leading-8 text-gray-700">
      <Lucide.MapPin className="mr-2 h-7 w-7 flex-shrink-0 text-gray-500" \"aria-hidden"="true" />
      {location.name->Option.map(React.string)->Option.getOr(React.null)}
    </div>
    // <div className="flex items-center mt-0 ml-2 lg:text-xl leading-8 text-gray-700">
    //   <Lucide.CornerDownRight
    //     className="mr-2.5 h-5 w-5 flex-shrink-0 text-gray-500" \"aria-hidden"="true"
    //   />
    // </div>
    <div className="ml-3 border-gray-200 border-l-4 pl-5 mt-4">
      {location.address
      ->Option.map(address =>
        <p className="lg:text-sm leading-8 text-gray-700">
          {defaultLink
          ->Option.map(link =>
            <a href={link} target="_blank" rel="noopener noreferrer"> {address->React.string} </a>
          )
          ->Option.getOr(address->React.string)}
        </p>
      )
      ->Option.getOr(""->React.string)}
      <p className="truncate">
      {location.links
      ->Option.map(links =>
        links
        ->Array.map(link =>
          <a
            key={link}
            href={link}
            className="mt-4 lg:text-sm leading-8 italic text-gray-700 truncate"
            target="_blank"
            rel="noopener noreferrer">
            {link->React.string}
          </a>
        )
        ->React.array
      )
      ->Option.getOr(React.null)}
      </p>
      {location.details
      ->Option.map(details =>
        <p className="mt-4 lg:text-xl leading-8 text-gray-700 whitespace-pre text-wrap">
          {details->React.string}
        </p>
      )
      ->Option.getOr(React.null)}
    </div>
  </>
}

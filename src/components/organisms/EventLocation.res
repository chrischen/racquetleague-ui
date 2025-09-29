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
    <div className="font-bold flex items-center lg:text-xl leading-8 text-gray-700">
      {location.name->Option.map(React.string)->Option.getOr(React.null)}
    </div>
    // <div className="flex items-center mt-0 ml-2 lg:text-xl leading-8 text-gray-700">
    //   <Lucide.CornerDownRight
    //     className="mr-2.5 h-5 w-5 flex-shrink-0 text-gray-500" \"aria-hidden"="true"
    //   />
    // </div>
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
        ->Array.map(link => {
          let truncatedLink =
            link->Js.String2.length > 50
              ? link->Js.String2.substring(~from=0, ~to_=50) ++ "..."
              : link
          <a
            key={link}
            href={link}
            className="mt-4 lg:text-sm leading-8 italic text-gray-700 truncate"
            target="_blank"
            rel="noopener noreferrer">
            {truncatedLink->React.string}
          </a>
        })
        ->React.array
      )
      ->Option.getOr(React.null)}
    </p>
    {location.details
    ->Option.map(details =>
      <div className="mt-4">
        <PreformattedParagraph
          text=details className="mb-2 last:mb-0 lg:text-xl leading-8 text-gray-700"
        />
      </div>
    )
    ->Option.getOr(React.null)}
  </>
}

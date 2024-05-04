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
    <h3 className="text-lg font-bold text-gray-900 mt-8">
      {location.name->Option.getOr("")->React.string}
    </h3>
    {location.address
    ->Option.map(address =>
      <p className="mt-4 lg:text-xl leading-8 text-gray-700">
        {defaultLink
        ->Option.map(link =>
          <a href={link} target="_blank" rel="noopener noreferrer"> {address->React.string} </a>
        )
        ->Option.getOr(address->React.string)}
      </p>
    )
    ->Option.getOr(""->React.string)}
    {location.links
    ->Option.map(links =>
      links
      ->Array.map(link =>
        <a
          key={link}
          href={link}
          className="mt-4 lg:text-sm leading-8 italic text-gray-700"
          target="_blank"
          rel="noopener noreferrer">
          {link->React.string}
        </a>
      )
      ->React.array
    )
    ->Option.getOr(React.null)}
  </>
}

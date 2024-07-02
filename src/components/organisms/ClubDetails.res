module Fragment = %relay(`
	fragment ClubDetails_club on Club {
		name
		description
	}
`)
@react.component
let make = (~club) => {
  let club = Fragment.use(club)
  <>
    <div className="font-bold flex items-center mt-4 lg:text-xl leading-8 text-gray-700">
      {club.name->Option.map(React.string)->Option.getOr(React.null)}
    </div>
    <div className="ml-3 border-gray-200 border-l-4 pl-5 mt-4">
      {club.description
      ->Option.map(description =>
        <p className="mt-4 lg:text-xl leading-8 text-gray-700 whitespace-pre text-wrap">
          {description->React.string}
        </p>
      )
      ->Option.getOr(React.null)}
    </div>
  </>
}

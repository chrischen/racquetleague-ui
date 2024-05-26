module Fragment = %relay(`
	fragment MediaList_location on Location {
		media {
			title
			url
		}

	}
`)

module YouTube = {
  @module("../molecules/iframe.jsx") @react.component
  external make: (~url: string) => React.element = "YouTube"
}

@genType @react.component
let make = (~media) => {
  let location = Fragment.use(media)
  let media = location.media->Option.getOr([])

  media
  ->Array.map(media => {
    media.url
    ->Option.map(url => <>
      <p> {media.title->Option.map(_, React.string)->Option.getOr(React.null)} </p>
			<YouTube url={url} />
    </>)
    ->Option.getOr(React.null)
  })
  ->React.array
}

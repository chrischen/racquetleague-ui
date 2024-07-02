
export const YouTube = ({ url }) => <iframe
	width="300"
	height="300"
	src={url}
	title="YouTube video player"
	frameBorder="0"
	allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
	referrerPolicy="strict-origin-when-cross-origin"
	allowFullScreen={true}
/>;

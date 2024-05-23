@module("@vis.gl/react-google-maps")
external useMapsLibrary: string => Js.Null.t<'a> = "useMapsLibrary";


module Geocoder = {
	type t;
	type constr;

	external make: (constr) => t = "new";

	type latLng;
	type latLngBounds;
	type geometry = {
		location: latLng,
		viewport: latLngBounds,
		bounds: latLngBounds,
		// location_type: geocoderLocationType
	}
	type result = {
		geometry
	}

	type results = array<result>;
	type addressArgs = {
		address: string
	}
	@send
	external geocodeAddress: (t, addressArgs, (results, string) => unit) => unit = "geocode";
}

module GeocodingLib = {
	type t;
	@get
	external geocoder: t => Geocoder.constr = "Geocoder"


}

// let test = useMapsLibrary("geocoding")->GeocodingLib.geocoder->Geocoder.make;

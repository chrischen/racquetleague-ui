type detector;
type navigator = {
	language?: string,
	languages?: array<string>,
}
type window = {
	navigator: navigator,
}

@module("@lingui/detect-locale") @variadic
external detect: array<detector> => string = "detect"

@module("@lingui/detect-locale")
external fromPath: int => detector = "fromPath"

@module("@lingui/detect-locale")
external fromStorage: string => detector = "fromStorage"

@module("@lingui/detect-locale")
external fromNavigator: navigator => detector = "fromNavigator"

let enFallback: detector = %raw("'en'");
let jaFallback: detector = %raw("'ja'");

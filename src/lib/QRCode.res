@module("react-qr-code") @react.component
external make: (
  ~value: string,
  ~size: option<int>=?,
  ~style: option<Js.Dict.t<string>>=?,
  ~viewBox: option<string>=?,
) => React.element = "default"

@module("@headlessui/react") @react.component
external make: (~\"as": 'asType=?, ~className: string=?, ~children: 'children) => React.element =
  "Menu"

module Button = {
  @module("@headlessui/react") @react.component
  external make: (~\"as": 'asType=?, ~className: string=?, ~children: 'children) => React.element =
    "Button"
}
module Items = {
  @module("@headlessui/react") @react.component
  external make: (~\"as": 'asType=?, ~className: string=?, ~children: 'children) => React.element =
    "Items"
}
module Item = {
  type cb = {active: bool}
  @module("@headlessui/react") @react.component
  external make: (
    ~\"as": 'asType=?,
    ~className: string=?,
    ~children: cb => React.element,
  ) => React.element = "Item"
}

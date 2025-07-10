module Switch = {
  @live @module("@headlessui/react") @react.component @live
  external make: (
    ~className: string=?,
    ~children: 'children,
    ~checked: bool=?,
    ~onChange: bool => unit=?,
  ) => React.element = "Switch"

  // @module("@headlessui/react")
  //   external make: (PervasivesU.JsxDOM.domProps) => React.element =
  //   "Switch"
  module Group = {
    @module("@headlessui/react") @scope("Switch") @react.component
    external make: (
      ~\"as": 'asType=?,
      ~className: string=?,
      ~children: 'children,
    ) => React.element = "Group"
  }

  module Label = {
    @module("@headlessui/react") @scope("Switch") @react.component
    external make: (
      ~\"as": 'asType=?,
      ~className: string=?,
      ~children: 'children,
    ) => React.element = "Label"
  }
}
module Disclosure = {
  type state = {\"open": bool}
  type cb = state => React.element
  @module("@headlessui/react") @react.component
  external make: (~\"as": 'asType=?, ~className: string=?, ~children: cb) => React.element =
    "Disclosure"
}
module DisclosureButton = {
  @module("@headlessui/react") @react.component
  external make: (
    ~key: string=?,
    ~\"as": 'asType=?,
    ~href: string=?,
    ~className: string=?,
    ~children: 'children,
    ~ariaCurrent: [#date | #"false" | #location | #page | #step | #time | #"true"]=?,
  ) => React.element = "DisclosureButton"
}
module DisclosurePanel = {
  type state = {close: unit => unit}
  type cb = state => React.element
  @module("@headlessui/react") @react.component
  external make: (~\"as": 'asType=?, ~className: string=?, ~children: 'children) => React.element =
    "DisclosurePanel"
}
module Menu = {
  @module("@headlessui/react") @react.component
  external make: (~\"as": 'asType=?, ~className: string=?, ~children: 'children) => React.element =
    "Menu"
}
module MenuButton = {
  @module("@headlessui/react") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "MenuButton"
}
module MenuItem = {
  type event = {active: bool, focus: bool}
  type cb = event => React.element
  @module("@headlessui/react") @react.component
  external make: (~key: string=?, ~className: string=?, ~children: cb) => React.element = "MenuItem"
}
module MenuItems = {
  @module("@headlessui/react") @react.component
  external make: (~className: string=?, ~children: 'children) => React.element = "MenuItems"
}
// module Label = {
//   @module("@headlessui/react") @react.component
//   external make: (~\"as": 'asType=?, ~className: string=?, ~children: 'children) => React.element =
//     "Label"
// }
module Field = {
  @module("@headlessui/react") @react.component
  external make: (~\"as": 'asType=?, ~className: string=?, ~children: 'children) => React.element =
    "Field"
}

module Dialog = {
  @module("@headlessui/react") @react.component
  external make: (
    ~\"open": bool,
    ~onClose: (bool => bool) => unit,
    ~transition: option<bool>=?,
    ~className: string=?,
    ~children: 'children,
  ) => React.element = "Dialog"
}
module DialogBackdrop = {
  @module("@headlessui/react") @react.component
  external make: (~transition: bool, ~className: string=?) => React.element = "DialogBackdrop"
}
module DialogPanel = {
  @module("@headlessui/react") @react.component
  external make: (
    ~transition: bool,
    ~className: string=?,
    ~children: React.element,
  ) => React.element = "DialogPanel"
}
module DialogTitle = {
  @module("@headlessui/react") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "DialogTitle"
}

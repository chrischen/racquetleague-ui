module Switch = {
  @live @module("@headlessui/react") @react.component @live
  external make: (
    ~className: string=?,
    ~children: 'children,
    ~checked: bool=?,
    ~onChange: JsxEventU.Form.t => unit=?,
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
  @module("@headlessui/react") @react.component
  external make: (~className: string=?, ~children: 'children) => React.element = "DisclosurePanel"
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
  type event = {focus: bool}
  type cb = event => React.element
  @module("@headlessui/react") @react.component
  external make: (~key: string=?, ~className: string=?, ~children: cb) => React.element = "MenuItem"
}
module MenuItems = {
  @module("@headlessui/react") @react.component
  external make: (~className: string=?, ~children: 'children) => React.element = "MenuItems"
}

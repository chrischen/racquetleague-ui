@module("./navbar.tsx") @react.component
external make: (~children: React.element) => React.element = "Navbar"

module Dropdown = HeadlessUi.Menu
module DropdownButton = {
  @module("./dropdown.tsx") @react.component
  external make: (
    ~className: string=?,
    ~\"as": React.component<'a>=?,
    ~children: React.element,
    ~outline: bool=?,
    ~plain: bool=?,
  ) => React.element = "DropdownButton"
}
module DropdownMenu = {
  @module("./dropdown.tsx") @react.component
  external make: (
    ~className: string=?,
    ~anchor: string=?,
    ~children: React.element,
  ) => React.element = "DropdownMenu"
}
module DropdownDivider = {
  @module("./dropdown.tsx") @react.component
  external make: (~className: string=?) => React.element = "DropdownDivider"
}
module DropdownItem = {
  @module("./dropdown.tsx") @react.component
  external make: (
    ~href: string=?,
    ~className: string=?,
    ~\"aria-label": string=?,
    ~children: React.element,
    ~onClick: JsxEventU.Mouse.t => unit=?,
  ) => React.element = "DropdownItem"
}

module DropdownLabel = {
  @module("./dropdown.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "DropdownLabel"
}

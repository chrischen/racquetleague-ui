@module("./navbar.tsx") @react.component
external make: (~children: React.element) => React.element = "Navbar"

module NavbarDivider = {
  @module("./navbar.tsx") @react.component
  external make: (~className: string=?) => React.element = "NavbarDivider"
}
module NavbarSection = {
  @module("./navbar.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "NavbarSection"
}
module NavbarItem = {
  @module("./navbar.tsx") @react.component
  external make: (
    ~className: string=?,
    ~href: string=?,
    ~\"aria-label": string=?,
    ~children: React.element,
  ) => React.element = "NavbarItem"
}

module NavbarLabel = {
  @module("./navbar.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "NavbarLabel"
}

module NavbarSpacer = {
  @module("./navbar.tsx") @react.component
  external make: (~className: string=?) => React.element = "NavbarSpacer"
}

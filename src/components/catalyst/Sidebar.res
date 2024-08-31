module Sidebar = {
  @module("./sidebar.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element =
    "Sidebar"
}
module SidebarHeader = {
  @module("./sidebar.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element =
    "SidebarHeader"
}
module SidebarBody = {
  @module("./sidebar.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element =
    "SidebarBody"
}
module SidebarSection = {
  @module("./sidebar.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element =
    "SidebarSection"
}
module SidebarItem = {
  @module("./sidebar.tsx") @react.component
  external make: (
    ~href: string=?,
    ~className: string=?,
    ~current: bool=?,
    ~\"aria-label": string=?,
    ~children: React.element,
  ) => React.element = "SidebarItem"
}

module SidebarLabel = {
  @module("./sidebar.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element =
    "SidebarLabel"
}

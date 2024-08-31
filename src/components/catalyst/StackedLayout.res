@module("./stacked-layout.tsx") @react.component
external make: (
  ~navbar: React.element,
  ~sidebar: React.element,
  ~children: React.element,
) => React.element = "StackedLayout"

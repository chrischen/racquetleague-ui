type css = {
  width?: string,
  height?: string,
  opacity?: float,
  scale?: float,
  originX?: float,
  originY?: float,
  x?: float,
  y?: float,
}
module Div = {
  @module("framer-motion") @scope("motion") @react.component
  external make: (
    ~className: string=?,
    ~style: css=?,
    ~key: string=?,
    ~animate: css=?,
    ~initial: css=?,
    ~exit: css=?,
    ~children: React.element=?,
  ) => React.element = "div"
}
module Li = {
  @module("framer-motion") @scope("motion") @react.component
  external make: (
    ~className: string=?,
    ~style: css=?,
    ~key: string=?,
    ~animate: css=?,
    ~initial: css=?,
    ~exit: css=?,
    ~layout: bool=?,
    ~children: React.element=?,
  ) => React.element = "li"
}

module Main = {
  @module("framer-motion") @scope("motion") @react.component
  external make: (~key: string) => React.element = "main"
}

module AnimatePresence = {
  @module("framer-motion") @react.component
  external make: (~mode: string=?, ~children: React.element) => React.element = "AnimatePresence"
}

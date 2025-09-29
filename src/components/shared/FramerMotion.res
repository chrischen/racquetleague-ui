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
    ~animate: 'animate=?, // Can be cssAnimate, variantAnimate, or any other type
    ~initial: css=?,
    ~exit: css=?,
    ~onMouseDown: ReactEvent.Mouse.t => unit=?,
    ~onMouseUp: ReactEvent.Mouse.t => unit=?,
    ~onPointerUp: ReactEvent.Pointer.t => unit=?,
    ~onPointerDown: ReactEvent.Pointer.t => unit=?,
    ~onPointerMove: ReactEvent.Pointer.t => unit=?,
    ~onPointerLeave: ReactEvent.Pointer.t => unit=?,
    ~onTouchStart: ReactEvent.Touch.t => unit=?,
    ~onTouchEnd: ReactEvent.Touch.t => unit=?,
    ~onTouchMove: ReactEvent.Touch.t => unit=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~variants: 'b=?,
    // ~animateControls as :  'a=?,
    ~children: React.element=?,
  ) => React.element = "div"
}
module DivCss = {
  @module("framer-motion") @scope("motion") @react.component
  external make: (
    ~className: string=?,
    ~style: css=?,
    ~key: string=?,
    ~animate: css=?, // Can be cssAnimate, variantAnimate, or any other type
    ~initial: css=?,
    ~exit: css=?,
    ~onMouseDown: ReactEvent.Mouse.t => unit=?,
    ~onMouseUp: ReactEvent.Mouse.t => unit=?,
    ~onPointerUp: ReactEvent.Pointer.t => unit=?,
    ~onPointerDown: ReactEvent.Pointer.t => unit=?,
    ~onPointerMove: ReactEvent.Pointer.t => unit=?,
    ~onPointerLeave: ReactEvent.Pointer.t => unit=?,
    ~onTouchStart: ReactEvent.Touch.t => unit=?,
    ~onTouchEnd: ReactEvent.Touch.t => unit=?,
    ~onTouchMove: ReactEvent.Touch.t => unit=?,
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~variants: 'b=?,
    // ~animateControls as :  'a=?,
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
module Tr = {
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
  ) => React.element = "tr"
}

module Main = {
  @module("framer-motion") @scope("motion") @react.component
  external make: (~key: string) => React.element = "main"
}

module AnimatePresence = {
  @module("framer-motion") @react.component
  external make: (~mode: string=?, ~children: React.element) => React.element = "AnimatePresence"
}

type animationControls

module AnimationControls = {
  // Add methods you need to call on animationControls, e.g., start, stop
  @send external start: (animationControls, string) => Promise.t<unit> = "start"
  @send external stop: (animationControls, string) => unit = "stop"
  // Add other methods like set, mount, etc., as needed
  // e.g., @send external set: (animationControls, 'definition) => unit = "set"
}

// Binding for the useAnimation hook
@module("framer-motion") @react.hook
external useAnimation: unit => animationControls = "useAnimation"

// Example of how you might define variants if you pass them to controls.start()
// This is just illustrative; your actual variant structure might differ.
type variants = {"hidden": css, "visible": css, "exit": css}
type dynamicVariants<'a> = 'a => {"initial": css, "animate": css}

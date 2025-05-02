// Assuming the TypeScript code is in a file accessible via "@/components/catalyst/button"
// Adjust the @module path if your file structure is different.

// Define the polymorphic variant for the color prop
type color = [
  | #"dark/zinc" // Escape strings with special characters
  | #light
  | #"dark/white"
  | #dark
  | #white
  | #zinc
  | #indigo
  | #cyan
  | #red
  | #orange
  | #amber
  | #yellow
  | #lime
  | #green
  | #emerald
  | #teal
  | #sky
  | #blue
  | #violet
  | #purple
  | #fuchsia
  | #pink
  | #rose
]

module Button = {
  @module("./button.tsx") @react.component
  external make: (
    // Style props (mutually exclusive in implementation, optional here)
    ~color: color=?,
    ~outline: bool=?,
    ~plain: bool=?,
    // Common props
    ~className: string=?,
    ~children: React.element,
    // Props for rendering as <button> (based on Headless UI Button)
    ~onClick: ReactEvent.Mouse.t => unit=?,
    ~disabled: bool=?,
    ~type_: string=?, // 'type' is a keyword
    // Props for rendering as <a> (Link)
    ~href: string=?,
    ~target: string=?, // Common link attribute
    ~rel: string=?, // Common link attribute
    // Accessibility
    ~\"aria-label": string=?,
    ~\"aria-disabled": bool=?, // Explicit aria-disabled if needed
    // Ref - Type needs to be general as it can be HTMLButtonElement or HTMLAnchorElement
    // Using Js.Nullable.t<Dom.element> is a safe bet, or you might need a more specific union if possible
    ~ref: React.ref<Js.Nullable.t<Dom.element>>=?,
  ) => React.element = "Button"
}

module TouchTarget = {
  @module("./button.tsx") @react.component
  external make: (~children: React.element) => React.element = "TouchTarget"
}

// Example Usage
@react.component
let makeExample = () => {
  <>
    <Button> {"Default Button"->React.string} </Button>
    <Button color=#blue> {"Blue Button"->React.string} </Button>
    <Button outline=true> {"Outline Button"->React.string} </Button>
    <Button plain=true> {"Plain Button"->React.string} </Button>
    <Button href="/some/path"> {"Link Button"->React.string} </Button>
    <Button disabled=true> {"Disabled Button"->React.string} </Button>
    <Button onClick={_ => Js.log("Clicked!")}> {"Click Me"->React.string} </Button>
    <Button>
      <TouchTarget> {"Button with explicit TouchTarget"->React.string} </TouchTarget>
    </Button>
  </>
}

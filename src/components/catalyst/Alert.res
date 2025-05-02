// Assuming the TypeScript code is in a file accessible via "@/components/alert"
// Adjust the @module path if your file structure is different.

// Define the polymorphic variant for the size prop
type size = [
  | #xs
  | #sm
  | #md
  | #lg
  | #xl
  | #"2xl" // Escape "2xl" as it starts with a number
  | #"3xl"
  | #"4xl"
  | #"5xl"
]

module Alert = {
  @module("./alert.tsx") @react.component
  external make: (
    // Based on HeadlessUI Dialog, 'open' and 'onClose' are essential
    @as("open") ~open_: bool, // 'open' is a keyword in ReScript, use @as to map
    ~onClose: (bool => bool) => unit,
    // ~onClose: React.Dispatch.t<bool>, // Assuming boolean state setter
    ~size: size=?, // Optional size prop using the variant
    ~className: string=?,
    ~children: React.element,
  ) => // Add other Headless.DialogProps as needed, e.g., initialFocus
  // ~initialFocus: React.Ref.t<Dom.element>=?,
  React.element = "Alert"
}

module AlertTitle = {
  @module("./alert.tsx") @react.component
  external make: (
    ~className: string=?,
    ~children: React.element,
  ) => // Add other Headless.DialogTitleProps if necessary
  React.element = "AlertTitle"
}

module AlertDescription = {
  @module("./alert.tsx") @react.component
  external make: (
    ~className: string=?,
    ~children: React.element,
  ) => // Add other Headless.DescriptionProps if necessary
  React.element = "AlertDescription"
}

module AlertBody = {
  @module("./alert.tsx") @react.component
  external // Standard div props are often implicitly handled by JSX Punning for common ones like className
  // Explicitly define if needed, or rely on JSX Punning for simple cases.
  make: (~className: string=?, ~children: React.element) => React.element = "AlertBody"
}

module AlertActions = {
  @module("./alert.tsx") @react.component
  external // Standard div props
  make: (~className: string=?, ~children: React.element) => React.element = "AlertActions"
}

// Example Usage (similar to the previous AlertModal example)
@react.component
let makeExample = () => {
  let (isOpen, setIsOpen) = React.useState(() => false)

  <>
    <Button.Button onClick={_ => setIsOpen(_ => true)}>
      {"Show Alert"->React.string}
    </Button.Button> // Assuming Button.Button binding exists
    <Alert open_=isOpen onClose={setIsOpen} size=#sm>
      <AlertTitle> {"Alert Title"->React.string} </AlertTitle>
      <AlertBody>
        <AlertDescription> {"This is the alert description."->React.string} </AlertDescription>
      </AlertBody>
      <AlertActions>
        <Button.Button plain=true onClick={_ => setIsOpen(_ => false)}>
          {"Cancel"->React.string}
        </Button.Button>
        <Button.Button onClick={_ => setIsOpen(_ => false)}>
          {"Confirm"->React.string}
        </Button.Button>
      </AlertActions>
    </Alert>
  </>
}

// Assuming the TypeScript/JavaScript code is in a file accessible via "./dialog.tsx"
// Adjust the @module path if your file structure is different.

// Define the polymorphic variant for the size prop if Dialog supports it
// (Based on the JS example, it doesn't seem to, but adding for completeness if needed later)
type size = [
  | #xs
  | #sm
  | #md
  | #lg
  | #xl
  | #"2xl"
  | #"3xl"
  | #"4xl"
  | #"5xl"
]

module Dialog = {
  @module("./dialog.tsx") @react.component
  external make: (
    @as("open") ~open_: bool, // 'open' is a keyword in ReScript, use @as to map
    ~onClose: (bool => bool) => unit, // Or React.Dispatch.t<bool>
    ~size: size=?, // Optional size prop
    ~className: string=?,
    ~children: React.element,
  ) => React.element = "Dialog" // The JS component is named Dialog
}

module DialogTitle = {
  @module("./dialog.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "DialogTitle"
}

module DialogDescription = {
  @module("./dialog.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element =
    "DialogDescription"
}

module DialogBody = {
  @module("./dialog.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "DialogBody"
}

module DialogActions = {
  @module("./dialog.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "DialogActions"
}

// Example Usage
// Assuming Button, Field, Label, Input bindings exist
// For example:
// module Button = {
//   @module("@/components/button") @react.component // Adjust path
//   external make: (~type_:"button" | "submit" | "reset"=?, ~onClick: ReactEvent.Mouse.t => unit=?, ~plain:bool=?, ~children: React.element) => React.element = "Button"
// }
// module Field = {
//   @module("@/components/fieldset") @react.component // Adjust path
//   external make: (~children: React.element) => React.element = "Field"
// }
// module Label = {
//   @module("@/components/fieldset") @react.component // Adjust path
//   external make: (~children: React.element) => React.element = "Label"
// }
// module Input = {
//   @module("@/components/input") @react.component // Adjust path
//   external make: (~name: string, ~placeholder: string=?, ~type_:string=?) => React.element = "Input"
// }

@react.component
let makeExample = () => {
  let (isOpen, setIsOpen) = React.useState(() => false)

  // Dummy Button binding for the example to compile
  // Replace with your actual Button binding
  module Button = {
    @react.component
    let make = (
      ~onClick: option<ReactEvent.Mouse.t => unit>=?,
      ~plain=false,
      ~children,
      ~type_="button",
    ) =>
      <button type_ ?onClick disabled=?{None} className={plain ? "plain" : ""}> children </button>
  }
  // Dummy Field, Label, Input bindings
  module Field = {
    @react.component let make = (~children) => <div> children </div>
  }
  module Label = {
    @react.component let make = (~children) => <label> children </label>
  }
  module Input = {
    @react.component let make = (~name, ~placeholder) => <input name placeholder />
  }

  <>
    <Button onClick={_ => setIsOpen(_ => true)}> {"Refund payment"->React.string} </Button>
    <Dialog open_=isOpen onClose={setIsOpen}>
      <DialogTitle> {"Refund payment"->React.string} </DialogTitle>
      <DialogDescription>
        {"The refund will be reflected in the customer’s bank account 2 to 3 business days after processing."->React.string}
      </DialogDescription>
      <DialogBody>
        <Field>
          <Label> {"Amount"->React.string} </Label>
          <Input name="amount" placeholder="$0.00" />
        </Field>
      </DialogBody>
      <DialogActions>
        <Button plain=true onClick={_ => setIsOpen(_ => false)}> {"Cancel"->React.string} </Button>
        <Button onClick={_ => setIsOpen(_ => false)}> {"Refund"->React.string} </Button>
      </DialogActions>
    </Dialog>
  </>
}

// Assuming bindings for Alert, AlertActions, AlertDescription, AlertTitle, Button exist
// Example paths - adjust based on your project structure

@react.component
let make = (
  ~button: React.element,
  ~className: string=?,
  ~title: React.element,
  ~description: React.element,
  ~onConfirmed: unit => unit,
) => {
  let (isOpen, setIsOpen) = React.useState(() => false)

  <>
    <UiAction ?className onClick={_ => setIsOpen(_ => true)}> {button} </UiAction>
    <ConfirmDialog title description isOpen setIsOpen={setIsOpen} onConfirmed />
  </>
}

// Optional: Export as default if needed
// let default = make

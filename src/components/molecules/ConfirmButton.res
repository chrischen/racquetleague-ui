// Assuming bindings for Alert, AlertActions, AlertDescription, AlertTitle, Button exist
// Example paths - adjust based on your project structure
open Alert
open Button

@react.component
let make = (
  ~button: React.element,
  ~className: string=?,
  ~title: React.element,
  ~description: React.element,
  ~onConfirmed: unit => unit,
) => {
  let (isOpen, setIsOpen) = React.useState(() => false)
  let handleConfirm = _ => {
    setIsOpen(_ => false) // Close the modal
    onConfirmed() // Call the provided callback
  }

  <>
    <Button ?className type_="button" onClick={_ => setIsOpen(_ => true)}> {button} </Button>
    <Alert open_=isOpen onClose={setIsOpen}>
      // Use open_ prop
      <AlertTitle> {title} </AlertTitle>
      <AlertDescription> {description} </AlertDescription>
      <AlertActions>
        <Button plain=true onClick={_ => setIsOpen(_ => false)}> {"Cancel"->React.string} </Button>
        <Button onClick=handleConfirm> {"Confirm"->React.string} </Button>
      </AlertActions>
    </Alert>
  </>
}

// Optional: Export as default if needed
// let default = make

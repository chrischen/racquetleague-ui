// Assuming Button bindings exist, and Dialog.res is in ../catalyst/
// Dialog.res provides:
// - type Dialog.size
// - module Dialog.Dialog
// - module Dialog.DialogTitle
// - module Dialog.DialogDescription
// - module Dialog.DialogBody
// - module Dialog.DialogActions

open Button // Assuming a Button module with Button.Button component

@react.component
let make = (
  ~triggerContent: React.element,
  ~title: React.element,
  ~description: React.element,
  ~body: React.element, // Content for the DialogBody
  ~onConfirm: unit => unit,
  ~confirmButtonText: string="Confirm",
  ~cancelButtonText: string="Cancel",
  ~dialogSize: option<Dialog.size>=?, // Uses 'size' type from Dialog.res
  ~triggerButtonClassName: option<string>=?,
) => {
  let (isOpen, setIsOpen) = React.useState(() => false)

  let handleConfirm = _ => {
    setIsOpen(_ => false) // Close the dialog
    onConfirm() // Call the provided callback
  }

  let handleCancel = _ => {
    setIsOpen(_ => false) // Close the dialog
  }

  <>
    <Button className=?triggerButtonClassName type_="button" onClick={_ => setIsOpen(_ => true)}>
      triggerContent
    </Button>
    <Dialog.Dialog open_=isOpen onClose={_ => setIsOpen(_ => false)} size=?dialogSize>
      <Dialog.DialogTitle> {title} </Dialog.DialogTitle>
      <Dialog.DialogDescription> {description} </Dialog.DialogDescription>
      <Dialog.DialogBody> body </Dialog.DialogBody>
      <Dialog.DialogActions>
        <Button plain=true onClick={handleCancel}> {cancelButtonText->React.string} </Button>
        <Button onClick=handleConfirm> {confirmButtonText->React.string} </Button>
      </Dialog.DialogActions>
    </Dialog.Dialog>
  </>
}

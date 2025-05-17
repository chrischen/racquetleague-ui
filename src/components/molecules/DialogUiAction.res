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
  ~dialogSize: option<Dialog.size>=?,
) => {
  // Uses 'size' type from Dialog.res

  let (isOpen, setIsOpen) = React.useState(() => false)

  let handleConfirm = _ => {
    setIsOpen(_ => false) // Close the dialog
    onConfirm() // Call the provided callback
  }

  let handleCancel = _ => {
    setIsOpen(_ => false) // Close the dialog
  }

  <>
    <UiAction onClick={_ => setIsOpen(_ => true)}> triggerContent </UiAction>
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

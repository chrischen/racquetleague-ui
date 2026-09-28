// Storybook support for CreateLocationForm.stories.tsx; the app never imports
// this. The form has no fragment; Relay is only there for its mutation.
@genType @react.component
let make = (~onCancel: option<unit => unit>=?, ~onClose=() => ()) => {
  <div className="max-w-3xl font-sans">
    <CreateLocationForm onCancel={_ => onCancel->Option.forEach(f => f())} onClose />
  </div>
}

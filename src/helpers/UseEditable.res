// Inline editing for display components.
//
// A page turns edit mode on (typically from an "Edit" button) and passes
// `editable` down as a prop. Every display component using this hook then
// offers its editable look — a dashed outline with an "Edit" pill, drawn by
// EditableSection — and a click opens the editor. Save hands the draft to the
// component's `onEdited`, which the page connects to whatever mutation
// applies; the hook never knows about the write.
//
//   let field = UseEditable.use(~editable, ~value=notes, ~onEdited)
//   <EditableSection state=field.state ... editor={<textarea value=field.draft ... />} />

type state =
  | Display
  | Editable
  | Editing

type t<'a> = {
  state: state,
  draft: 'a,
  setDraft: ('a => 'a) => unit,
  startEditing: unit => unit,
  // Drops the draft and closes the editor.
  cancel: unit => unit,
  // Hands the draft to `onEdited` and closes the editor.
  commit: unit => unit,
  // Escape cancels, Cmd/Ctrl+Enter commits. Attach to the editor element.
  onKeyDown: ReactEvent.Keyboard.t => unit,
}

let use = (~editable: bool, ~value: 'a, ~onEdited: 'a => unit): t<'a> => {
  let (editing, setEditing) = React.useState(() => false)
  let (draft, setDraft) = React.useState(() => value)

  // Leaving edit mode closes any open editor without saving.
  React.useEffect1(() => {
    if !editable {
      setEditing(_ => false)
    }
    None
  }, [editable])

  let startEditing = () => {
    setDraft(_ => value)
    setEditing(_ => true)
  }
  let cancel = () => {
    setDraft(_ => value)
    setEditing(_ => false)
  }
  let commit = () => {
    onEdited(draft)
    setEditing(_ => false)
  }
  let onKeyDown = e => {
    let key = ReactEvent.Keyboard.key(e)
    if key == "Escape" {
      ReactEvent.Keyboard.preventDefault(e)
      cancel()
    } else if key == "Enter" && (ReactEvent.Keyboard.metaKey(e) || ReactEvent.Keyboard.ctrlKey(e)) {
      ReactEvent.Keyboard.preventDefault(e)
      commit()
    }
  }

  {
    state: if !editable {
      Display
    } else if editing {
      Editing
    } else {
      Editable
    },
    draft,
    setDraft,
    startEditing,
    cancel,
    commit,
    onKeyDown,
  }
}

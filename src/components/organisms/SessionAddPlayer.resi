@rhf
type inputsUser = {name: Zod.string_}

@react.component
let make: (~eventId: string, ~onPlayerAdd: inputsUser => unit) => React.element

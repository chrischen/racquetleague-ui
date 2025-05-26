module Fieldset = {
  // Props from Omit<Headless.FieldsetProps, 'as' | 'className'>
  // Common Headless.FieldsetProps: disabled, name, form, children.
  @react.component @module("./fieldset.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~disabled: bool=?,
    ~name: string=?,
    ~form: string=?, // Associates with a form ID
    ~children: React.element=?,
    ~key: string=?,
  ) => React.element = "Fieldset"
}

module Legend = {
  // Props from Omit<Headless.LegendProps, 'as' | 'className'>
  // Common Headless.LegendProps: disabled, children.
  @react.component @module("./fieldset.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~disabled: bool=?,
    ~children: React.element=?,
    ~key: string=?,
  ) => React.element = "Legend"
}

module FieldGroup = {
  // Props from React.ComponentPropsWithoutRef<'div'>
  // Includes common div attributes like id, style, event handlers, etc.
  @react.component @module("./fieldset.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~id: string=?,
    ~style: ReactDOM.Style.t=?,
    ~key: string=?,
    // Event handlers like onClick, etc., can be added if needed
    // e.g. ~onClick: ReactEvent.Mouse.t => unit=?,
    ~children: React.element=?,
  ) => React.element = "FieldGroup"
}

module Field = {
  // Props from Omit<Headless.FieldProps, 'as' | 'className'>
  // Common Headless.FieldProps: disabled, name, required, children.
  @react.component @module("./fieldset.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~disabled: bool=?,
    ~name: string=?,
    ~required: bool=?,
    ~children: React.element, // Headless.Field typically requires children
    ~key: string=?,
  ) => React.element = "Field"
}

module Label = {
  // Props from Omit<Headless.LabelProps, 'as' | 'className'>
  // Common Headless.LabelProps: disabled, children.
  @react.component @module("./fieldset.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~disabled: bool=?,
    ~children: React.element=?,
    ~htmlFor: string=?, // Common prop for <label>
    ~key: string=?,
  ) => React.element = "Label"
}

module Description = {
  // Props from Omit<Headless.DescriptionProps, 'as' | 'className'>
  // Common Headless.DescriptionProps: disabled, children.
  @react.component @module("./fieldset.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~disabled: bool=?,
    ~children: React.element=?,
    ~key: string=?,
  ) => React.element = "Description"
}

module ErrorMessage = {
  // Props from Omit<Headless.DescriptionProps, 'as' | 'className'> (same as Description)
  // Common Headless.DescriptionProps: disabled, children.
  @react.component @module("./fieldset.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~disabled: bool=?,
    ~children: React.element=?,
    ~key: string=?,
  ) => React.element = "ErrorMessage"
}

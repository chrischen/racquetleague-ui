module CheckboxGroup = {
  @react.component @module("./checkbox.tsx")
  external make: (
    ~className: string=?,
    // Common props from React.ComponentPropsWithoutRef<'div'>
    ~id: string=?,
    ~style: ReactDOM.Style.t=?,
    ~key: string=?,
    // Event handlers like onClick, etc., can be added if needed
    // e.g. ~onClick: ReactEvent.Mouse.t => unit=?,
    ~children: React.element=?,
  ) => // If you need to pass other arbitrary HTML attributes,
  // you might need a more complex props type or use an "unsafe" approach.
  React.element = "CheckboxGroup"
}

module CheckboxField = {
  // Props from Omit<Headless.FieldProps, 'as' | 'className'>
  // Common Headless.FieldProps include: children, disabled, name, required.
  // 'as' is omitted. 'className' is handled by the component's own prop.
  @react.component @module("./checkbox.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~disabled: bool=?,
    ~name: string=?,
    ~required: bool=?,
    ~children: React.element, // Headless.Field typically requires children
    ~key: string=?,
  ) => React.element = "CheckboxField"
}

module Checkbox = {
  type color = [
    | @as("dark/zinc") #dark_zinc
    | @as("dark/white") #dark_white
    | @as("white") #white
    | @as("dark") #dark
    | @as("zinc") #zinc
    | @as("red") #red
    | @as("orange") #orange
    | @as("amber") #amber
    | @as("yellow") #yellow
    | @as("lime") #lime
    | @as("green") #green
    | @as("emerald") #emerald
    | @as("teal") #teal
    | @as("cyan") #cyan
    | @as("sky") #sky
    | @as("blue") #blue
    | @as("indigo") #indigo
    | @as("violet") #violet
    | @as("purple") #purple
    | @as("fuchsia") #fuchsia
    | @as("pink") #pink
    | @as("rose") #rose
  ]

  // Props from Omit<Headless.CheckboxProps, 'as' | 'className'>
  // Common Headless.CheckboxProps: checked, defaultChecked, onChange, disabled, name, value, required, form, indeterminate.
  // 'as' is omitted. 'className' is handled by the component's own prop.
  @react.component @module("./checkbox.tsx")
  external make: (
    ~className: string=?, // Explicitly defined in the TSX component's props
    ~color: color=?, // Defaults to 'dark/zinc' in the TSX component
    ~checked: bool=?,
    ~defaultChecked: bool=?,
    ~indeterminate: bool=?,
    ~onChange: bool => unit=?, // Headless UI Checkbox onChange gives a boolean
    ~disabled: bool=?,
    ~name: string=?,
    ~value: string=?,
    ~required: bool=?,
    ~form: string=?, // Associates with a form ID
    ~key: string=?,
  ) => // This Checkbox component does not accept children in its props definition.
  React.element = "Checkbox"
}

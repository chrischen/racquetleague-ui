// Storybook support for SeekingPartnerInput.stories.tsx; the app never
// imports this. The switch is controlled, so the wrapper holds its value and
// the story can be toggled.
@genType @react.component
let make = (~seeking=false, ~onChange: option<bool => unit>=?) => {
  let (value, setValue) = React.useState(() => seeking ? Some(1) : None)
  React.useEffect1(() => {
    setValue(_ => seeking ? Some(1) : None)
    None
  }, [seeking])
  <div className="max-w-xl font-sans">
    <SeekingPartnerInput
      seekingPartner=value
      onChange={checked => {
        setValue(_ => checked ? Some(1) : None)
        onChange->Option.forEach(f => f(checked))
      }}
    />
  </div>
}

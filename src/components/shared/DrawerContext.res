type contextValue = {
  openDrawer: (React.element, string) => unit,
  closeDrawer: unit => unit,
}

let defaultValue: contextValue = {
  openDrawer: (_, _) => (),
  closeDrawer: () => (),
}

let context: React.Context.t<contextValue> = React.createContext(defaultValue)

module Provider = {
  let make = React.Context.provider(context)
}

let use = () => React.useContext(context)

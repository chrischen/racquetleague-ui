// Whether the app shell is in dark mode. PkuruLayout follows the system
// preference and puts Tailwind's `dark` class on its content wrappers (dark
// mode is class-based); anything portalled to document.body - dialogs - lands
// outside those wrappers, so it reads this to put the class on its own root.
let context: React.Context.t<bool> = React.createContext(false)

module Provider = {
  let make = React.Context.provider(context)
}

let use = () => React.useContext(context)

// The classes a root outside the shell's wrappers needs: Tailwind's dark
// variant switch, and the native-control colour scheme to match.
let rootClass = isDark => isDark ? "dark [color-scheme:dark]" : ""

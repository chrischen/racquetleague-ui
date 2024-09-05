// type session = {viewer: option<UserProvider_user_graphql.Types.fragment_viewer>}
// module SessionContextProvider = {
//   @react.component @module("./appContext") @scope("SessionContext")
//   external make: (~children: React.element, ~value: session) => React.element = "Provider"

module Fragment = %relay(`
  fragment GlobalQueryProvider_viewer on Viewer {
    user {
      id
      lineUsername
    }
  }
`)

type query = option<RescriptRelay.fragmentRefs<[#GlobalQueryProvider_viewer | #NavViewer_viewer]>>
let context: React.Context.t<query> = React.createContext(None)
module Provider = {
  let make = React.Context.provider(context)
}

// Hook API
let useViewer = () => {
  let globalQuery = React.useContext(context)
  globalQuery->Option.map(q => Fragment.use(q))->Option.getOr({user: None})
}

// Render prop API
module Viewer = {
  @react.component
  let make = (~children: 'a => React.element) => {
    // Uses the Query fragment from the global context
    let globalQuery = React.useContext(context)
    let viewer = globalQuery->Option.map(q => Fragment.use(q))->Option.getOr({user: None})
    children(viewer)
  }
}

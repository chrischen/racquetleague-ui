// type session = {viewer: option<UserProvider_user_graphql.Types.fragment_viewer>}
// module SessionContextProvider = {
//   @react.component @module("./appContext") @scope("SessionContext")
//   external make: (~children: React.element, ~value: session) => React.element = "Provider"

module Fragment = %relay(`
  fragment GlobalQueryProvider_viewer on Viewer {
    user {
      id
      lineUsername
      locale
    }
  }
`)

type query = option<RescriptRelay.fragmentRefs<[#GlobalQueryProvider_viewer | #NavViewer_viewer]>>
let context: React.Context.t<query> = React.createContext(None)

module ContextProvider = {
  let make = React.Context.provider(context)
}

// Hook API
let useViewer = () => {
  let globalQuery = React.useContext(context)
  globalQuery->Option.map(q => Fragment.use(q))->Option.getOr({user: None})
}

// Automatically navigates to the viewer's stored locale when it differs from the URL lang.
// Renders nothing — pure side-effect component.
module LocaleSync = {
  @react.component
  let make = () => {
    let viewer = useViewer()
    let locale = React.useContext(LangProvider.LocaleContext.context)
    let navigate = LangProvider.Router.useOriginalNavigate()
    let {pathname, search} = Router.useLocation()

    let userLocale =
      viewer.user
      ->Option.flatMap(u => u.locale)
      ->Option.getOr("")

    React.useEffect2(() => {
      if userLocale != "" && userLocale != locale.lang {
        let targetPath =
          I18n.getLangPath(userLocale) ++ I18n.getBasePath(locale.lang, pathname) ++ search
        navigate(targetPath, None)
      }
      None
    }, (userLocale, locale.lang))

    React.null
  }
}

// Renders the browser-detection banner only when the viewer has no stored locale preference.
// When the viewer has an explicit locale, LocaleSync handles redirection instead.
module DetectedLang = {
  @react.component
  let make = () => {
    let viewer = useViewer()
    let hasStoredLocale =
      viewer.user
      ->Option.flatMap(u => u.locale)
      ->Option.map(l => l != "")
      ->Option.getOr(false)

    if hasStoredLocale {
      React.null
    } else {
      <LangProvider.DetectedLang />
    }
  }
}

module Provider = {
  @react.component
  let make = (~value: query, ~children: React.element) => {
    <ContextProvider value>
      <LocaleSync />
      {children}
    </ContextProvider>
  }
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

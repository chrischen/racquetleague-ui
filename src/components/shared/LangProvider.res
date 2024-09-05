type locale = {
  locale: string,
  lang: string,
  timezone: string,
}
module LocaleContext = {
  module Provider = {
    @react.component @module("../layouts/appContext") @scope("LocaleContext")
    external make: (~children: React.element, ~value: locale) => React.element = "Provider"
  }
  @module("../layouts/appContext")
  external context: React.Context.t<locale> = "LocaleContext"
}
@module("react-router-dom")
external useLoaderData: unit => locale = "useLoaderData"

@genType @react.component
let make = () => {
  let data = useLoaderData()
  let locale = switch data.lang {
  | "ja" => Some("ja")
  | "en" => Some("en")
  | _ => None
  }
  open Router

  <LocaleContext.Provider value=data>
    <Lingui.I18nProvider i18n=Lingui.i18n>
      {switch locale {
      | Some(locale) =>
        <ReactIntl2.IntlProvider locale timeZone=data.timezone>
          <Outlet />
        </ReactIntl2.IntlProvider>
      | None => <NotFound />
      }}
    </Lingui.I18nProvider>
  </LocaleContext.Provider>
}

module Router = {
  // Locale-aware Link component
  module Link = {
    let make = (
      props: Router.Link.props<
        string,
        React.element,
        string,
        string,
        bool,
        bool,
        [> #page | #"false"],
      >,
    ) => {
      let locale = React.useContext(LocaleContext.context)
      let props = {
        ...props,
        to: switch props.to->String.startsWith("/") {
        | true => "/" ++ locale.lang ++ props.to
        | false => props.to
        },
      }

      <Router.Link {...props} />
    }
  }
  module NavLink = {
    @genType
    let make = (
      props: Router.NavLink.props<
        string,
        React.element,
        Router.NavLink.linkState => string,
        string,
        'a => unit,
        bool,
        bool,
      >,
    ) => {
      let locale = React.useContext(LocaleContext.context)
      let props = {
        ...props,
        to: switch props.to->String.startsWith("/") {
        | true => "/" ++ locale.lang ++ props.to
        | false => props.to
        },
      }

      <Router.NavLink {...props} />
    }
  }
  module LinkWithOpts = {
    let make = (
      props: Router.LinkWithOpts.props<
        Router.LinkWithOpts.to,
        React.element,
        string,
        string,
        bool,
        bool,
      >,
    ) => {
      let locale = React.useContext(LocaleContext.context)
      let props = {
        ...props,
        to: {
          ...props.to,
          pathname: ?props.to.pathname->Option.map(pathname =>
            switch pathname->String.startsWith("/") {
            | true => "/" ++ locale.lang ++ pathname
            | false => pathname
            }
          ),
        },
      }

      <Router.LinkWithOpts {...props} />
    }
  }
}
//
// @genType
// let default = make

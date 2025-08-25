type locale = {
  locale: string,
  detectedLocale?: string,
  detectedLang?: string,
  lang: string,
  timezone: string,
}

let parseLang = (loc: string) => {
  loc->String.split("-")->Array.get(0)
}
let parseLocale = (loc: string) => {
  loc->String.split("-")->Array.get(1)
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
        string,
        string,
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
  // Locale-aware navigate hook: prefixes leading "/" paths with current locale.lang unless already present
  let useNavigate = () => {
    let navigate = Router.useNavigate()
    let locale = React.useContext(LocaleContext.context)
    (target: string, opts) => {
      let prefixed = target->String.startsWith("/") ? "/" ++ locale.lang ++ target : target
      navigate(prefixed, opts)
    }
  }

  let useOriginalNavigate = Router.useNavigate
  let useLocation = Router.useLocation
}

module DetectedLang = {
  @react.component
  let make = () => {
    let (langNotice, setLangNotice) = React.useState(() => false)
    let {pathname} = Router.useLocation()
    let locale = React.useContext(LocaleContext.context)
    let navigate = Router.useOriginalNavigate()
    React.useEffect1(() => {
      locale.detectedLang
      ->Option.map(detectedLang => {
        if detectedLang != locale.lang {
          Localized.loadMessages(
            Some(detectedLang),
            Lingui.loadMessagesForDetected({
              ja: Lingui.import("../../locales/src/components/pages/DefaultLayoutMap.re/ja"),
              en: Lingui.import("../../locales/src/components/pages/DefaultLayoutMap.re/en"),
            }),
          )->Promise.thenResolve(
            _ => {
              Lingui.detectedI18n.activate(detectedLang)
              setLangNotice(_ => true)
              ()
            },
          )
        } else {
          setLangNotice(_ => false)
          Js.Promise.resolve()
        }
      })
      ->ignore
      None
    }, [locale.lang])
    <div className="mx-auto max-w-7xl mb-4">
      {langNotice
        ? <InfoAlert
            cta={Lingui.detectedI18n->Lingui.trans("8hwlOf")->React.string}
            ctaClick={() => {
              navigate(
                I18n.getLangPath(locale.detectedLang->Option.getOr("en")) ++
                I18n.getBasePath(locale.lang, pathname),
                None,
              )
            }}>
            {Lingui.detectedI18n
            ->Lingui.trans("/96Fb+")
            ->React.string}
          </InfoAlert>
        : React.null}
    </div>
  }
}
//
// @genType
// let default = make

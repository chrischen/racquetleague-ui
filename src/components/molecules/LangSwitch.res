open Router;
module LocaleButton = {
  type t = {locale: string, display: string}
  @genType @react.component
  let make = (~locale: t, ~path, ~active) => {
    let locPath = locale.locale == "en" ? "" : "/" ++ locale.locale
    switch active {
    | true => <span> {React.string(locale.display)} </span>
    | false =>
      <Link to={locPath ++ path}>
        <span>
          {React.string(locale.display)}
        </span>
      </Link>
    }
  }
}
let locales = [
  {LocaleButton.locale: "en", display: "english"},
  {locale: "ja", display: "日本語"},
]
@genType @react.component
let make = () => {
  let {i18n: {locale}} = Lingui.useLingui()
  let {pathname} = Router.useLocation()
  let basePath = switch locale {
  | "en" => "/" ++ pathname->String.replaceRegExp(Js.Re.fromString("^/(" ++ locale ++ "/?|)"), "")
  | locale => "/" ++ pathname->String.replaceRegExp(Js.Re.fromString("^/" ++ locale ++ "/?"), "")
  }

  locales
  ->Belt.Array.mapWithIndex((index, loc) => {
    <React.Fragment key=loc.locale>
      {index > 0 ? " | "->React.string : React.null}
      <LocaleButton locale={loc} path={basePath} active={loc.locale == locale} />
    </React.Fragment>
  })
  ->React.array
}
type array<'a> = array<'a>


@genType
let default = make

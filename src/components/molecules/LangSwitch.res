open Router
module LocaleButton = {
  type t = {lang: string, display: string}
  @genType @react.component
  let make = (~locale: t, ~path, ~active) => {
    let locPath = I18n.getLangPath(locale.lang)
    switch active {
    | true => <span> {React.string(locale.display)} </span>
    | false =>
      <Link to={locPath ++ path}>
        <span> {React.string(locale.display)} </span>
      </Link>
    }
  }
}
let locales = [{LocaleButton.lang: "en", display: "english"}, {lang: "ja", display: "日本語"}]
@genType @react.component
let make = () => {
  let {i18n: {locale}} = Lingui.useLingui()
  let {pathname, search} = Router.useLocation()
  let basePath = I18n.getBasePath(locale, pathname)
  // Preserve only the current query string (not the hash) when switching locales
  let basePathWithQuery = basePath ++ search

  locales
  ->Belt.Array.mapWithIndex((index, loc) => {
    <React.Fragment key=loc.lang>
      {index > 0 ? " | "->React.string : React.null}
      <LocaleButton locale={loc} path={basePathWithQuery} active={loc.lang == locale} />
    </React.Fragment>
  })
  ->React.array
}
type array<'a> = array<'a>

@genType
let default = make

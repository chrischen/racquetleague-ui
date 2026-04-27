open Router

module UpdateLocaleMutation = %relay(`
  mutation LangSwitchUpdateLocaleMutation($input: UpdateLocaleInput!) {
    updateLocale(input: $input) {
      viewer {
        locale
      }
      errors {
        message
      }
    }
  }
`)

type locale = {lang: string, display: string, flag: string}

module LocaleButton = {
  @genType @react.component
  let make = (~locale: locale, ~active) => {
    switch active {
    | true => <span className="font-semibold text-gray-900"> {React.string(locale.display)} </span>
    | false => <span className="text-gray-700"> {React.string(locale.display)} </span>
    }
  }
}

let locales = [
  {lang: "en", display: "English", flag: "🇺🇸"},
  {lang: "ja", display: "日本語", flag: "🇯🇵"},
  {lang: "th", display: "ไทย", flag: "🇹🇭"},
  {lang: "zh-TW", display: "繁體中文", flag: "🇹🇼"},
  {lang: "zh-CN", display: "简体中文", flag: "🇨🇳"},
  {lang: "ko", display: "한국어", flag: "🇰🇷"},
  {lang: "vi", display: "Tiếng Việt", flag: "🇻🇳"},
]

module Dropdown = HeadlessUi.Menu
module DropdownButton = {
  @module("../catalyst/dropdown.tsx") @react.component
  external make: (
    ~className: string=?,
    ~\"as": React.component<'a>=?,
    ~children: React.element,
    ~outline: bool=?,
  ) => React.element = "DropdownButton"
}
module DropdownMenu = {
  @module("../catalyst/dropdown.tsx") @react.component
  external make: (
    ~className: string=?,
    ~anchor: string=?,
    ~children: React.element,
  ) => React.element = "DropdownMenu"
}
module DropdownItem = {
  @module("../catalyst/dropdown.tsx") @react.component
  external make: (
    ~href: string=?,
    ~className: string=?,
    ~\"aria-label": string=?,
    ~children: React.element,
    ~onClick: JsxEventU.Mouse.t => unit=?,
  ) => React.element = "DropdownItem"
}
module DropdownLabel = {
  @module("../catalyst/dropdown.tsx") @react.component
  external make: (~className: string=?, ~children: React.element) => React.element = "DropdownLabel"
}

@genType @react.component
let make = () => {
  let {i18n: {locale}} = Lingui.useLingui()
  let {pathname, search} = Router.useLocation()
  let navigate = Router.useNavigate()
  let (commitUpdateLocale, _) = UpdateLocaleMutation.use()
  let basePath = I18n.getBasePath(locale, pathname)
  // Preserve only the current query string (not the hash) when switching locales
  let basePathWithQuery = basePath ++ search

  let currentLocale =
    locales
    ->Array.find(loc => loc.lang == locale)
    ->Option.getOr({
      lang: "en",
      display: "English",
      flag: "🇺🇸",
    })

  <Dropdown>
    <DropdownButton
      className="inline-flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
      <span> {currentLocale.flag->React.string} </span>
      <span> {currentLocale.display->React.string} </span>
      <HeroIcons.ChevronDownIcon className="w-4 h-4" />
    </DropdownButton>
    <DropdownMenu className="min-w-48 z-[100]" anchor="bottom start">
      {locales
      ->Array.map(loc => {
        let isActive = loc.lang == locale
        let locPath = I18n.getLangPath(loc.lang) ++ basePathWithQuery

        <DropdownItem
          key={loc.lang}
          onClick={_ => {
            navigate(locPath, None)
            commitUpdateLocale(
              ~variables={input: {locale: loc.lang}},
            )->RescriptRelay.Disposable.ignore
          }}
          className={isActive ? "bg-gray-50" : ""}>
          <div className="flex items-center gap-3">
            <span className="text-lg"> {loc.flag->React.string} </span>
            <DropdownLabel>
              <LocaleButton locale={loc} active={isActive} />
            </DropdownLabel>
          </div>
        </DropdownItem>
      })
      ->React.array}
    </DropdownMenu>
  </Dropdown>
}
type array<'a> = array<'a>

@genType
let default = make

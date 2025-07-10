module Outlet = {
  @module("react-router-dom") @react.component
  external make: (~context: 'a=?) => React.element = "Outlet"
}

@module("react-router-dom")
external useParams: unit => 'a = "useParams"

type navOpts = {replace: bool}
type navigate = (string, option<navOpts>) => unit
@module("react-router-dom")
external useNavigate: unit => navigate = "useNavigate"

// @TODO: Binding to location type may be wrong
type location<'a> = {pathname: string, search: string, hash?: string, state?: 'a}
@module("react-router-dom") external useLocation: unit => location<'a> = "useLocation"

module SearchParams = {
  type t

  @new
  external make: string => t = "URLSearchParams"
  @send external getNull: (t, string) => Js.Null.t<string> = "get"
  let get: (t, string) => option<string> = (t, key) => getNull(t, key)->Js.Null.toOption
  @send external getAll: (t, string) => option<array<string>> = "getAll"
  @send external entries: t => option<Js.Array2.array_like<array<array<string>>>> = "entries"
  @send external toString: t => string = "toString"
  @send external set: (t, string, string) => unit = "set"
  @send external delete: (t, string) => unit = "delete"
  @send external deleteValue: (t, string, string) => unit = "delete"

  @new
  external fromEntries: option<Js.Array2.array_like<array<array<string>>>> => t = "URLSearchParams"
}
module ImmSearchParams = {
  type t

  @module("immurl") @new
  external make: string => t = "ImmutableURLSearchParams"

  @send external getNull: (t, string) => Js.Null.t<string> = "get"
  let get: (t, string) => option<string> = (t, key) => getNull(t, key)->Js.Null.toOption
  @send external getAll: (t, string) => option<array<string>> = "getAll"
  @send external entries: t => option<Js.Array2.array_like<array<array<string>>>> = "entries"
  @send external toString: t => string = "toString"
  @send external set: (t, string, string) => t = "set"
  @send external delete: (t, string) => t = "delete"
  @send external deleteValue: (t, string, string) => t = "delete"

  let fromSearchParams: SearchParams.t => t = searchParams =>
    make(SearchParams.toString(searchParams))

  let toSearchParams: t => SearchParams.t = t => t->entries->SearchParams.fromEntries
}

@module("react-router-dom")
external useSearchParams: unit => (SearchParams.t, SearchParams.t => unit) = "useSearchParams"

@module("react-router-dom")
external useSearchParamsFunc: unit => (SearchParams.t, (SearchParams.t => SearchParams.t) => unit) =
  "useSearchParams"
module URL = {
  type t = {searchParams: SearchParams.t}

  @new external make: string => t = "URL"
}
module RouterRequest = {
  type t = {url: string}
}
@module("react-router-dom")
external defer: 'a => Js.Null.t<'a> = "defer"

module Await = {
  @module("react-router-dom") @react.component
  external make: (
    ~children: 'a => React.element,
    ~resolve: Js.Promise.t<'a>,
    ~errorElement: React.element,
  ) => React.element = "Await"
}

@module("react-router-dom")
external useAsyncValue: unit => 'a = "useAsyncValue"

module Link = {
  @react.component @module("react-router-dom")
  external make: (
    ~to: string,
    ~children: React.element,
    ~className: string=?,
    ~relative: string=?,
    ~reloadDocument: bool=?,
    ~unstable_viewTransition: bool=?,
    ~ariaCurrent: [> #page | #"false"]=?,
    ~rel: string=?,
    ~target: string=?,
  ) => React.element = "Link"
}
module NavLink = {
  type linkState = {isActive: bool, isPending: bool, isTransitioning: bool}
  @react.component @module("react-router-dom")
  external make: (
    ~to: string,
    ~children: React.element,
    ~className: linkState => string=?,
    ~relative: string=?,
    ~onClick: 'a => unit=?,
    ~reloadDocument: bool=?,
    ~unstable_viewTransition: bool=?,
  ) => // ~ariaCurrent: [> #page | #"false"]=?,
  React.element = "NavLink"
}

@module("react-router-dom")
external createSearchParams: 'a => SearchParams.t = "createSearchParams"

module LinkWithOpts = {
  type to = {
    pathname?: string,
    search?: string,
  }
  @react.component @module("react-router-dom")
  external make: (
    ~to: to,
    ~children: React.element,
    ~className: string=?,
    ~relative: string=?,
    ~reloadDocument: bool=?,
    ~unstable_viewTransition: bool=?,
  ) => React.element = "Link"
}

@module("react-router-dom")
external useOutletContext: unit => 'a = "useOutletContext"

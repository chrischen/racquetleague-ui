module Outlet = {
  @module("react-router-dom") @react.component
  external make: unit => React.element = "Outlet"
}

@module("react-router-dom")
external useParams: unit => 'a = "useParams"

type navOpts = {replace: bool}
type navigate = (string, option<navOpts>) => unit
@module("react-router-dom")
external useNavigate: unit => navigate = "useNavigate"

@module("react-router-dom")
external useSearchParams: unit => (string, string => unit) = "useSearchParams"

// @TODO: Binding to location type may be wrong
type location<'a> = {pathname: string, search: string, hash?: string, state?: 'a}
@module("react-router-dom") external useLocation: unit => location<'a> = "useLocation"

module SearchParams = {
  type t

  @send external get: (t, string) => option<string> = "get";
  @send external getAll: (t, string) => option<array<string>> = "getAll";
  @send external entries: (t) => option<Js.Array2.array_like<array<array<string>>>> = "entries";
  @send external toString: t => string= "toString";
}
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
  ) => React.element = "Link"
}

@module("react-router-dom")
external createSearchParams: 'a => SearchParams.t = "createSearchParams"

module LinkWithOpts = {
  type to= {
    pathname?: string,
    search?: string
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

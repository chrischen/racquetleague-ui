%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
open LangProvider.Router

@module("./btn_login_base@2x.png")
external btn_login_base: string = "default"

type loginParams = {return?: string}
@react.component
let make = (~className: option<string>=?) => {
  let ts = Lingui.UtilString.t;
  let {pathname} = Router.useLocation()
  let baseClass = "";
  <LinkWithOpts
    className={className->Option.map(c => Util.cx([c, baseClass]))->Option.getOr(baseClass)}
    to={
      pathname: "/oauth-login",
      search: Router.createSearchParams({return: pathname})->Router.SearchParams.toString,
    }>
    <div 
    alt={ts`login with Line`}
    className="inline-block align-middle">
    <img className="w-32" src={btn_login_base} alt={ts`login with Line`} />
    // {t`login with Line`}
    </div>
  </LinkWithOpts>
}

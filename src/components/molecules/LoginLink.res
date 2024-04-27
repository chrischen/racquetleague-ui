%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

type loginParams = {
  return?: string
}
@react.component
let make = (~className: option<string>=?) => {
  let { pathname } = Router.useLocation();
  <Router.LinkWithOpts ?className to={pathname: "/oauth-login", search: Router.createSearchParams({return: pathname})->Router.SearchParams.toString}> {t`login with Line`} </Router.LinkWithOpts>
}

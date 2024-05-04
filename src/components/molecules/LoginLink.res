%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
open LangProvider.Router;

type loginParams = {
  return?: string
}
@react.component
let make = (~className: option<string>=?) => {
  let { pathname } = Router.useLocation();
  let locale = React.useContext(LangProvider.LocaleContext.context);
  <LinkWithOpts ?className to={pathname: "/oauth-login", search: Router.createSearchParams({return: pathname})->Router.SearchParams.toString}> {t`login with Line`} </LinkWithOpts>
}

%%raw("import { t } from '@lingui/macro'")

@react.component
let make = () => {
  let {search} = Router.useLocation();
  open Lingui.Util
  let search = search == "" ? None : Some(search);
  <WaitForMessages>
    {_ =>
      <Layout.Container>
        <h1>
          <div className="text-base leading-6 text-gray-500"> {t`login with Line`} </div>
          <div className="mt-1 text-2xl font-semibold leading-6 text-gray-900">
            {t`login failed`}
          </div>
        </h1>
        <h2 className="mt-4 text-lg font-semibold leading-6 text-gray-900">
          {t`are you in a private browsing mode?`}
        </h2>
        <p className="mt-2 text-base leading-6 text-gray-500">
          {t`please try again outside of private browsing as it can interfere with Line login. if the problem persists, you can try the safe-mode login button below.`}
        </p>
        <a
          href={"/login" ++
          search->Option.map(search => search ++ "&safe=true")->Option.getOr("?safe=true")}
          className="block mt-4 text-2xl">
          {t`safe-mode login with Line`}
        </a>
      </Layout.Container>}
  </WaitForMessages>
}

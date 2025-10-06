%%raw("import { t } from '@lingui/macro'")

type loaderData = None
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@react.component
let make = () => {
  open Lingui.Util
  let {search} = Router.useLocation()
  let (params, _) = Router.useSearchParams()
  let returnUrl = params->Router.SearchParams.get("return")->Option.map(l => l)
  <WaitForMessages>
    {_ =>
      <Layout.Container>
        <h1>
          <div className="text-base leading-6 text-gray-500"> {t`login with Line`} </div>
          <div className="mt-1 text-2xl font-semibold leading-6 text-gray-900">
            {t`privacy disclosure`}
          </div>
        </h1>
        <h2 className="mt-4 text-lg font-semibold leading-6 text-gray-900">
          {t`we will collect the following information from your Line account`}
        </h2>
        <dl className="">
          <dt className="mt-4 text-lg font-semibold leading-6 text-gray-900">
            {t`email address`}
          </dt>
          <dd className="mt-2 text-base leading-6 text-gray-500">
            <ul className="list-disc list-inside">
              <li className="mt-1">
                {t`notification of updates or cancellations to events (you can opt out)`}
              </li>
              <li className="mt-1">
                {t`event organizers and other users cannot view your email`}
              </li>
            </ul>
          </dd>
          <dt className="mt-4 text-lg font-semibold leading-6 text-gray-900">
            {t`display name`}
          </dt>
          <dd className="mt-2 text-base leading-6 text-gray-500">
            {t`publicly displayed on event attendance lists`}
          </dd>
          <dt className="mt-4 text-lg font-semibold leading-6 text-gray-900">
            {t`profile picture`}
          </dt>
          <dd className="mt-2 text-base leading-6 text-gray-500">
            {t`publicly displayed on event attendance lists`}
          </dd>
        </dl>
        <a href={"/login" ++ search} >
          <Button.Button className="block mt-4 text-2xl"> {t`login with Line`} </Button.Button>
        </a>
        <Router.Link to={returnUrl->Option.getOr("/")} className="block mt-4 text">
          {t`cancel login`}
        </Router.Link>
      </Layout.Container>}
  </WaitForMessages>
}

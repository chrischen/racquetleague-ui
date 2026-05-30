%%raw("import { t } from '@lingui/macro'")

type loaderData = None
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@module("../../entry/auth-client")
external authClient: BetterAuth.authClient = "authClient"

// Status of the user-code approval flow.
type status =
  | Idle
  | Submitting
  | Approved
  | Denied
  | Errored(string)

@react.component
let make = () => {
  open Lingui.Util
  let (params, _) = Router.useSearchParams()
  let initialUserCode = params->Router.SearchParams.get("user_code")->Option.getOr("")
  let (userCode, setUserCode) = React.useState(() => initialUserCode)
  let (status, setStatus) = React.useState(() => Idle)
  let viewer = GlobalQuery.useViewer()
  let navigate = Router.useNavigate()

  // Browser came from the PWA's external `/device` link. The user must be
  // logged in here (system browser) for `device.approve` to associate the
  // pending device with their session.
  let isLoggedIn = viewer.user->Option.isSome

  // Return back to this device page (preserving the code) after login.
  let returnHref = {
    let base = "/device"
    let qs = userCode == "" ? "" : "?user_code=" ++ userCode
    base ++ qs
  }

  // Approving a device only makes sense when signed in. When there's no user,
  // bounce to the login page and come back here (with the code) afterwards.
  // `replace` keeps this redirect out of history so Back doesn't land on an
  // empty device page.
  React.useEffect1(() => {
    if !isLoggedIn {
      navigate(
        "/oauth-login?return=" ++ Js.Global.encodeURIComponent(returnHref),
        Some({replace: true}),
      )
    }
    None
  }, [isLoggedIn])

  let handleApprove = async () => {
    if userCode == "" {
      setStatus(_ => Errored("Missing code"))
    } else {
      setStatus(_ => Submitting)
      try {
        let result = await authClient.device.approve({userCode: userCode})
        switch result.error->Js.Null.toOption {
        | None => setStatus(_ => Approved)
        | Some(err) => setStatus(_ => Errored(err.message))
        }
      } catch {
      | exn =>
        let message =
          exn->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")
        setStatus(_ => Errored(message))
      }
    }
  }

  let handleDeny = async () => {
    if userCode == "" {
      setStatus(_ => Errored("Missing code"))
    } else {
      setStatus(_ => Submitting)
      try {
        let result = await authClient.device.deny({userCode: userCode})
        switch result.error->Js.Null.toOption {
        | None => setStatus(_ => Denied)
        | Some(err) => setStatus(_ => Errored(err.message))
        }
      } catch {
      | exn =>
        let message =
          exn->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")
        setStatus(_ => Errored(message))
      }
    }
  }

  <WaitForMessages>
    {_ =>
      <div className="w-full flex justify-center px-4 py-10 sm:py-16">
        <div className="w-full max-w-md">
          <div className="text-center mb-8">
            <div
              className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-blue-600 text-white mb-4 shadow-lg shadow-blue-600/20">
              <Lucide.Smartphone className="w-7 h-7" />
            </div>
            <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white mb-2">
              {t`Approve sign-in`}
            </h1>
            <p className="text-gray-600 dark:text-gray-400">
              {t`Confirm the code shown in your app to finish signing in.`}
            </p>
          </div>
          <div
            className="bg-white dark:bg-[#1e1f23] rounded-2xl shadow-xl shadow-gray-200/60 dark:shadow-black/30 p-6 sm:p-8 border border-gray-100 dark:border-[#2a2b30] space-y-4">
            {if !isLoggedIn {
              // Either the session is still loading or we're about to redirect
              // to login (see the effect above). Show a neutral placeholder.
              <p className="text-sm text-gray-600 dark:text-gray-400 text-center">
                {t`Redirecting to sign in…`}
              </p>
            } else {
              <>
                <div>
                  <label
                    htmlFor="user_code"
                    className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    {t`Code from your app`}
                  </label>
                  <input
                    id="user_code"
                    type_="text"
                    value={userCode}
                    onChange={e => {
                      let v = ReactEvent.Form.target(e)["value"]
                      setUserCode(_ => v)
                    }}
                    autoComplete="one-time-code"
                    className="block w-full px-3 py-3 border border-gray-300 dark:border-[#3a3b40] dark:bg-[#222326] dark:text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors font-mono text-lg tracking-widest text-center"
                    placeholder="XXXX-XXXX"
                  />
                </div>
                {switch status {
                | Approved =>
                  <div
                    className="p-4 bg-green-50 dark:bg-green-500/10 border border-green-200 dark:border-green-500/30 rounded-lg text-sm text-green-800 dark:text-green-300">
                    {t`Device approved! You can return to the app.`}
                  </div>
                | Denied =>
                  <div
                    className="p-4 bg-yellow-50 dark:bg-yellow-500/10 border border-yellow-200 dark:border-yellow-500/30 rounded-lg text-sm text-yellow-800 dark:text-yellow-300">
                    {t`Sign-in request denied.`}
                  </div>
                | Errored(msg) =>
                  <div
                    className="p-3 bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/30 rounded-lg text-sm text-red-800 dark:text-red-300">
                    {React.string(msg)}
                  </div>
                | Idle | Submitting => React.null
                }}
                {switch status {
                | Approved | Denied => React.null
                | _ =>
                  <div className="flex gap-3">
                    <button
                      disabled={status == Submitting}
                      onClick={_ => handleDeny()->ignore}
                      className="flex-1 px-4 py-3 border border-gray-300 dark:border-[#3a3b40] text-gray-700 dark:text-gray-200 rounded-lg font-medium hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors disabled:opacity-60">
                      {t`Deny`}
                    </button>
                    <button
                      disabled={status == Submitting}
                      onClick={_ => handleApprove()->ignore}
                      className="flex-1 bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors disabled:opacity-60">
                      {status == Submitting ? {t`Working…`} : {t`Approve`}}
                    </button>
                  </div>
                }}
              </>
            }}
          </div>
        </div>
      </div>}
  </WaitForMessages>
}

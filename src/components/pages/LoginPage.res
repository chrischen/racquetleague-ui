%%raw("import { t } from '@lingui/macro'")

type loaderData = None
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@module("../../entry/auth-client")
external authClient: BetterAuth.authClient = "authClient"

external alert: string => unit = "alert"

let handleSocialLogin = async (returnUrl: option<string>) => {
  let ts = Lingui.UtilString.t
  Console.log("Starting social login flow")

  let callbackURL = returnUrl->Option.getOr("/")

  try {
    let result = await authClient.signIn.social({
      provider: "line",
      callbackURL,
    })

    let error = result.error->Js.Null.toOption
    let data = result.data->Js.Null.toOption

    switch (data, error) {
    | (Some(_), None) => ()
    | (_, Some(error)) => alert(ts`Login failed: ${error.message}`)
    | _ => ()
    }
  } catch {
  | exn => {
      let message =
        exn->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")
      alert(ts`An error occurred: ${message}`)
    }
  }
}

let handleMagicLinkLogin = async (email: string, returnUrl: option<string>) => {
  let ts = Lingui.UtilString.t
  Console.log2("Starting magic link login flow with email:", email)

  let callbackURL = returnUrl->Option.getOr("/")

  try {
    let result = await authClient.signIn.magicLink({
      email,
      callbackURL,
    })
    Console.log2("Magic link result:", result)

    let error = result.error->Js.Null.toOption
    let data = result.data->Js.Null.toOption

    switch (data, error) {
    | (_, Some(error)) => {
        Console.error2("Error:", error)
        alert(ts`Failed to send magic link: ${error.message}`)
      }
    | (Some(_), None) => alert(ts`Check your email for a magic link to sign in!`)
    | _ => alert(ts`Check your email for a magic link to sign in!`)
    }
  } catch {
  | exn => {
      Console.error2("Exception:", exn)
      let message =
        exn->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")
      alert(ts`An error occurred: ${message}`)
    }
  }
}

// Device-authorization client id used by the PWA.
let pwaClientId = "pwa"

// External browser navigation helpers. On iOS standalone PWAs, neither
// `target="_blank"`, `window.open`, nor a plain `window.location` escape the
// PWA webview — same-origin/in-scope links stay inside the app and external
// ones open an in-app modal web view, not the real Safari app. The only
// reliable web technique (iOS 17+) is Apple's undocumented `x-safari-` URL
// scheme, which forces the system Safari app. It requires an https URL.
// `setHref` is used for the in-PWA redirect once sign-in completes.
@val @scope(("window", "location")) external setHref: string => unit = "assign"

// Open `url` in the real Safari app from inside a standalone PWA on iOS.
// On iOS 17+ the undocumented `x-safari-` scheme forces the system Safari
// app (it requires an https URL). On every other platform — Android, desktop,
// iOS Safari tabs — a normal `target="_blank"` anchor already opens the
// default browser correctly, so this returns false there and lets the
// anchor's default behavior run.
//
// Returns true when it handled the navigation (caller should preventDefault).
let openInSystemSafari = (url: string): bool => {
  if InstallPwa.isIosDevice() && url->String.startsWith("https://") {
    setHref("x-safari-" ++ url)
    true
  } else {
    false
  }
}

@react.component
let make = () => {
  open Lingui.Util
  let (params, _) = Router.useSearchParams()
  let returnUrl = params->Router.SearchParams.get("return")
  let errorParam = params->Router.SearchParams.get("error")
  let (email, setEmail) = React.useState(() => "")

  // `?device=1` forces the device-authorization (PWA) flow for manual testing,
  // regardless of whether we're actually running in standalone mode.
  let forceDeviceFlow = switch params->Router.SearchParams.get("device") {
  | Some("1") | Some("true") => true
  | _ => false
  }

  // Standalone detection runs only on the client so SSR keeps the regular UI.
  let (isStandalone, setIsStandalone) = React.useState(() => false)
  React.useEffect0(() => {
    setIsStandalone(_ => forceDeviceFlow || InstallPwa.isStandalone())
    None
  })

  // Device-authorization flow state (used when isStandalone is true).
  let (deviceCode, setDeviceCode) = React.useState((): option<BetterAuth.deviceCodeData> => None)
  let (deviceError, setDeviceError) = React.useState((): option<string> => None)
  let (deviceStarting, setDeviceStarting) = React.useState(() => false)
  let session = authClient.useSession()

  // Once we have a device code, poll `/device/token` until the server marks
  // the device approved. On success the server hook (`hooks.after` on
  // /device/token) sets the session cookie on this response — the auth
  // client uses `credentials: include` by default. We then refetch the
  // session and bounce to returnUrl.
  //
  // Note: better-auth's typed `error.code` carries the HTTP status code name
  // (e.g. "BAD_REQUEST"), not the RFC 8628 oauth code. The RFC code is in the
  // response body as `error` (e.g. "authorization_pending"). We read the raw
  // error object to pick that up.
  React.useEffect2(() => {
    switch deviceCode {
    | None => None
    | Some(code: BetterAuth.deviceCodeData) =>
      let cancelled = ref(false)
      // Server returns interval in seconds; clamp to a sensible minimum so a
      // missing/zero value doesn't busy-loop.
      let intervalMs = Js.Math.max_int(code.interval, 1) * 1000
      let rec poll = async () => {
        if cancelled.contents {
          ()
        } else {
          let result = await authClient.device.token({
            grant_type: BetterAuth.deviceGrantType,
            device_code: code.device_code,
            client_id: pwaClientId,
          })
          let data = result.data->Js.Null.toOption
          let error = result.error->Js.Null.toOption
          Console.log3("device.token poll:", data, error)
          switch (data, error) {
          | (Some(_), _) =>
            // Cookie set on this response by the server hook. Hard navigate
            // so the new cookie is included in subsequent requests.
            session.refetch()
            setHref(returnUrl->Option.getOr("/"))
          | (_, Some(err)) =>
            // Inspect the raw oauth `error` field on the body.
            let rfcCode: option<string> = (Obj.magic(err): {..})["error"]->Js.Nullable.toOption
            switch rfcCode {
            | Some("authorization_pending") =>
              let _ = Js.Global.setTimeout(() => poll()->ignore, intervalMs)
            | Some("slow_down") =>
              let _ = Js.Global.setTimeout(() => poll()->ignore, intervalMs + 5000)
            | Some("access_denied") => setDeviceError(_ => Some("Sign-in was denied."))
            | Some("expired_token") =>
              setDeviceError(_ => Some("The code expired. Please try again."))
              setDeviceCode(_ => None)
            | Some(other) => setDeviceError(_ => Some(other))
            | None =>
              // No RFC code — if it's a 400 we're probably still waiting.
              if err.status == 400 {
                let _ = Js.Global.setTimeout(() => poll()->ignore, intervalMs)
              } else {
                setDeviceError(_ => Some(err.message))
              }
            }
          | _ =>
            // Empty response — keep polling rather than giving up.
            let _ = Js.Global.setTimeout(() => poll()->ignore, intervalMs)
          }
        }
      }
      // Kick off first poll immediately so the user sees activity. Subsequent
      // polls space themselves out by `intervalMs`.
      poll()->ignore
      Some(() => cancelled := true)
    }
  }, (deviceCode, returnUrl))

  let handleStartDeviceFlow = async () => {
    setDeviceStarting(_ => true)
    setDeviceError(_ => None)
    try {
      let result = await authClient.device.code({client_id: pwaClientId})
      switch (result.data->Js.Null.toOption, result.error->Js.Null.toOption) {
      | (Some(code), _) =>
        // Don't auto-open: on iOS standalone PWAs, programmatic `window.open`
        // stays inside the webview. The user must tap a real <a target="_blank">
        // anchor (rendered below) to break out into the system browser.
        setDeviceCode(_ => Some(code))
      | (_, Some(error)) => setDeviceError(_ => Some(error.message))
      | _ => setDeviceError(_ => Some("Failed to start device authorization"))
      }
    } catch {
    | exn =>
      let message =
        exn->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.message(e))->Option.getOr("Unknown error")
      setDeviceError(_ => Some(message))
    }
    setDeviceStarting(_ => false)
  }

  let errorMessage = switch errorParam {
  | Some("email_not_found") =>
    Some(
      t`Your LINE account does not have an email associated. Please set an email address for your account from the LINE app, and then try again.`,
    )
  | Some(x) => Some(t`An error occurred during sign in. Please try again.`)
  | None => None
  }

  let handleSubmit = e => {
    e->ReactEvent.Form.preventDefault
    if email != "" {
      handleMagicLinkLogin(email, returnUrl)->ignore
    }
  }

  <WaitForMessages>
    {_ =>
      <div
        className="min-h-screen w-full bg-gradient-to-br from-blue-50 via-white to-gray-50 flex items-center justify-center p-4">
        // Back Button
        <Router.Link
          to={returnUrl->Option.getOr("/")}
          className="fixed top-6 left-6 flex items-center gap-2 text-gray-600 hover:text-gray-900 transition-colors">
          <Lucide.MoveLeft className="w-5 h-5" />
          <span className="font-medium"> {t`Back to events`} </span>
        </Router.Link>
        <div className="w-full max-w-md">
          // Error Message
          {errorMessage
          ->Option.map(msg =>
            <div
              className="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
              <Lucide.AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
              <p className="text-sm text-red-800"> {msg} </p>
            </div>
          )
          ->Option.getOr(React.null)}
          // Logo/Brand
          <div className="text-center mb-8">
            <div
              className="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-2xl mb-4 shadow-lg">
              <svg
                className="w-8 h-8 text-white"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
            </div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2"> {t`Sign in to Pkuru.com`} </h1>
            <p className="text-gray-600"> {t`New users will be automatically registered`} </p>
          </div>
          // Login Card
          <div className="bg-white rounded-2xl shadow-xl p-8 border border-gray-100">
            {if isStandalone {
              // -------------------------------------------------------------
              // Device Authorization (PWA standalone) UI
              // -------------------------------------------------------------
              <div className="space-y-4">
                <p className="text-sm text-gray-600">
                  {t`The installed app uses a separate browser, so we'll complete sign-in in your system browser. Tap the button below, sign in there, and we'll automatically sign you in here.`}
                </p>
                {switch deviceCode {
                | None =>
                  <button
                    disabled={deviceStarting}
                    onClick={_ => handleStartDeviceFlow()->ignore}
                    className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200 shadow-sm disabled:opacity-60">
                    {deviceStarting ? {t`Starting…`} : {t`Sign in via system browser`}}
                  </button>
                | Some(code) =>
                  <div className="space-y-3">
                    <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
                      <p className="text-xs uppercase tracking-wide text-blue-700 mb-1">
                        {t`Your code`}
                      </p>
                      <p className="text-2xl font-mono font-bold text-blue-900 tracking-widest">
                        {React.string(code.user_code)}
                      </p>
                      <p className="text-xs text-blue-700 mt-2">
                        {t`If your browser didn't open, visit:`}
                        {React.string(" ")}
                        <span className="font-mono break-all">
                          {React.string(code.verification_uri)}
                        </span>
                      </p>
                    </div>
                    <a
                      href={code.verification_uri_complete->Option.getOr(code.verification_uri)}
                      target="_blank"
                      rel="noopener noreferrer"
                      onClick={e => {
                        let url =
                          code.verification_uri_complete->Option.getOr(code.verification_uri)
                        if openInSystemSafari(url) {
                          // Handled via the iOS `x-safari-` scheme; suppress the
                          // default in-PWA navigation.
                          e->ReactEvent.Mouse.preventDefault
                        }
                      }}
                      className="block text-center w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 transition-colors duration-200 shadow-sm">
                      {t`Open browser to continue`}
                    </a>
                    <p className="text-xs text-gray-500 text-center">
                      {t`Waiting for sign-in to complete…`}
                    </p>
                  </div>
                }}
                {deviceError
                ->Option.map(msg =>
                  <div
                    className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-800">
                    {React.string(msg)}
                  </div>
                )
                ->Option.getOr(React.null)}
              </div>
            } else {
              <>
                // Social Login Button - LINE
                <div className="space-y-3 mb-6">
                  <button
                    onClick={_ => handleSocialLogin(returnUrl)->ignore}
                    className="w-full flex items-center justify-center gap-3 px-4 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors duration-200 font-medium text-gray-700">
                    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
                      <path
                        d="M19.365 9.863c.349 0 .63.285.63.631 0 .345-.281.63-.63.63H17.61v1.125h1.755c.349 0 .63.283.63.63 0 .344-.281.629-.63.629h-2.386c-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63h2.386c.346 0 .627.285.627.63 0 .349-.281.63-.63.63H17.61v1.125h1.755zm-3.855 3.016c0 .27-.174.51-.432.596-.064.021-.133.031-.199.031-.211 0-.391-.09-.51-.25l-2.443-3.317v2.94c0 .344-.279.629-.631.629-.346 0-.626-.285-.626-.629V8.108c0-.27.173-.51.43-.595.06-.023.136-.033.194-.033.195 0 .375.104.495.254l2.462 3.33V8.108c0-.345.282-.63.63-.63.345 0 .63.285.63.63v4.771zm-5.741 0c0 .344-.282.629-.631.629-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.63-.63.346 0 .628.285.628.63v4.771zm-2.466.629H4.917c-.345 0-.63-.285-.63-.629V8.108c0-.345.285-.63.63-.63.348 0 .63.285.63.63v4.141h1.756c.348 0 .629.283.629.63 0 .344-.282.629-.629.629M24 10.314C24 4.943 18.615.572 12 .572S0 4.943 0 10.314c0 4.811 4.27 8.842 10.035 9.608.391.082.923.258 1.058.59.12.301.079.766.038 1.08l-.164 1.02c-.045.301-.24 1.186 1.049.645 1.291-.539 6.916-4.078 9.436-6.975C23.176 14.393 24 12.458 24 10.314"
                      />
                    </svg>
                    {t`Continue with LINE`}
                  </button>
                </div>
                // Divider
                <div className="relative my-6">
                  <div className="absolute inset-0 flex items-center">
                    <div className="w-full border-t border-gray-300" />
                  </div>
                  <div className="relative flex justify-center text-sm">
                    <span className="px-4 bg-white text-gray-500">
                      {t`or continue with email`}
                    </span>
                  </div>
                </div>
                // Magic Link Form
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                      {t`Email address`}
                    </label>
                    <div className="relative">
                      <div
                        className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <svg
                          className="w-4 h-4 text-gray-400"
                          fill="none"
                          stroke="currentColor"
                          viewBox="0 0 24 24">
                          <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth="2"
                            d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                          />
                        </svg>
                      </div>
                      <input
                        id="email"
                        type_="email"
                        value={email}
                        onChange={e => {
                          let value = ReactEvent.Form.target(e)["value"]
                          setEmail(_ => value)
                        }}
                        className="block w-full pl-10 pr-3 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors"
                        placeholder="you@example.com"
                        required={true}
                      />
                    </div>
                  </div>
                  <button
                    type_="submit"
                    className="w-full bg-blue-600 text-white py-3 px-4 rounded-lg font-medium hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors duration-200 shadow-sm">
                    {t`Send magic link`}
                  </button>
                </form>
              </>
            }}
          </div>
        </div>
      </div>}
  </WaitForMessages>
}

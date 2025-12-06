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

@react.component
let make = () => {
  open Lingui.Util
  let (params, _) = Router.useSearchParams()
  let returnUrl = params->Router.SearchParams.get("return")
  let errorParam = params->Router.SearchParams.get("error")
  let (email, setEmail) = React.useState(() => "")

  let errorMessage = switch errorParam {
  | Some("email_not_found") =>
    Some(
      t`Your LINE account does not have an email associated. Please set an email address for your account from the LINE app, and then try again.`,
    )
  | Some(_) => Some(t`An error occurred during sign in. Please try again.`)
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
                <span className="px-4 bg-white text-gray-500"> {t`or continue with email`} </span>
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
          </div>
        </div>
      </div>}
  </WaitForMessages>
}

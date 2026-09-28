%%raw("import { t } from '@lingui/macro'")

/* Where emailed confirmation links land.

   /verify-email?token=... confirms a receiving email (the settings page's
   "Receiving emails"). The link only works for the account that asked for
   it, so a signed-out visitor is sent to sign in and brought back here, token
   and all. The token is used once per visit, then taken out of the address
   bar.

   /verify-email?purpose=change-email is where better-auth sends someone after
   they open a change-of-account-email link: it has already made the change
   (signing them in if needed), or appended ?error=CODE. This page only shows
   the outcome. */

type loaderData = None
@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@val @scope(("window", "history"))
external replaceState: (Js.Nullable.t<string>, string, string) => unit = "replaceState"
@val @scope(("window", "location")) external pathname: string = "pathname"

module Mutation = %relay(`
  mutation VerifyEmailPageMutation($token: String!) {
    verifyEmail(token: $token) {
      address
      viewer {
        id
        email
        alternateEmails {
          address
          verified
        }
      }
      errors {
        message
      }
    }
  }
`)

type status =
  | Verifying
  | Verified(string)
  // An account with no email took the address as its email.
  | BecameAccountEmail(string)
  | AccountEmailChanged
  | Failed(string)

@react.component
let make = () => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let (params, _) = Router.useSearchParams()
  // Read once: the token is removed from the URL after use.
  let token = React.useRef(params->Router.SearchParams.get("token"))
  let purpose = React.useRef(params->Router.SearchParams.get("purpose"))
  let error = React.useRef(params->Router.SearchParams.get("error"))
  let viewer = GlobalQuery.useViewer()
  let navigate = LangProvider.Router.useNavigate()
  let (commit, _) = Mutation.use()
  let (status, setStatus) = React.useState(() => Verifying)
  let started = React.useRef(false)
  let isLoggedIn = viewer.user->Option.isSome

  let errorCopy = (code: string) =>
    switch code {
    | "INVALID_TOKEN" =>
      ts`This link doesn't work for this account. Make sure you're signed in to the account that added the address, or send a new link from your profile settings.`
    | "EXPIRED_TOKEN" => ts`This link has expired. Send a new one from your profile settings.`
    | "EMAIL_UNAVAILABLE" => ts`This address is already used by another pkuru account.`
    | "MISSING_TOKEN" => ts`This link is incomplete. Open it from the email again.`
    | _ => ts`Something went wrong. Please try again.`
    }

  // better-auth's codes, for a change of account email.
  let changeErrorCopy = (code: string) =>
    switch code {
    | "TOKEN_EXPIRED" => ts`This link has expired. Ask for a new one from your profile settings.`
    | "INVALID_TOKEN" => ts`This link doesn't work. Open it from the email again, or ask for a new one from your profile settings.`
    | "USER_NOT_FOUND" => ts`This link has already been used, or your account email has changed since it was sent.`
    | "INVALID_USER" => ts`You're signed in to a different account. Sign out, then open the link again.`
    | "EMAIL_UNAVAILABLE" => ts`This address is already used by another pkuru account.`
    | _ => ts`Something went wrong. Please try again.`
    }

  React.useEffect1(() => {
    switch (token.current, isLoggedIn) {
    | _ if purpose.current == Some("change-email") =>
      replaceState(Js.Nullable.null, "", pathname)
      switch error.current {
      | Some(code) => setStatus(_ => Failed(changeErrorCopy(code)))
      | None => setStatus(_ => AccountEmailChanged)
      }
    | (None, _) => setStatus(_ => Failed(errorCopy("MISSING_TOKEN")))
    | (Some(token), false) =>
      // Back here, with the token, once signed in. `replace` keeps this
      // redirect out of history.
      navigate(
        "/oauth-login?return=" ++
        Js.Global.encodeURIComponent("/verify-email?token=" ++ token),
        Some({replace: true}),
      )
    | (Some(token), true) if !started.current =>
      started.current = true
      commit(
        ~variables={token: token},
        ~onCompleted=(res, _) => {
          replaceState(Js.Nullable.null, "", pathname)
          switch res.verifyEmail.errors
          ->Option.flatMap(errs => errs->Array.get(0))
          ->Option.map(e => e.message) {
          | Some(code) => setStatus(_ => Failed(errorCopy(code)))
          | None =>
            let address = res.verifyEmail.address->Option.getOr("")
            let isAccountEmail =
              res.verifyEmail.viewer->Option.flatMap(v => v.email) == Some(address)
            setStatus(_ => isAccountEmail ? BecameAccountEmail(address) : Verified(address))
          }
        },
        ~onError=_ => setStatus(_ => Failed(errorCopy(""))),
      )->RescriptRelay.Disposable.ignore
    | _ => ()
    }
    None
  }, [isLoggedIn])

  <WaitForMessages>
    {_ =>
      <div className="w-full flex justify-center px-4 py-10 sm:py-16">
        <div
          className="w-full max-w-md bg-white dark:bg-[#1e1f23] rounded-2xl shadow-xl shadow-gray-200/60 dark:shadow-black/30 p-6 sm:p-8 border border-gray-100 dark:border-[#2a2b30] text-center space-y-4">
          {switch status {
          | Verifying =>
            <>
              <Lucide.Mail className="w-10 h-10 mx-auto text-gray-400" />
              <p className="text-gray-700 dark:text-gray-300"> {t`Confirming your email…`} </p>
            </>
          | Verified(address) =>
            <>
              <Lucide.CheckCircle2 className="w-10 h-10 mx-auto text-green-600 dark:text-green-400" />
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                {t`Email confirmed`}
              </h1>
              <p className="text-gray-700 dark:text-gray-300">
                <span className="font-medium"> {address->React.string} </span>
                {" "->React.string}
                {t`is now one of your receiving emails. Bookings you forward from it to chris@pkuru.com will be added to your events.`}
              </p>
              <LangProvider.Router.Link
                to="/settings/profile"
                className="inline-flex justify-center items-center px-4 py-2.5 rounded-lg text-sm font-bold bg-[#a3e635] text-gray-900 hover:bg-[#84cc16] transition-colors">
                {t`Go to profile settings`}
              </LangProvider.Router.Link>
            </>
          | BecameAccountEmail(address) =>
            <>
              <Lucide.CheckCircle2 className="w-10 h-10 mx-auto text-green-600 dark:text-green-400" />
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                {t`Email confirmed`}
              </h1>
              <p className="text-gray-700 dark:text-gray-300">
                <span className="font-medium"> {address->React.string} </span>
                {" "->React.string}
                {t`is now your account email.`}
              </p>
              <LangProvider.Router.Link
                to="/settings/profile"
                className="inline-flex justify-center items-center px-4 py-2.5 rounded-lg text-sm font-bold bg-[#a3e635] text-gray-900 hover:bg-[#84cc16] transition-colors">
                {t`Go to profile settings`}
              </LangProvider.Router.Link>
            </>
          | AccountEmailChanged =>
            <>
              <Lucide.CheckCircle2 className="w-10 h-10 mx-auto text-green-600 dark:text-green-400" />
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                {t`Account email changed`}
              </h1>
              <p className="text-gray-700 dark:text-gray-300">
                {t`Your account now uses the new address. Your previous address is kept as a receiving email, which you can remove in your profile settings.`}
              </p>
              <LangProvider.Router.Link
                to="/settings/profile"
                className="inline-flex justify-center items-center px-4 py-2.5 rounded-lg text-sm font-bold bg-[#a3e635] text-gray-900 hover:bg-[#84cc16] transition-colors">
                {t`Go to profile settings`}
              </LangProvider.Router.Link>
            </>
          | Failed(message) =>
            <>
              <Lucide.XCircle className="w-10 h-10 mx-auto text-red-500" />
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                {t`Couldn't confirm this email`}
              </h1>
              <p className="text-gray-700 dark:text-gray-300"> {message->React.string} </p>
              <LangProvider.Router.Link
                to="/settings/profile"
                className="inline-flex justify-center items-center px-4 py-2.5 rounded-lg text-sm font-semibold border border-gray-300 dark:border-gray-700 text-gray-800 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors">
                {t`Go to profile settings`}
              </LangProvider.Router.Link>
            </>
          }}
        </div>
      </div>}
  </WaitForMessages>
}

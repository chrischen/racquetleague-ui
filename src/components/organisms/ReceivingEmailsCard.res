%%raw("import { t } from '@lingui/macro'")

/* The addresses a user receives booking emails at: their account email, and
   alternates they've added. Bookings forwarded to chris@pkuru.com are matched
   to an account by the address they come from, so an alternate counts once
   the link emailed to it has been used (on /verify-email). Each mutation
   returns the viewer's list, which Relay writes onto this User record.

   The account email itself is changed through better-auth: a link goes to
   the new address, and /verify-email?purpose=change-email shows the result. */

@module("../../entry/auth-client")
external authClient: BetterAuth.authClient = "authClient"

module Fragment = %relay(`
  fragment ReceivingEmailsCard_user on User {
    id
    email
    alternateEmails {
      address
      verified
    }
  }
`)

module AddMutation = %relay(`
  mutation ReceivingEmailsCardAddMutation($email: String!) {
    addAlternateEmail(email: $email) {
      viewer {
        id
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

module ResendMutation = %relay(`
  mutation ReceivingEmailsCardResendMutation($email: String!) {
    resendAlternateEmailVerification(email: $email) {
      viewer {
        id
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

module RemoveMutation = %relay(`
  mutation ReceivingEmailsCardRemoveMutation($email: String!) {
    removeAlternateEmail(email: $email) {
      viewer {
        id
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

type notice =
  | Sent(string)
  | ChangeSent(string)
  | Failed(string)

let pillClass = "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium shrink-0"

@react.component
let make = (~user) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t
  let data = Fragment.use(user)
  let (commitAdd, adding) = AddMutation.use()
  let (commitResend, resending) = ResendMutation.use()
  let (commitRemove, removing) = RemoveMutation.use()
  let (draft, setDraft) = React.useState(() => "")
  let (notice, setNotice) = React.useState(() => None)
  // The address waiting on "Remove?" confirmation.
  let (removing_, setRemoving) = React.useState(() => None)
  // The account email's "Change" form.
  let (changing, setChanging) = React.useState(() => false)
  let (newEmail, setNewEmail) = React.useState(() => "")
  let (changeBusy, setChangeBusy) = React.useState(() => false)
  let localePath = LangProvider.Router.useLocalePath()

  /* The server answers with a stable code; the wording lives here, in the
     reader's language. */
  let errorCopy = (code: string) =>
    switch code {
    | "INVALID_EMAIL" => ts`That doesn't look like an email address.`
    | "SAME_AS_PRIMARY" => ts`That's already your account email.`
    | "ALREADY_ADDED" => ts`You've already added that address.`
    | "TOO_MANY" => ts`You can add up to 5 receiving emails. Remove one to add another.`
    | "RATE_LIMITED" => ts`Too many emails sent. Please wait a minute and try again.`
    | "SEND_FAILED" => ts`We couldn't send the email. Try "Resend" in a moment.`
    | "NOT_FOUND" => ts`That address isn't on your account any more.`
    | _ => ts`Something went wrong. Please try again.`
    }
  let failed = _ => setNotice(_ => Some(Failed(ts`Something went wrong. Please try again.`)))

  let add = () => {
    let address = draft->String.trim
    if address != "" {
      setNotice(_ => None)
      commitAdd(
        ~variables={email: address},
        ~onCompleted=(res, _) =>
          switch res.addAlternateEmail.errors->Option.flatMap(errs => errs->Array.get(0))->Option.map(e => e.message) {
          | Some(code) => setNotice(_ => Some(Failed(errorCopy(code))))
          | None =>
            setDraft(_ => "")
            setNotice(_ => Some(Sent(address->String.toLowerCase)))
          },
        ~onError=failed,
      )->RescriptRelay.Disposable.ignore
    }
  }

  let resend = (address: string) => {
    setNotice(_ => None)
    commitResend(
      ~variables={email: address},
      ~onCompleted=(res, _) =>
        switch res.resendAlternateEmailVerification.errors->Option.flatMap(errs => errs->Array.get(0))->Option.map(e => e.message) {
        | Some(code) => setNotice(_ => Some(Failed(errorCopy(code))))
        | None => setNotice(_ => Some(Sent(address)))
        },
      ~onError=failed,
    )->RescriptRelay.Disposable.ignore
  }

  let remove = (address: string) => {
    setNotice(_ => None)
    commitRemove(
      ~variables={email: address},
      ~onCompleted=(res, _) =>
        switch res.removeAlternateEmail.errors->Option.flatMap(errs => errs->Array.get(0))->Option.map(e => e.message) {
        | Some(code) => setNotice(_ => Some(Failed(errorCopy(code))))
        | None => ()
        },
      ~onError=failed,
    )->RescriptRelay.Disposable.ignore
  }

  // better-auth answers {status: true} whether or not it sent anything (it
  // won't say that another account has the address), so success reads as
  // "check that inbox".
  let changeAccountEmail = () => {
    let address = newEmail->String.trim->String.toLowerCase
    let current = data.email->Option.map(String.toLowerCase)
    if address == "" {
      ()
    } else if current == Some(address) {
      setNotice(_ => Some(Failed(errorCopy("SAME_AS_PRIMARY"))))
    } else {
      setNotice(_ => None)
      setChangeBusy(_ => true)
      authClient.changeEmail({
        newEmail: address,
        callbackURL: localePath("/verify-email?purpose=change-email"),
      })
      ->Promise.thenResolve(res => {
        setChangeBusy(_ => false)
        switch res.error->Js.Null.toOption {
        | Some({status: 429}) => setNotice(_ => Some(Failed(errorCopy("RATE_LIMITED"))))
        | Some({status: 400}) => setNotice(_ => Some(Failed(errorCopy("INVALID_EMAIL"))))
        | Some(_) => failed()
        | None =>
          setChanging(_ => false)
          setNewEmail(_ => "")
          setNotice(_ => Some(ChangeSent(address)))
        }
      })
      ->Promise.catch(_ => {
        setChangeBusy(_ => false)
        failed()
        Promise.resolve()
      })
      ->ignore
    }
  }

  let row = (~address: string, ~pill: React.element, ~actions: React.element) =>
    <li key=address className="flex flex-wrap items-center justify-between gap-2 py-2.5">
      <div className="flex items-center gap-2 min-w-0">
        <span className="truncate text-sm text-gray-900 dark:text-gray-100"> {address->React.string} </span>
        pill
      </div>
      <div className="flex items-center gap-3"> actions </div>
    </li>

  <WaitForMessages>
    {() =>
      <div
        className="mt-8 border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
        <div className="px-4 py-5 sm:px-6">
          <h3
            className="text-sm font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
            {t`Receiving emails`}
          </h3>
        </div>
        <div className="px-4 pb-6 space-y-4">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            {t`Bookings you forward to chris@pkuru.com are added to your account when they come from one of these addresses. Add the other addresses you receive booking confirmations at.`}
          </p>
          {data.email->Option.isNone
            ? <p className="text-sm text-gray-600 dark:text-gray-400">
                {t`Your account has no email yet. The first address you confirm here becomes your account email.`}
              </p>
            : React.null}
          <ul className="divide-y divide-gray-100 dark:divide-gray-800">
            {switch data.email {
            | Some(email) =>
              row(
                ~address=email,
                ~pill={
                  <span
                    className={pillClass ++ " bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400"}>
                    {t`Account email`}
                  </span>
                },
                ~actions={
                  <button
                    type_="button"
                    onClick={_ => {
                      setNotice(_ => None)
                      setChanging(v => !v)
                    }}
                    className="text-sm font-medium text-gray-700 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100">
                    {t`Change`}
                  </button>
                },
              )
            | None => React.null
            }}
            {data.alternateEmails
            ->Array.map(e =>
              row(
                ~address=e.address,
                ~pill={
                  e.verified
                    ? <span
                        className={pillClass ++ " bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"}>
                        {t`Confirmed`}
                      </span>
                    : <span
                        className={pillClass ++ " bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400"}>
                        {t`Awaiting confirmation`}
                      </span>
                },
                ~actions={
                  <>
                    {e.verified
                      ? React.null
                      : <button
                          type_="button"
                          disabled={resending}
                          onClick={_ => resend(e.address)}
                          className="text-sm font-medium text-gray-700 hover:text-gray-900 dark:text-gray-300 dark:hover:text-gray-100 disabled:opacity-50">
                          {t`Resend`}
                        </button>}
                    <button
                      type_="button"
                      disabled={removing}
                      onClick={_ => setRemoving(_ => Some(e.address))}
                      className="text-sm font-medium text-red-600 hover:text-red-700 dark:text-red-400 disabled:opacity-50">
                      {t`Remove`}
                    </button>
                  </>
                },
              )
            )
            ->React.array}
          </ul>
          {changing
            ? <form
                className="space-y-2 rounded-lg bg-gray-50 dark:bg-[#222222] p-3"
                onSubmit={e => {
                  ReactEvent.Form.preventDefault(e)
                  changeAccountEmail()
                }}>
                <label
                  htmlFor="newAccountEmail"
                  className="block text-sm font-medium text-gray-900 dark:text-gray-100">
                  {t`New account email`}
                </label>
                <p className="text-xs text-gray-600 dark:text-gray-400">
                  {t`We'll email a link to the new address. Your current address stays on as a receiving email.`}
                </p>
                <div className="flex flex-col sm:flex-row gap-2">
                  <input
                    id="newAccountEmail"
                    type_="email"
                    value=newEmail
                    onChange={e => {
                      let v = ReactEvent.Form.target(e)["value"]
                      setNewEmail(_ => v)
                    }}
                    placeholder={ts`name@example.com`}
                    className="block w-full px-4 py-2.5 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#1a1a1a] text-gray-900 dark:text-gray-100"
                  />
                  <button
                    type_="submit"
                    disabled={changeBusy || newEmail->String.trim == ""}
                    className="inline-flex justify-center items-center px-4 py-2.5 rounded-lg text-sm font-bold bg-[#a3e635] text-gray-900 hover:bg-[#84cc16] focus:outline-none focus:ring-2 focus:ring-[#a3e635] transition-colors disabled:opacity-50 shrink-0">
                    {t`Send link`}
                  </button>
                  <button
                    type_="button"
                    onClick={_ => {
                      setChanging(_ => false)
                      setNewEmail(_ => "")
                    }}
                    className="inline-flex justify-center items-center px-4 py-2.5 rounded-lg text-sm font-semibold border border-gray-300 dark:border-gray-700 text-gray-800 dark:text-gray-200 hover:bg-gray-50 dark:hover:bg-[#2a2b30] transition-colors shrink-0">
                    {t`Cancel`}
                  </button>
                </div>
              </form>
            : React.null}
          {switch notice {
          | Some(Sent(address)) =>
            <p className="text-sm text-gray-700 dark:text-gray-300">
              {(ts`We sent a confirmation link to` ++ " " ++ address ++ ". ")->React.string}
              {t`Open it while signed in to pkuru to finish adding the address.`}
            </p>
          | Some(ChangeSent(address)) =>
            <p className="text-sm text-gray-700 dark:text-gray-300">
              {(ts`We sent a link to` ++ " " ++ address ++ ". ")->React.string}
              {t`Open it to make it your account email. Until then, nothing changes.`}
            </p>
          | Some(Failed(message)) =>
            <p className="text-sm text-red-600 dark:text-red-400"> {message->React.string} </p>
          | None => React.null
          }}
          <form
            className="flex flex-col sm:flex-row gap-2"
            onSubmit={e => {
              ReactEvent.Form.preventDefault(e)
              add()
            }}>
            <label htmlFor="receivingEmail" className="sr-only"> {t`Add a receiving email`} </label>
            <input
              id="receivingEmail"
              type_="email"
              value=draft
              onChange={e => {
                let v = ReactEvent.Form.target(e)["value"]
                setDraft(_ => v)
              }}
              placeholder={ts`name@example.com`}
              className="block w-full px-4 py-2.5 border border-gray-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#a3e635] focus:border-[#a3e635] transition-colors bg-white dark:bg-[#222222] text-gray-900 dark:text-gray-100"
            />
            <button
              type_="submit"
              disabled={adding || draft->String.trim == ""}
              className="inline-flex justify-center items-center px-4 py-2.5 rounded-lg text-sm font-bold bg-[#a3e635] text-gray-900 hover:bg-[#84cc16] focus:outline-none focus:ring-2 focus:ring-[#a3e635] transition-colors disabled:opacity-50 shrink-0">
              {t`Add`}
            </button>
          </form>
        </div>
        <ConfirmDialog
          isOpen={removing_->Option.isSome}
          setIsOpen={f =>
            if !f(removing_->Option.isSome) {
              setRemoving(_ => None)
            }}
          title={t`Remove this receiving email?`}
          description={t`Bookings forwarded from it will no longer be added to your account. You can add it again later.`}
          onConfirmed={_ => {
            removing_->Option.forEach(remove)
            setRemoving(_ => None)
          }}
        />
      </div>}
  </WaitForMessages>
}

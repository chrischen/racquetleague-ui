%%raw("import { t } from '@lingui/macro'")

let ts = Lingui.UtilString.t

/* The card reads the link and the SSO URL off the root query, and both
   mutations return the viewer so the Relay store flips this card by User id
   without waiting for a refetch. */
module CardFragment = %relay(`
  fragment DuprConnectCard_query on Query {
    duprSsoUrl
    viewer {
      profile {
        id
        dupr {
          duprId
          doubles
          singles
          doublesReliable
          singlesReliable
          doublesReliability
          syncedAt
        }
      }
    }
  }
`)

module ConnectMutation = %relay(`
  mutation DuprConnectCardConnectMutation($input: ConnectDuprInput!) {
    connectDupr(input: $input) {
      viewer {
        id
        dupr {
          duprId
          doubles
          singles
          doublesReliable
          singlesReliable
          syncedAt
        }
      }
      errors {
        message
      }
    }
  }
`)

module DisconnectMutation = %relay(`
  mutation DuprConnectCardDisconnectMutation {
    disconnectDupr {
      viewer {
        id
        dupr {
          duprId
          doubles
          singles
          doublesReliable
          singlesReliable
          syncedAt
        }
      }
      errors {
        message
      }
    }
  }
`)

/* Phrase the last sync as "3 days ago" rather than "4320 minutes ago":
   FormattedRelativeTime takes a delta plus a unit, so pick the unit by
   magnitude and let Intl do the wording in the reader's language. */
let relativeSince = (syncedAt: Util.Datetime.t): (float, ReactIntl.timeUnit) => {
  let elapsedMinutes =
    (Date.now() -. syncedAt->Util.Datetime.toDate->Date.getTime) /. 60_000.0
  let ago = Math.max(elapsedMinutes, 0.0)
  if ago < 60.0 {
    (-.Math.round(ago), #minute)
  } else if ago < 1440.0 {
    (-.Math.round(ago /. 60.0), #hour)
  } else {
    (-.Math.round(ago /. 1440.0), #day)
  }
}

/* Linked is not held in state: it is read from the store, so the card can
   never disagree with what the server last told us. */
type phase =
  | Idle
  | AwaitingLogin
  | Linking
  | Failed(string)

@react.component
let make = (~query, ~onChanged: unit => unit=() => ()) => {
  open Lingui.Util
  let data = CardFragment.use(query)
  let (commitConnect, _) = ConnectMutation.use()
  let (commitDisconnect, isDisconnecting) = DisconnectMutation.use()

  let (phase, setPhase) = React.useState(() => Idle)
  let (confirmOpen, setConfirmOpen) = React.useState(() => false)
  let (frameLoaded, setFrameLoaded) = React.useState(() => false)
  /* Something DUPR's page told us while the modal is open — that the account
     needs setup, that consent was declined. Shown under DUPR's panel rather
     than closing it, because the panel is where DUPR says what to do next. */
  let (notice, setNotice) = React.useState(() => None)
  /* DUPR posts its message more than once in some flows; the mutation must
     fire exactly once per login. */
  let consumed = React.useRef(false)

  let link = data.viewer->Option.flatMap(v => v.profile)->Option.flatMap(p => p.dupr)
  let ssoUrl = data.duprSsoUrl
  let ssoOrigin = React.useMemo1(() => ssoUrl->Option.flatMap(DuprSso.originOf), [ssoUrl])

  /* The server answers with a stable code so the wording lives here, in the
     language the reader is using, rather than coming back from the API. */
  let errorCopy = (code: string) =>
    switch code {
    | "DUPR_ALREADY_LINKED" => ts`That DUPR account is already linked to another player.`
    | "DUPR_TOKEN_INVALID" => ts`That DUPR sign-in has expired. Please try again.`
    | "DUPR_NOT_CONFIGURED" => ts`DUPR linking isn't available right now.`
    | _ => ts`Couldn't reach DUPR. Please try again in a moment.`
    }

  /* DUPR posts `{error: ...}` when the sign-in cannot go on. The two reasons
     it uses today get proper copy; anything else is shown as DUPR worded it,
     so a new reason is at least visible rather than swallowed. */
  let rejectedCopy = (reason: string) =>
    switch reason {
    | "DUPR account setup required" =>
      ts`DUPR needs you to finish setting up your account before it can be linked. Follow the steps in the DUPR panel, then sign in again.`
    | "consent_denied" =>
      ts`You declined to share your DUPR data, so nothing was linked. Sign in again and choose Authorize to link.`
    | other => ts`DUPR couldn't complete the sign-in.` ++ " (" ++ other ++ ")"
    }

  let closeModal = () => {
    setFrameLoaded(_ => false)
    setNotice(_ => None)
    setPhase(_ => Idle)
  }

  /* The origin check is the whole security boundary here: anything on the
     page can postMessage, so a message from elsewhere is dropped without
     comment. Registered only while the modal is open. */
  React.useEffect2(() => {
    switch (phase, ssoOrigin) {
    | (AwaitingLogin, Some(ssoOrigin)) =>
      consumed.current = false
      let handler = (event: DuprSso.messageEvent) =>
        switch DuprSso.parseMessage(
          ~ssoOrigin,
          ~origin=event->DuprSso.origin,
          ~data=event->DuprSso.data,
        ) {
        | Ignored => ()
        /* Not the login payload, but not a failure either: DUPR's page posts
           other traffic to its parent. Keep waiting; note it for debugging. */
        | Unrecognized(keys) =>
          Console.warn2("DUPR posted a message that is not a login; ignoring. Keys:", keys)
        | Rejected(reason) => setNotice(_ => Some(rejectedCopy(reason)))
        | Tokens({accessToken, refreshToken}) =>
          if !consumed.current {
            consumed.current = true
            setPhase(_ => Linking)
            commitConnect(
              ~variables={input: {accessToken, refreshToken}},
              ~onCompleted=(response, _) =>
                switch response.connectDupr.errors
                ->Option.flatMap(errs => errs->Array.get(0))
                ->Option.map(e => e.message) {
                | Some(code) => setPhase(_ => Failed(errorCopy(code)))
                | None =>
                  closeModal()
                  onChanged()
                },
              ~onError=_ =>
                setPhase(_ => Failed(ts`Couldn't reach DUPR. Please try again in a moment.`)),
            )->RescriptRelay.Disposable.ignore
          }
        }
      DuprSso.addMessageListener("message", handler)
      Some(() => DuprSso.removeMessageListener("message", handler))
    | _ => None
    }
  }, (phase, ssoOrigin))

  let disconnect = () =>
    commitDisconnect(
      ~variables=(),
      ~onCompleted=(response, _) =>
        switch response.disconnectDupr.errors
        ->Option.flatMap(errs => errs->Array.get(0))
        ->Option.map(e => e.message) {
        | Some(code) => setPhase(_ => Failed(errorCopy(code)))
        | None => onChanged()
        },
      ~onError=_ => setPhase(_ => Failed(ts`Couldn't reach DUPR. Please try again in a moment.`)),
    )->RescriptRelay.Disposable.ignore

  let statusPill = {
    let (label, tone) = switch (link, phase) {
    | (Some(_), _) => (ts`Linked`, "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400")
    | (None, Linking) => (ts`Linking`, "bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400")
    | (None, _) => (ts`Not linked`, "bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400")
    }
    <span
      className={"mt-0.5 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium shrink-0 " ++
      tone}>
      {label->React.string}
    </span>
  }

  <WaitForMessages>
    {() =>
      <div
        className="mt-8 border border-gray-200 dark:border-gray-800 rounded-lg overflow-hidden bg-white dark:bg-[#1a1a1a] transition-colors">
        <div className="px-4 py-5 sm:px-6">
          <h3
            className="text-sm font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
            {t`DUPR`}
          </h3>
        </div>
        <div className="px-4 pb-6 space-y-4">
          <div className="flex items-start gap-3">
            {statusPill}
            <div className="space-y-1">
              {switch link {
              | Some(link) =>
                <>
                  <div className="text-gray-900 dark:text-gray-100">
                    <DuprRatingBadge
                      doubles={link.doubles}
                      singles=?link.singles
                      doublesReliable={CombinedRating.duprEstablished(
                        ~reliability=link.doublesReliability,
                        ~reliable=link.doublesReliable,
                      )}
                      singlesReliable={link.singlesReliable}
                    />
                  </div>
                  <p className="text-xs text-gray-500 dark:text-gray-400">
                    {(ts`DUPR ID` ++ ": ")->React.string}
                    <span className="font-mono"> {link.duprId->React.string} </span>
                    {switch link.syncedAt {
                    | Some(syncedAt) =>
                      let (value, unit) = relativeSince(syncedAt)
                      <>
                        {React.string(" · ")}
                        {(ts`Last synced`)->React.string}
                        {React.string(" ")}
                        <ReactIntl.FormattedRelativeTime value unit />
                      </>
                    | None => React.null
                    }}
                  </p>
                </>
              | None =>
                <p className="text-sm text-gray-700 dark:text-gray-300">
                  {t`Link your DUPR account to use your verified DUPR rating here. While it's linked, it replaces your self-rating.`}
                </p>
              }}
            </div>
          </div>
          {switch phase {
          | Failed(message) =>
            <p className="text-sm text-red-600 dark:text-red-400"> {message->React.string} </p>
          | _ => React.null
          }}
          {switch (link, ssoUrl) {
          | (Some(_), _) =>
            <div>
              <button
                type_="button"
                disabled={isDisconnecting}
                onClick={_ => setConfirmOpen(_ => true)}
                className="text-sm font-medium text-red-600 hover:text-red-700 dark:text-red-400 disabled:opacity-50">
                {t`Disconnect DUPR`}
              </button>
            </div>
          | (None, None) =>
            /* No client key configured on this deployment; offering a button
               that cannot work would be worse than saying so. */
            <p className="text-sm text-gray-500 dark:text-gray-400">
              {t`DUPR linking isn't available right now.`}
            </p>
          | (None, Some(_)) =>
            <div className="space-y-3">
              <button
                type_="button"
                onClick={_ => {
                  setPhase(_ => AwaitingLogin)
                  setFrameLoaded(_ => false)
                }}
                className="w-full sm:w-auto bg-[#a3e635] text-gray-900 py-2.5 px-5 rounded-lg font-bold hover:bg-[#84cc16] focus:outline-none focus:ring-2 focus:ring-[#a3e635] transition-colors">
                {t`Log in with DUPR`}
              </button>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                {t`Don't have a DUPR account?`}
                {React.string(" ")}
                <a
                  href="https://mydupr.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="underline hover:text-gray-700 dark:hover:text-gray-200">
                  {t`Create one at mydupr.com or in the DUPR app`}
                </a>
              </p>
            </div>
          }}
        </div>
        <ConfirmDialog
          isOpen=confirmOpen
          setIsOpen=setConfirmOpen
          title={t`Disconnect DUPR?`}
          description={t`Your DUPR rating will stop being used here and your self-rating picker comes back.`}
          onConfirmed=disconnect
        />
        {switch (phase, ssoUrl) {
        | (AwaitingLogin, Some(url))
        | (Linking, Some(url)) =>
          <Dialog.Dialog
            open_=true
            onClose={_ =>
              switch phase {
              /* Don't let a stray backdrop click abandon an in-flight link. */
              | Linking => ()
              | _ => closeModal()
              }}
            size=#"2xl">
            <Dialog.DialogTitle> {t`Log in with DUPR`} </Dialog.DialogTitle>
            <Dialog.DialogDescription>
              {t`Sign in to DUPR to link your account. We store your DUPR ID and ratings — never your DUPR password.`}
            </Dialog.DialogDescription>
            <Dialog.DialogBody>
              <div className="relative h-[70vh] min-h-[480px] w-full">
                {frameLoaded
                  ? React.null
                  : <div
                      className="absolute inset-0 flex items-center justify-center text-sm text-gray-500 dark:text-gray-400">
                      {t`Loading DUPR…`}
                    </div>}
                {/* DUPR's SSO page asks for the payment permission, and
                    `allow` is not in ReScript's DOM prop record, so it is
                    added to the rendered element rather than the JSX. */
                React.cloneElement(
                  <iframe
                    src=url
                    title={ts`DUPR login`}
                    onLoad={_ => setFrameLoaded(_ => true)}
                    className="h-full w-full rounded-lg border-0"
                  />,
                  {"allow": "payment"},
                )}
                {switch phase {
                | Linking =>
                  <div
                    className="absolute inset-0 flex items-center justify-center bg-white/80 dark:bg-black/60 text-sm font-medium">
                    {t`Linking your account…`}
                  </div>
                | _ => React.null
                }}
              </div>
              {switch notice {
              | Some(message) =>
                <p className="mt-3 text-sm text-red-600 dark:text-red-400" role="alert">
                  {message->React.string}
                </p>
              | None => React.null
              }}
            </Dialog.DialogBody>
            <Dialog.DialogActions>
              <Button.Button plain=true onClick={_ => closeModal()}>
                {t`Cancel`}
              </Button.Button>
            </Dialog.DialogActions>
          </Dialog.Dialog>
        | _ => React.null
        }}
      </div>}
  </WaitForMessages>
}

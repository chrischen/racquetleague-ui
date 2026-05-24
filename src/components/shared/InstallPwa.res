%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// ---------------------------------------------------------------------------
// Platform detection (all SSR-safe — check typeof window at runtime)
// ---------------------------------------------------------------------------

type mediaQueryList = {matches: bool}
@val @scope("window") external matchMedia: string => mediaQueryList = "matchMedia"
@val @scope("navigator") external navigatorStandalone: Js.Nullable.t<bool> = "standalone"
@val @scope("navigator") external userAgent: string = "userAgent"

/** True when running in PWA / standalone display mode. */
let isStandalone = (): bool =>
  matchMedia("(display-mode: standalone)").matches ||
  navigatorStandalone->Js.Nullable.toOption->Option.getOr(false)

/**
 * True when running in iOS Safari (not in a PWA, not in an in-app browser).
 * Web Push requires the PWA to be installed on iOS; this flag is used to
 * surface "Add to Home Screen" instructions.
 */
let isIosSafari = (): bool => {
  let ua = userAgent
  let isIos = Js.Re.test_(%re("/iphone|ipad|ipod/i"), ua)
  let isSafariOnly =
    Js.Re.test_(%re("/safari/i"), ua) &&
    !Js.Re.test_(%re("/chrome|crios|fxios|opios|mercury|fbav|instagram|line|twitter/i"), ua)
  isIos && isSafariOnly
}

// ---------------------------------------------------------------------------
// localStorage keys
// ---------------------------------------------------------------------------

let nudgeDismissalKey = "pwa_nudge_notifications_dismissed"

@val @scope("localStorage") external lsGetItem: string => Js.Nullable.t<string> = "getItem"
@val @scope("localStorage") external lsSetItem: (string, string) => unit = "setItem"
@val @scope("Date") external dateNow: unit => float = "now"

let isNudgeDismissed = (): bool => {
  try {
    switch lsGetItem(nudgeDismissalKey)->Js.Nullable.toOption {
    | None => false
    | Some(v) =>
      switch Float.fromString(v) {
      | None => false
      // Re-show after 14 days in case the user changes their mind
      | Some(ts) => dateNow() -. ts < 14.0 *. 24.0 *. 60.0 *. 60.0 *. 1000.0
      }
    }
  } catch {
  | _ => false
  }
}

let saveNudgeDismissal = (): unit => {
  try {
    lsSetItem(nudgeDismissalKey, dateNow()->Float.toString)
  } catch {
  | _ => ()
  }
}

// ---------------------------------------------------------------------------
// localStorage dismissal (Banner only; 7-day re-show)
// ---------------------------------------------------------------------------

let bannerDismissalKey = "pwa_install_banner_dismissed"

let isBannerDismissed = (): bool => {
  try {
    switch lsGetItem(bannerDismissalKey)->Js.Nullable.toOption {
    | None => false
    | Some(v) =>
      switch Float.fromString(v) {
      | None => false
      | Some(ts) => dateNow() -. ts < 7.0 *. 24.0 *. 60.0 *. 60.0 *. 1000.0
      }
    }
  } catch {
  | _ => false
  }
}

let saveBannerDismissal = (): unit => {
  try {
    lsSetItem(bannerDismissalKey, dateNow()->Float.toString)
  } catch {
  | _ => ()
  }
}

// ---------------------------------------------------------------------------
// beforeinstallprompt / appinstalled listeners
// ---------------------------------------------------------------------------

type beforeInstallPromptEvent
@send external preventDefault: beforeInstallPromptEvent => unit = "preventDefault"
@send external promptInstall: beforeInstallPromptEvent => unit = "prompt"
@val @scope("window")
external windowAddEventListener: (string, 'handler) => unit = "addEventListener"
@val @scope("window")
external windowRemoveEventListener: (string, 'handler) => unit = "removeEventListener"

/**
 * Attaches `beforeinstallprompt` and `appinstalled` listeners.
 * Returns a cleanup function.
 */
let setupInstallListeners = (
  ~onPromptReady: beforeInstallPromptEvent => unit,
  ~onInstalled: unit => unit,
): (unit => unit) => {
  try {
    let onBefore = (e: beforeInstallPromptEvent) => {
      e->preventDefault
      onPromptReady(e)
    }
    let onInstall = (_: 'a) => onInstalled()
    windowAddEventListener("beforeinstallprompt", onBefore)
    windowAddEventListener("appinstalled", onInstall)
    () => {
      windowRemoveEventListener("beforeinstallprompt", onBefore)
      windowRemoveEventListener("appinstalled", onInstall)
    }
  } catch {
  | _ => () => ()
  }
}

/** Reads the `beforeinstallprompt` event captured before React mounted (or null). */
@val
@scope("window")
external getStoredPwaPrompt: Js.Nullable.t<beforeInstallPromptEvent> = "__pwaInstallPrompt"

/** Calls `.prompt()` on a captured `BeforeInstallPromptEvent`. */
let callDeferredPrompt = (e: Js.Nullable.t<beforeInstallPromptEvent>) =>
  switch e->Js.Nullable.toOption {
  | Some(event) => event->promptInstall
  | None => ()
  }

// Service worker / push notification browser API bindings
type pushManager
type serviceWorkerRegistration = {pushManager: pushManager}

@val @scope("navigator") external swFromNavigator: Js.Nullable.t<'a> = "serviceWorker"
@val @scope("window") external pushManagerFromWindow: Js.Nullable.t<'a> = "PushManager"

@val @scope(("navigator", "serviceWorker"))
external swGetRegistration: unit => promise<Js.Nullable.t<serviceWorkerRegistration>> =
  "getRegistration"

@send external pushMgrGetSubscription: pushManager => promise<Js.Nullable.t<'a>> = "getSubscription"

let isPushSupportedBrowser = (): bool => {
  try {
    swFromNavigator->Js.Nullable.toOption->Option.isSome &&
      pushManagerFromWindow->Js.Nullable.toOption->Option.isSome
  } catch {
  | _ => false
  }
}

/**
 * Resolves with the current PushSubscription or null.
 * Uses getRegistration() so it returns immediately when no SW is active.
 */
let getPushSubscription = async () => {
  try {
    let reg = await swGetRegistration()
    switch reg->Js.Nullable.toOption {
    | None => Js.Nullable.null
    | Some(r) => await r.pushManager->pushMgrGetSubscription
    }
  } catch {
  | _ => Js.Nullable.null
  }
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type installState =
  | Standalone // already installed as PWA
  | IosSafari // iOS Safari, not standalone — must Add to Home Screen first
  | Installable // beforeinstallprompt captured — native install available
  | NotSupported // desktop/unsupported browser — no special handling

type hookResult = {
  state: installState,
  dismissed: bool,
  dismiss: unit => unit,
  triggerInstall: unit => unit,
}

// ---------------------------------------------------------------------------
// usePwaInstall hook
// ---------------------------------------------------------------------------

let usePwaInstall = (): hookResult => {
  let (state, setState) = React.useState(() => NotSupported)
  let (dismissed, setDismissed) = React.useState(() => false)
  let deferredPromptRef: React.ref<Js.Nullable.t<'a>> = React.useRef(Js.Nullable.null)

  // Initial platform detection — runs in browser only (useEffect is client-only)
  React.useEffect0(() => {
    let standalone = isStandalone()
    let ios = isIosSafari()
    let stored = getStoredPwaPrompt
    let dismissed_ = isBannerDismissed()
    Js.Console.log4("[PWA] detect: standalone=", standalone, "iosSafari=", ios)
    Js.Console.log2("[PWA] detect: bannerDismissed=", dismissed_)
    Js.Console.log2("[PWA] detect: storedPrompt=", stored)
    if standalone {
      setState(_ => Standalone)
    } else if ios {
      setState(_ => IosSafari)
    } else {
      // beforeinstallprompt may have fired before React mounted; pick it up here.
      switch stored->Js.Nullable.toOption {
      | Some(event) =>
        Js.Console.log("[PWA] using stored beforeinstallprompt → Installable")
        deferredPromptRef.current = Js.Nullable.return(event)
        setState(_ => Installable)
      | None => Js.Console.log("[PWA] no stored prompt yet, waiting for listener")
      }
    }
    setDismissed(_ => dismissed_)
    None
  })

  // beforeinstallprompt / appinstalled listeners
  React.useEffect0(() => {
    let cleanup = setupInstallListeners(
      ~onPromptReady=event => {
        deferredPromptRef.current = Js.Nullable.return(event)
        setState(_ => Installable)
      },
      ~onInstalled=() => {
        deferredPromptRef.current = Js.Nullable.null
        setState(_ => Standalone)
      },
    )
    Some(cleanup)
  })

  let dismiss = () => {
    saveBannerDismissal()
    setDismissed(_ => true)
  }

  let triggerInstall = () => {
    callDeferredPrompt(deferredPromptRef.current)
    deferredPromptRef.current = Js.Nullable.null
    setState(_ => Standalone)
  }

  {state, dismissed, dismiss, triggerInstall}
}

// ---------------------------------------------------------------------------
// Inline iOS instructions panel (used inside PushNotifications on Settings)
// ---------------------------------------------------------------------------

/** The iOS Share icon (upload/share glyph, resembles Safari's share button). */
let shareIconSvg =
  <svg
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0 0 24 24"
    fill="none"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
    className="w-4 h-4 inline-block align-[-3px] mx-0.5"
    ariaHidden=true>
    <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" />
    <polyline points="16 6 12 2 8 6" />
    <line x1="12" y1="2" x2="12" y2="15" />
  </svg>

/**
 * Standalone panel shown on the Settings page when the app is running in iOS
 * Safari (not yet installed as a PWA). Exported so PushNotifications can
 * render it inside its own component tree without a second hook call.
 */
module IosSafariPanel = {
  @react.component
  let make = () =>
    <div
      className="rounded-lg border border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-950/40 px-4 py-4 text-sm">
      <p className="font-semibold text-amber-900 dark:text-amber-200 mb-2">
        {t`Add to Home Screen to enable notifications`}
      </p>
      <ol className="space-y-1 text-amber-800 dark:text-amber-300 list-none">
        <li>
          {"1. "->React.string}
          {t`Tap the Share button`}
          {shareIconSvg}
          {t`in Safari's toolbar`}
        </li>
        <li>
          {"2. "->React.string}
          {t`Scroll down and tap `}
          <strong> {t`"Add to Home Screen"`} </strong>
        </li>
        <li>
          {"3. "->React.string}
          {t`Open the app from your Home Screen and enable notifications`}
        </li>
      </ol>
    </div>
}

// ---------------------------------------------------------------------------
// Banner component (sitewide — used in PkuruLayout, LeagueLayout)
// ---------------------------------------------------------------------------

@react.component
let make = () => {
  let {state, dismissed, dismiss, triggerInstall} = usePwaInstall()
  let (showIosInstructions, setShowIosInstructions) = React.useState(() => false)

  // Standalone nudge state: check async whether a push subscription already exists
  let (nudgeDismissed, setNudgeDismissed) = React.useState(() => true) // start hidden
  let (hasSubscription, setHasSubscription) = React.useState(() => true) // assume subscribed until checked

  React.useEffect0(() => {
    if isStandalone() && isPushSupportedBrowser() && !isNudgeDismissed() {
      let _ =
        getPushSubscription()
        ->Promise.then(sub => {
          let subscribed = sub->Js.Nullable.toOption->Option.isSome
          setHasSubscription(_ => subscribed)
          setNudgeDismissed(_ => subscribed) // hide nudge if already subscribed
          Promise.resolve()
        })
        ->Promise.catch(_ => Promise.resolve())
    }
    None
  })

  let dismissNudge = () => {
    saveNudgeDismissal()
    setNudgeDismissed(_ => true)
  }

  if dismissed {
    React.null
  } else {
    switch state {
    | Standalone =>
      // Show a nudge when the app is running as a PWA but push isn't enabled yet
      if nudgeDismissed || hasSubscription {
        React.null
      } else {
        <div
          className="border-b border-green-200 dark:border-green-900 bg-green-50 dark:bg-green-950/40 px-4 py-2 text-sm">
          <div className="flex items-center justify-between gap-3">
            <div className="flex items-center gap-2 min-w-0">
              <span className="text-green-900 dark:text-green-200 font-medium shrink-0">
                {t`Stay in the loop`}
              </span>
              <span className="text-green-700 dark:text-green-400 hidden sm:inline truncate">
                {t`— enable push notifications for event reminders`}
              </span>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <a
                href="/settings/profile"
                className="rounded-md bg-green-600 px-3 py-1 text-xs font-semibold text-white shadow-sm hover:bg-green-500 focus:outline-none focus-visible:ring-2 focus-visible:ring-green-500 focus-visible:ring-offset-1">
                {t`Enable now`}
              </a>
              <button
                type_="button"
                onClick={_ => dismissNudge()}
                className="text-green-600 dark:text-green-400 hover:text-green-900 dark:hover:text-green-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-green-500 rounded p-0.5"
                ariaLabel="Dismiss">
                {"×"->React.string}
              </button>
            </div>
          </div>
        </div>
      }

    | NotSupported => React.null

    | IosSafari =>
      <div
        className="border-b border-amber-200 dark:border-amber-800 bg-amber-50 dark:bg-amber-950/40 px-4 py-2 text-sm">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-2 min-w-0">
            <span className="text-amber-900 dark:text-amber-200 font-medium shrink-0">
              {t`Install Racquet League`}
            </span>
            <span className="text-amber-700 dark:text-amber-400 hidden sm:inline truncate">
              {t`— add to your Home Screen for push notifications`}
            </span>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button
              type_="button"
              onClick={_ => setShowIosInstructions(v => !v)}
              className="text-amber-700 dark:text-amber-300 underline underline-offset-2 font-medium focus:outline-none focus-visible:ring-2 focus-visible:ring-amber-500 rounded">
              {showIosInstructions ? t`Hide` : t`How to install`}
            </button>
            <button
              type_="button"
              onClick={_ => dismiss()}
              className="text-amber-600 dark:text-amber-400 hover:text-amber-900 dark:hover:text-amber-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-amber-500 rounded p-0.5"
              ariaLabel="Dismiss">
              {"×"->React.string}
            </button>
          </div>
        </div>
        {showIosInstructions
          ? <div className="mt-3 pb-1">
              <ol className="space-y-1 text-amber-800 dark:text-amber-300 list-none">
                <li>
                  {"1. "->React.string}
                  {t`Tap the Share button`}
                  {shareIconSvg}
                  {t`in Safari's toolbar`}
                </li>
                <li>
                  {"2. "->React.string}
                  {t`Scroll down and tap `}
                  <strong> {t`"Add to Home Screen"`} </strong>
                </li>
              </ol>
            </div>
          : React.null}
      </div>

    | Installable =>
      <div
        className="border-b border-blue-200 dark:border-blue-900 bg-blue-50 dark:bg-blue-950/40 px-4 py-2 text-sm">
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-2 min-w-0">
            <span className="text-blue-900 dark:text-blue-200 font-medium shrink-0">
              {t`Install Racquet League`}
            </span>
            <span className="text-blue-700 dark:text-blue-400 hidden sm:inline truncate">
              {t`— for a faster, app-like experience`}
            </span>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <button
              type_="button"
              onClick={_ => triggerInstall()}
              className="rounded-md bg-blue-600 px-3 py-1 text-xs font-semibold text-white shadow-sm hover:bg-blue-500 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 focus-visible:ring-offset-1">
              {t`Install`}
            </button>
            <button
              type_="button"
              onClick={_ => dismiss()}
              className="text-blue-600 dark:text-blue-400 hover:text-blue-900 dark:hover:text-blue-100 focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500 rounded p-0.5"
              ariaLabel="Dismiss">
              {"×"->React.string}
            </button>
          </div>
        </div>
      </div>
    }
  }
}

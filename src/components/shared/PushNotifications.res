%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// ---------------------------------------------------------------------------
// GraphQL
// ---------------------------------------------------------------------------

module VapidKeyQuery = %relay(`
  query PushNotificationsVapidKeyQuery {
    vapidPublicKey
  }
`)

module RegisterMutation = %relay(`
  mutation PushNotificationsRegisterMutation($input: RegisterPushSubscriptionInput!) {
    registerPushSubscription(input: $input) {
      success
      errors { message }
    }
  }
`)

module UnregisterMutation = %relay(`
  mutation PushNotificationsUnregisterMutation($endpoint: String!) {
    unregisterPushSubscription(endpoint: $endpoint) {
      success
      errors { message }
    }
  }
`)

// ---------------------------------------------------------------------------
// Browser Push API — types
// ---------------------------------------------------------------------------

type serviceWorkerRegistration
type pushSubscription
type pushManager
type uint8Array = Js.TypedArray2.Uint8Array.t

type subscriptionKeys = {p256dh: string, auth: string}
type subscriptionDetails = {
  endpoint: string,
  expirationTime: Js.Nullable.t<float>,
  keys: subscriptionKeys,
}
type subscriptionJSON = {keys: Js.Nullable.t<subscriptionKeys>}
type pushSubscribeOptions = {userVisibleOnly: bool, applicationServerKey: uint8Array}

// ---------------------------------------------------------------------------
// Browser Push API — externals
// ---------------------------------------------------------------------------

// SSR-safe presence checks via globalThis (property access never throws)
@val @scope("globalThis") external _window: Js.Undefined.t<'a> = "window"
@val @scope("globalThis") external _pushManagerClass: Js.Undefined.t<'a> = "PushManager"
@val @scope("globalThis") external _notificationClass: Js.Undefined.t<'a> = "Notification"
@val @scope("navigator") external _navigatorSW: Js.Undefined.t<'a> = "serviceWorker"

// Notification API
@val @scope("Notification") external notificationPermission: string = "permission"
@val @scope("Notification")
external requestPermission: unit => promise<string> = "requestPermission"

// navigator.serviceWorker
@val @scope(("navigator", "serviceWorker"))
external registerSW: string => promise<serviceWorkerRegistration> = "register"
@val @scope(("navigator", "serviceWorker"))
external swReady: promise<serviceWorkerRegistration> = "ready"
@val @scope(("navigator", "serviceWorker"))
external getRegistrationJs: unit => promise<Js.Nullable.t<serviceWorkerRegistration>> =
  "getRegistration"

// ServiceWorkerRegistration
@get external regActive: serviceWorkerRegistration => Js.Nullable.t<'a> = "active"
@get external regPushManager: serviceWorkerRegistration => pushManager = "pushManager"

// PushManager
@send
external pmGetSubscription: pushManager => promise<Js.Nullable.t<pushSubscription>> =
  "getSubscription"
@send
external pmSubscribe: (pushManager, pushSubscribeOptions) => promise<pushSubscription> = "subscribe"

// PushSubscription
@get external subEndpoint: pushSubscription => string = "endpoint"
@get external subExpirationTime: pushSubscription => Js.Nullable.t<float> = "expirationTime"
@send external subToJSON: pushSubscription => subscriptionJSON = "toJSON"
@send external subUnsubscribe: pushSubscription => promise<bool> = "unsubscribe"

// VAPID / base64 helpers
@val external atob: string => string = "atob"
@send external charCodeAt: (string, int) => int = "charCodeAt"
@send external replaceAll: (string, string, string) => string = "replaceAll"
@send external strRepeat: (string, int) => string = "repeat"
@new external makeUint8Array: int => uint8Array = "Uint8Array"

// Promise.race
@val @scope("Promise") external promiseRace: array<promise<'a>> => promise<'a> = "race"

// setTimeout
@val external setTimeout: (unit => unit, int) => int = "setTimeout"

// ---------------------------------------------------------------------------
// Browser Push API — functions
// ---------------------------------------------------------------------------

exception SwTimeout

let isPushSupported = () =>
  _window->Js.Undefined.toOption->Option.isSome &&
  _navigatorSW->Js.Undefined.toOption->Option.isSome &&
  _pushManagerClass->Js.Undefined.toOption->Option.isSome

let getNotificationPermission = () =>
  switch _notificationClass->Js.Undefined.toOption {
  | None => "denied"
  | Some(_) => notificationPermission
  }

let requestNotificationPermission = () => requestPermission()

let registerServiceWorker = () =>
  registerSW("/sw.js")->Promise.then(reg =>
    if reg->regActive->Js.Nullable.isNullable {
      let timeoutPromise: promise<serviceWorkerRegistration> = Promise.make((_, reject) => {
        let _ = setTimeout(() => reject(SwTimeout), 10000)
      })
      promiseRace([swReady, timeoutPromise])
    } else {
      Promise.resolve(reg)
    }
  )

let getSubscription = () =>
  getRegistrationJs()->Promise.then(regNullable =>
    switch regNullable->Js.Nullable.toOption {
    | None => Promise.resolve(Js.Nullable.null)
    | Some(reg) => reg->regPushManager->pmGetSubscription
    }
  )

let subscribeToPush = (vapidKey: string, reg: serviceWorkerRegistration) => {
  let base64 = vapidKey->replaceAll("-", "+")->replaceAll("_", "/")
  let padding = "="->strRepeat(mod(4 - mod(base64->String.length, 4), 4))
  let padded = base64 ++ padding
  let rawStr = atob(padded)
  let len = rawStr->String.length
  let uint8 = makeUint8Array(len)
  for i in 0 to len - 1 {
    Js.TypedArray2.Uint8Array.unsafe_set(uint8, i, rawStr->charCodeAt(i))
  }
  reg->regPushManager->pmSubscribe({userVisibleOnly: true, applicationServerKey: uint8})
}

let getSubscriptionDetails = (sub: pushSubscription): subscriptionDetails => {
  let json = sub->subToJSON
  {
    endpoint: sub->subEndpoint,
    expirationTime: sub->subExpirationTime,
    keys: json.keys->Js.Nullable.toOption->Option.getOr({p256dh: "", auth: ""}),
  }
}

let unsubscribeFromPush = (sub: pushSubscription) => sub->subUnsubscribe

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

type subscriptionState =
  | Unknown
  | Unsupported
  | Subscribed
  | Unsubscribed
  | Denied

/**
 * Inner component: loads the VAPID key via Relay (suspends while fetching),
 * then renders Enable / Disable controls.
 */
module Inner = {
  @react.component
  let make = () => {
    let {vapidPublicKey} = VapidKeyQuery.use(~variables=())
    let (commitRegister, _registerInFlight) = RegisterMutation.use()
    let (commitUnregister, _unregisterInFlight) = UnregisterMutation.use()

    let (state, setState) = React.useState(() => Unknown)
    let (busy, setBusy) = React.useState(() => false)
    let (subscribeError, setSubscribeError) = React.useState(() => None)
    // Stores the active ServiceWorkerRegistration pre-fetched on mount.
    // Having it ready means subscribe() can be called synchronously on click
    // (0 async hops from the user gesture), which is required on iOS.
    let (swReg, setSwReg) = React.useState(() => None)

    // Detect current subscription state on mount
    React.useEffect0(() => {
      let supported = isPushSupported()
      let permission = getNotificationPermission()
      if !supported {
        setState(_ => Unsupported)
      } else if permission == "denied" {
        setState(_ => Denied)
      } else {
        // Pre-register the SW so subscribe() fires synchronously on click.
        // Each async hop between the user gesture and subscribe() risks iOS
        // discarding the gesture context and throwing NotAllowedError.
        let _ =
          registerServiceWorker()
          ->Promise.then(reg => {
            setSwReg(_ => Some(reg))
            Promise.resolve()
          })
          ->Promise.catch(err => {
            Js.Console.error2("[PushNotifications] SW pre-register error:", err)
            Promise.resolve()
          })
        let _ =
          getSubscription()
          ->Promise.then(sub => {
            let isSubscribed = sub->Js.Nullable.toOption->Option.isSome
            setState(_ => isSubscribed ? Subscribed : Unsubscribed)
            Promise.resolve()
          })
          ->Promise.catch(err => {
            Js.Console.error2("[PushNotifications] getSubscription error:", err)
            setState(_ => Unsupported)
            Promise.resolve()
          })
      }
      None
    })

    let handleSubscribe = () => {
      switch vapidPublicKey {
      | None =>
        Js.Console.error(
          "[PushNotifications] vapidPublicKey is null — VAPID not configured on server",
        )
      | Some(key) =>
        let currentPermission = getNotificationPermission()
        if currentPermission == "denied" {
          setState(_ => Denied)
        } else {
          setBusy(_ => true)
          setSubscribeError(_ => None)
          let doSubscribe = reg => {
            subscribeToPush(key, reg)
            ->Promise.then(sub => {
              let {endpoint, expirationTime, keys: {p256dh, auth}} = getSubscriptionDetails(sub)
              Promise.make((resolve, _reject) => {
                commitRegister(
                  ~variables={
                    input: {
                      endpoint,
                      p256dh,
                      auth,
                      expirationTime: ?expirationTime->Js.Nullable.toOption,
                    },
                  },
                  ~onCompleted=(_data, _errors) => {
                    setState(_ => Subscribed)
                    setBusy(_ => false)
                    resolve()
                  },
                  ~onError=err => {
                    Js.Console.error2("[PushNotifications] register mutation error:", err)
                    setBusy(_ => false)
                    resolve()
                  },
                )->RescriptRelay.Disposable.ignore
              })
            })
            ->Promise.catch(err => {
              let name = err->Js.Exn.asJsExn->Option.flatMap(e => Js.Exn.name(e))->Option.getOr("")
              Js.Console.error2("[PushNotifications] subscribe error:", err)
              if name == "NotAllowedError" {
                setSubscribeError(_ => Some(
                  t`Push notifications are blocked. Check your browser or device notification settings for this site, then try again.`,
                ))
              }
              setBusy(_ => false)
              Promise.resolve()
            })
          }

          // Request permission (if needed) then subscribe in a single chain.
          // swReg was pre-fetched on mount so the SW registration step is a
          // no-op when present — minimizing async hops from the user gesture.
          let _ =
            requestNotificationPermission()
            ->Promise.then(permission => {
              switch permission {
              | "granted" =>
                switch swReg {
                | Some(reg) => doSubscribe(reg)
                | None => registerServiceWorker()->Promise.then(reg => doSubscribe(reg))
                }
              | "denied" =>
                setState(_ => Denied)
                setBusy(_ => false)
                Promise.resolve()
              | _ =>
                setBusy(_ => false)
                Promise.resolve()
              }
            })
            ->Promise.catch(err => {
              Js.Console.error2("[PushNotifications] permission request error:", err)
              setBusy(_ => false)
              Promise.resolve()
            })
        }
      }
    }

    let handleUnsubscribe = () => {
      setBusy(_ => true)
      let _ =
        getSubscription()
        ->Promise.then(sub => {
          switch sub->Js.Nullable.toOption {
          | None =>
            setState(_ => Unsubscribed)
            setBusy(_ => false)
            Promise.resolve()
          | Some(sub) =>
            let {endpoint} = getSubscriptionDetails(sub)
            unsubscribeFromPush(sub)->Promise.then(_ => {
              Promise.make(
                (resolve, _reject) => {
                  commitUnregister(
                    ~variables={endpoint: endpoint},
                    ~onCompleted=(_, _) => {
                      setState(_ => Unsubscribed)
                      setBusy(_ => false)
                      resolve()
                    },
                    ~onError=err => {
                      Js.Console.error2("[PushNotifications] unregister mutation error:", err)
                      setBusy(_ => false)
                      resolve()
                    },
                  )->RescriptRelay.Disposable.ignore
                },
              )
            })
          }
        })
        ->Promise.catch(err => {
          Js.Console.error2("[PushNotifications] unsubscribe error:", err)
          setBusy(_ => false)
          Promise.resolve()
        })
    }

    let btnBase = "inline-flex items-center gap-x-1.5 rounded-md px-3 py-2 text-sm font-semibold shadow-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"

    switch state {
    | Unsupported => React.null
    | Denied =>
      // Notification permission is granted but push subscription is blocked.
      // This happens when the user has denied push at the browser/OS level
      // separately from the notification permission (common on iOS and Chrome).
      <p className="text-sm text-gray-500">
        {t`Notifications are blocked. To enable them, go to your device or browser settings and allow notifications for this site.`}
      </p>
    | Unknown => <span className="text-sm text-gray-500"> {t`Loading...`} </span>
    | Unsubscribed =>
      <div className="flex flex-col gap-2">
        <button
          type_="button"
          disabled=busy
          onClick={_ => handleSubscribe()}
          className={Util.cx([
            btnBase,
            "bg-indigo-600 text-white hover:bg-indigo-500 focus-visible:outline-indigo-600",
          ])}>
          {t`Enable notifications`}
        </button>
        {switch subscribeError {
        | None => React.null
        | Some(msg) => <p className="text-sm text-red-600"> {msg} </p>
        }}
      </div>
    | Subscribed =>
      <button
        type_="button"
        disabled=busy
        onClick={_ => handleUnsubscribe()}
        className={Util.cx([
          btnBase,
          "bg-white text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50",
        ])}>
        {t`Disable notifications`}
      </button>
    }
  }
}

/**
 * Public component.  On iOS Safari (non-standalone), push is unavailable —
 * render the "Add to Home Screen" instructions instead.  On all other
 * platforms, render the subscribe/unsubscribe toggle wrapped in Suspense.
 */
@react.component
let make = () => {
  let {state: installState} = InstallPwa.usePwaInstall()

  switch installState {
  | InstallPwa.IosSafari =>
    // Push is not available on iOS Safari until the PWA is installed.
    // Show Add-to-Home-Screen instructions unconditionally (no dismiss here —
    // the user is on the Settings page and explicitly looking at notifications).
    <InstallPwa.IosSafariPanel />

  | _ =>
    // For all other platforms defer to the push support check.
    if !isPushSupported() || getNotificationPermission() == "denied" {
      React.null
    } else {
      <React.Suspense fallback={React.null}>
        <Inner />
      </React.Suspense>
    }
  }
}

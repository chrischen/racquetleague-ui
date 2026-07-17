%%raw("import { t } from '@lingui/macro'")

// SelfCheckinDisplay - Fullscreen QR code display for inviting players
//
// Shows a large QR code pointing at the current page URL so players can
// scan it with their phone camera to open the tool and join the event.

@val @scope(("window", "location")) external locationHref: string = "href"

@react.component
let make = (~onClose: unit => unit) => {
  open Lingui.Util
  let ts = Lingui.UtilString.t

  <div
    className="fixed inset-0 z-50 flex min-h-screen items-center justify-center bg-slate-950 p-5 text-white"
    role="dialog"
    ariaModal=true>
    <button
      onClick={_ => onClose()}
      className="absolute right-5 top-5 rounded-full bg-slate-800 p-3 text-slate-200 transition-colors hover:bg-slate-700 hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-slate-950"
      title={ts`Close self check-in display`}>
      <Lucide.X className="h-6 w-6" />
    </button>
    <main className="flex w-full max-w-xl flex-col items-center text-center">
      <div
        className="mb-5 flex h-12 w-12 items-center justify-center rounded-full bg-blue-500 text-slate-950">
        <Lucide.UserPlus className="h-7 w-7" />
      </div>
      <p className="mb-2 text-sm font-bold uppercase tracking-[0.2em] text-blue-300">
        {t`Event check-in`}
      </p>
      <h1 className="text-4xl font-extrabold sm:text-5xl"> {t`Scan to check in`} </h1>
      <p className="mt-3 max-w-md text-lg leading-relaxed text-slate-300">
        {t`Open your phone camera, scan this code, and join the event.`}
      </p>
      <div className="mt-8 rounded-3xl bg-white p-4 shadow-2xl sm:p-5">
        <QRCode value={locationHref} />
      </div>
      <p className="mt-6 text-sm text-slate-400">
        {t`Having trouble scanning? Try to find the event from the club page.`}
      </p>
    </main>
  </div>
}

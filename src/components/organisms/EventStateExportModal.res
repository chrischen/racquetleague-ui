%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// Hands the organiser this event's recorded history as a string to carry
// elsewhere. Read-only by design: the paired import modal is where a string
// comes back in.
@val @scope(("navigator", "clipboard"))
external writeText: string => promise<unit> = "writeText"

@send external select: Dom.element => unit = "select"

@react.component
let make = (~text: string, ~onClose: unit => unit) => {
  let ts = Lingui.UtilString.t
  let (copied, setCopied) = React.useState(() => false)
  let textareaRef = React.useRef(Nullable.null)

  React.useEffect1(() => {
    if copied {
      let timer = setTimeout(() => setCopied(_ => false), 2000)
      Some(() => clearTimeout(timer))
    } else {
      None
    }
  }, [copied])

  let selectAll = () => textareaRef.current->Nullable.forEach(el => el->select)

  // The clipboard API needs a secure context, so a failure here is expected on a
  // plain-http LAN address — exactly where an organiser moves data between
  // devices. Select the text instead so a manual copy still works.
  let copy = async () => {
    try {
      await writeText(text)
      setCopied(_ => true)
    } catch {
    | _ => {
        setCopied(_ => false)
        selectAll()
      }
    }
  }

  <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
    <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full">
      <div
        className="bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between rounded-t-xl">
        <div className="flex items-center gap-3">
          <Lucide.Download className="w-6 h-6 text-blue-600" />
          <h2 className="text-xl font-bold text-slate-800"> {t`Export History`} </h2>
        </div>
        <button
          onClick={_ => onClose()}
          className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
          ariaLabel={ts`Close`}>
          <Lucide.X className="w-5 h-5 text-slate-600" />
        </button>
      </div>
      <div className="p-6 space-y-4">
        <p className="text-sm text-slate-600">
          {t`Scored matches and rating adjustments only. Paste this into Import History on another device.`}
        </p>
        <textarea
          ref={ReactDOM.Ref.domRef(textareaRef)}
          readOnly=true
          value={text}
          onFocus={_ => selectAll()}
          rows={14}
          className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 font-mono text-xs"
        />
      </div>
      <div
        className="bg-slate-50 border-t border-slate-200 px-6 py-4 flex items-center justify-end gap-3 rounded-b-xl">
        <button
          type_="button"
          onClick={_ => onClose()}
          className="px-4 py-2 rounded-lg font-medium bg-white border border-slate-300 text-slate-700 hover:bg-slate-50 transition-colors">
          {t`Close`}
        </button>
        <button
          type_="button"
          onClick={_ => copy()->ignore}
          className={copied
            ? "flex items-center gap-2 px-6 py-2 rounded-lg font-medium transition-colors shadow-md bg-green-600 text-white"
            : "flex items-center gap-2 px-6 py-2 rounded-lg font-medium transition-colors shadow-md bg-blue-600 text-white hover:bg-blue-700"}>
          {copied
            ? <> <Lucide.Check className="w-4 h-4" /> <span> {t`Copied`} </span> </>
            : <> <Lucide.Copy className="w-4 h-4" /> <span> {t`Copy`} </span> </>}
        </button>
      </div>
    </div>
  </div>
}

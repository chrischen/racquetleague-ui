%%raw("import { t } from '@lingui/macro'")
open Lingui.Util

// The card chrome for a UseEditable field, so every editable section on a page
// looks the same: a plain card, a dashed "click to edit" card while edit mode
// is on, and the open editor with Cancel/Save.
//
// In the Editable state the whole card is a <button>, so `children` must be
// phrasing content (spans, text) with no interactive elements inside.

@react.component
let make = (
  ~state: UseEditable.state,
  ~heading: React.element,
  // Accessible name for the click-to-edit card, e.g. "Edit notes from the host".
  ~editLabel: string,
  ~saveLabel: React.element,
  ~onStartEditing: unit => unit,
  ~onCancel: unit => unit,
  ~onCommit: unit => unit,
  // The editor, shown in the Editing state in place of `children`.
  ~editor: React.element,
  // Outer placement; the card fills it.
  ~className: string="mx-3 mt-3",
  ~children: React.element,
) => {
  let headingClass = "text-base font-semibold text-gray-900 dark:text-gray-100"
  <div className>
    {switch state {
    | UseEditable.Display =>
      <section
        className="rounded-xl border border-gray-200 bg-white px-4 py-4 dark:border-[#2a2b30] dark:bg-[#1e1f23]">
        <h2 className={"mb-3 " ++ headingClass}> heading </h2>
        children
      </section>
    | UseEditable.Editing =>
      <section
        className="rounded-xl border-2 border-[#94c93a] bg-white px-4 py-4 shadow-[0_0_0_4px_rgba(189,242,93,0.18)] dark:bg-[#1e1f23]">
        <div className="mb-3 flex items-center justify-between gap-2">
          <h2 className=headingClass> heading </h2>
          <span
            className="font-mono text-[10px] uppercase tracking-wider text-[#547817] dark:text-[#bdf25d]">
            {t`Editing`}
          </span>
        </div>
        editor
        <div className="mt-2.5 flex items-center justify-end gap-1.5">
          <button
            type_="button"
            onClick={_ => onCancel()}
            className="inline-flex items-center gap-1.5 rounded-md border border-gray-200 bg-white px-3 py-1.5 text-xs font-semibold text-gray-600 transition-colors hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:border-[#3a3b40] dark:bg-[#222326] dark:text-gray-300 dark:hover:bg-[#26272b]">
            <Lucide.X size=13 \"aria-hidden"="true" />
            {t`Cancel`}
          </button>
          <button
            type_="button"
            onClick={_ => onCommit()}
            className="inline-flex items-center gap-1.5 rounded-md bg-[#bdf25d] px-3 py-1.5 text-xs font-semibold text-black transition-colors hover:bg-[#aee050] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-1">
            <Lucide.Check size=13 \"aria-hidden"="true" />
            saveLabel
          </button>
        </div>
      </section>
    | UseEditable.Editable =>
      <button
        type_="button"
        onClick={_ => onStartEditing()}
        ariaLabel=editLabel
        className="group relative block w-full rounded-xl border-2 border-dashed border-[#94c93a]/70 bg-white px-4 py-4 text-left transition-colors hover:border-[#94c93a] hover:bg-[#bdf25d]/[0.07] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] focus-visible:ring-offset-2 dark:bg-[#1e1f23] dark:hover:bg-[#bdf25d]/[0.06]">
        <span
          className="absolute -top-2.5 right-3 inline-flex items-center gap-1 rounded-full bg-[#bdf25d] px-2 py-0.5 font-mono text-[9px] font-semibold uppercase tracking-wider text-black">
          <Lucide.Pencil size=9 \"aria-hidden"="true" />
          {t`Edit`}
        </span>
        <span className={"mb-3 block " ++ headingClass}> heading </span>
        children
        <span className="mt-2 block font-mono text-[10px] text-gray-400 dark:text-gray-500">
          {t`Click to edit`}
        </span>
      </button>
    }}
  </div>
}

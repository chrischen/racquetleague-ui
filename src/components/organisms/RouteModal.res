%%raw("import { t } from '@lingui/macro'")

// Modal chrome from the Magic Patterns NewPlanModal, for routes that open over
// the page they were reached from: a dimmed backdrop and a centred panel (a
// bottom sheet on phones) with eyebrow, title and close. The wrapped route
// stays the URL, so closing is a navigation the caller decides on. Built on
// Radix so Escape, focus trapping and click-outside come for free.
//
// The flex wrapper sits outside Dialog.Content on purpose: Radix pins
// `pointer-events: auto` on Content, so if the wrapper were the Content a click
// on the empty margin would count as inside the dialog and never dismiss it.

let iconButtonClass = "rounded-md p-1.5 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-900 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#94c93a] dark:hover:bg-[#2a2b30] dark:hover:text-white"

@react.component
let make = (
  ~title: React.element,
  ~eyebrow: option<React.element>=?,
  ~description: option<React.element>=?,
  ~onClose: unit => unit,
  ~onBack: option<unit => unit>=?,
  ~children: React.element,
) => {
  let ts = Lingui.UtilString.t
  // The portal renders into document.body, outside the shell's dark-mode
  // wrappers, so the theme class is mirrored on the dialog's own root.
  let themeClass = DarkMode.rootClass(DarkMode.use())
  <Radix.Dialog.Root
    \"open"=true
    onOpenChange={isOpen =>
      if !isOpen {
        onClose()
      }}>
    <Radix.Dialog.Portal>
      <div className=themeClass>
        <Radix.Dialog.Overlay
          className="fixed inset-0 z-40 bg-black/40 animate-in fade-in duration-150"
        />
        <div
          className="pointer-events-none fixed inset-0 z-50 flex items-stretch justify-center px-3 pb-[calc(env(safe-area-inset-bottom)+72px)] pt-16 md:items-center md:p-4">
        <Radix.Dialog.Content
          className="pointer-events-auto flex max-h-full w-full flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-2xl outline-none animate-in fade-in slide-in-from-bottom-4 duration-200 dark:border-[#2a2b30] dark:bg-[#1e1f23] md:max-h-[90vh] md:w-[min(620px,calc(100vw-2rem))]">
          <header
            className="flex flex-shrink-0 items-center justify-between gap-3 border-b border-gray-100 px-4 py-3 dark:border-[#2a2b30]">
            <div className="flex min-w-0 items-center gap-2.5">
              {switch onBack {
              | Some(back) =>
                <button
                  type_="button" onClick={_ => back()} ariaLabel={ts`Back`} className=iconButtonClass>
                  <Lucide.ArrowLeft size=16 \"aria-hidden"="true" />
                </button>
              | None => React.null
              }}
              <div className="min-w-0">
                {switch eyebrow {
                | Some(eyebrow) =>
                  <div
                    className="font-mono text-[10px] uppercase tracking-wider text-gray-400 dark:text-gray-500">
                    eyebrow
                  </div>
                | None => React.null
                }}
                <Radix.Dialog.Title
                  className="truncate text-base font-semibold text-gray-900 dark:text-gray-100">
                  title
                </Radix.Dialog.Title>
                {switch description {
                | Some(description) =>
                  <Radix.Dialog.Description asChild=true>
                    <span className="sr-only"> description </span>
                  </Radix.Dialog.Description>
                | None => React.null
                }}
              </div>
            </div>
            <button
              type_="button" onClick={_ => onClose()} ariaLabel={ts`Close`} className=iconButtonClass>
              <Lucide.X size=16 \"aria-hidden"="true" />
            </button>
          </header>
          <div className="flex-1 overflow-y-auto px-4 py-4"> children </div>
        </Radix.Dialog.Content>
        </div>
      </div>
    </Radix.Dialog.Portal>
  </Radix.Dialog.Root>
}

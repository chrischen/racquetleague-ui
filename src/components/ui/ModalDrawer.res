%%raw("import { t, plural } from '@lingui/macro'")
open Lingui.Util
open HeadlessUi;

@react.component
let make = (~title: string, ~children: React.element, ~open_, ~setOpen) => {
  // let (open_, setOpen) = React.useState(_ => false)

	<Dialog \"open"={open_} onClose={setOpen} className="relative z-10">
      <DialogBackdrop
        transition=true
        className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity duration-500 ease-in-out data-[closed]:opacity-0"
      />

      <div className="fixed inset-0 overflow-hidden">
        <div className="absolute inset-0 overflow-hidden">
          <div className="pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10">
            <DialogPanel
              transition=true
              className="pointer-events-auto w-screen max-w-2xl transform transition duration-500 ease-in-out data-[closed]:translate-x-full sm:duration-200"
            >
              <div className="flex h-full flex-col overflow-y-scroll bg-white py-6 shadow-xl">
                <div className="px-4 sm:px-6">
                  <div className="flex items-start justify-between">
                    <DialogTitle className="text-base font-semibold leading-6 text-gray-900">{title->React.string}</DialogTitle>
                    <div className="ml-3 flex h-7 items-center">
                      <button
                        type_="button"
                        onClick={_ => setOpen(_ => false)}
                        className="relative rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
                      >
                        <span className="absolute -inset-2.5" />
                        <span className="sr-only">{t`Close panel`}</span>
                        <HeroIcons.XMarkIcon aria-hidden="true" className="h-6 w-6" />
                      </button>
                    </div>
                  </div>
                </div>
                <div className="relative mt-6 flex-1 px-4 sm:px-6">{children}</div>
              </div>
            </DialogPanel>
          </div>
        </div>
      </div>
    </Dialog>
}

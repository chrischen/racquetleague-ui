%%raw("import { t, plural } from '@lingui/macro'")
@react.component
let make = (
  ~actions: React.element,
  ~panelWidthClass: string="w-4/5 sm:w-3/4 md:w-2/3 max-w-xs",
  ~className: string="",
  ~panelClassName: string="",
  ~defaultOpen: bool=false,
  ~onToggle: option<bool => unit>=?,
  ~children: React.element,
) => {
  let (isOpen, setIsOpen) = React.useState(() => defaultOpen)
  let toggle = () =>
    setIsOpen(prev => {
      let next = !prev
      switch onToggle {
      | Some(f) => f(next)
      | None => ()
      }
      next
    })
  <div className={Util.cx(["relative overflow-hidden", className])}>
    <div onClick={_ => toggle()}> {children} </div>
    {isOpen
      ? <button
          className="absolute inset-0 bg-white/60 backdrop-blur-sm z-10 cursor-pointer"
          ariaLabel={Lingui.UtilString.t`close actions`}
          onClick={e => {
            e->ReactEvent.Mouse.stopPropagation
            setIsOpen(_ => {
              switch onToggle {
              | Some(f) => f(false)
              | None => ()
              }
              false
            })
          }}
        />
      : React.null}
    <div
      ariaHidden={!isOpen}
      className={Util.cx([
        "absolute top-0 right-0 h-full bg-white/95 backdrop-blur border-l border-gray-200",
        panelWidthClass,
        "flex px-4 py-2 z-20 overflow-y-auto transition-transform duration-200 ease-out will-change-transform",
        isOpen
          ? "translate-x-0 shadow-[-4px_0_8px_-2px_rgba(0,0,0,0.15)] pointer-events-auto"
          : "translate-x-full pointer-events-none",
        panelClassName,
      ])}
      onClick={e => e->ReactEvent.Mouse.stopPropagation}>
      <div className="flex h-full w-full items-stretch">
        <button
          type_="button"
          onClick={_ =>
            setIsOpen(_ => {
              switch onToggle {
              | Some(f) => f(false)
              | None => ()
              }
              false
            })}
          className="self-stretch flex items-center px-2 -ml-2 rounded-r-md text-gray-500 hover:text-gray-700 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-colors"
          ariaLabel={Lingui.UtilString.t`close`}>
          <HeroIcons.ChevronRightIcon className="h-5 w-5" />
        </button>
        <div className="flex flex-1 items-center justify-end gap-3 px-4"> {actions} </div>
      </div>
    </div>
  </div>
}

%%raw("import { cx } from '@linaria/core'")

@react.component
let make = (
  ~onClick: JsxEventU.Mouse.t => unit,
  ~onTouchStart: option<JsxEventU.Touch.t => unit>=?,
  ~className=?,
  ~active=false,
  ~alt: option<string>=?,
  ~children: React.element,
) => {
  open Util
  let baseClass = active ? "italic" : ""
  <a
    href="#"
    ?alt
    className={className->Option.map(c => cx([c, baseClass]))->Option.getOr(baseClass)}
    onClick={e => {
      e->JsxEventU.Mouse.preventDefault
      onClick(e)
    }}
    onTouchStart=?{onTouchStart->Option.map(f => {
      e => {
        e->JsxEventU.Touch.preventDefault
        f(e)
      }
    })}>
    {children}
  </a>
}

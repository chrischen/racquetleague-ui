%%raw("import { cx, css } from '@linaria/core'")

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
    className={Util.cx([
      className->Option.map(c => cx([c, baseClass]))->Option.getOr(baseClass),
      %raw("css`-webkit-touch-callout: none; user-select: none;`"),
    ])}
    draggable=false
    onClick={e => {
      e->JsxEventU.Mouse.preventDefault
      onClick(e)
    }}
    onTouchStart=?{onTouchStart->Option.map(f => {
      e => {
        f(e)
      }
    })}>
    {children}
  </a>
}

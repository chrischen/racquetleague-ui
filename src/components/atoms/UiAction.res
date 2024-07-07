%%raw("import { cx } from '@linaria/core'")

@react.component
let make = (~onClick: unit => unit, ~className=?, ~active=false, ~children: React.element) => {
	open Util;
	let baseClass = active ? "italic" : ""
	<a href="#" className={className->Option.map(c => cx([c, baseClass]))->Option.getOr(baseClass)} onClick={e => {
		e->JsxEventU.Mouse.preventDefault;
		onClick()
	}}>
		{children}
	</a>
}

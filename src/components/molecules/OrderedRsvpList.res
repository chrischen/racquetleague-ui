@react.component
let make = (
  ~items: array<'a>,
  ~children: (~index: int, ~item: 'a) => React.element,
  ~className: option<string>=?,
) => {
  let baseClass = "space-y-3"
  let computedClassName = switch className {
  | Some(extra) if extra != "" => baseClass ++ " " ++ extra
  | _ => baseClass
  }

  <div className=computedClassName>
    {items
    ->Array.mapWithIndex((item, i) =>
      <div key={`item-${i->Int.toString}`} className="flex items-center space-x-3">
        <span
          className="flex-shrink-0 w-6 h-6 bg-gray-100 rounded-full flex items-center justify-center text-xs font-medium text-gray-600">
          {(i + 1)->Int.toString->React.string}
        </span>
        {children(~index=i, ~item)}
      </div>
    )
    ->React.array}
  </div>
}

@react.component
let make = (
  ~title: React.element,
  ~count: int,
  ~max: option<int>=?,
  ~className: option<string>=?,
) => {
  let baseClass = "font-medium text-gray-900"
  let computedClassName = switch className {
  | Some(extra) if extra != "" => baseClass ++ " " ++ extra
  | _ => baseClass
  }

  <h3 className=computedClassName>
    {title}
    <RsvpListCount count ?max />
  </h3>
}

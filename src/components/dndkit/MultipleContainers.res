module Items = {
  // type t = Js.Dict.t<(array<string>, array<string>)>
  type t = Js.Dict.t<(array<string>)>
}
type renderProps = {
  value: string,
  dragging: bool,
}
@module("./multipleContainers.tsx") @react.component
external make: (
  ~items: Items.t,
  ~minimal: bool=?,
  ~setItems: (Items.t => Items.t) => unit,
  ~deleteContainer: string => unit,
  ~renderContainer: (array<React.element>, int) => React.element=?,
  ~renderItem: renderProps => React.element=?,
  ~renderValue: string => React.element,
) => React.element = "MultipleContainers"

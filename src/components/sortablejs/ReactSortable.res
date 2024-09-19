// module Plugin = {
//   type t;
//
//   @new @module("react-sortablejs") external simpleDrag: t = "SimpleDrag"
//   @new @module("react-sortablejs") external multiDrag: t = "MultiDrag"
//   @new @module("react-sortablejs") external swap: t = "Swap"
// }
// module Sortable = {
//   type t
//   @module("react-sortablejs")
//   external sortable: t = "Sortable"
//
//   @send
//   external mount: (t, Plugin.t) => unit = "mount"
// }

@module("react-sortablejs") @react.component
external make: (
  ~list: array<'a>,
  ~setList: (array<'a> => array<'a>) => unit,
  ~swap: bool=?,
  ~multiDrag: bool=?,
  ~children: React.element,
) => React.element = "ReactSortable"

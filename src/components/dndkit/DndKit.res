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

module DndContext = {
  type active = {id: string}
  type over = {id: string}
  type dropEvent = {
    active: active,
    over: option<over>,
  }
  type dropCb = dropEvent => unit
  @module("@dnd-kit/core") @react.component
  external make: (~children: React.element, ~onDragEnd: dropCb) => React.element = "DndContext"
}

module SortableContext = {
  type strategy
  @module("@dnd-kit/sortable")
  external rectSwappingStrategy: strategy = "rectSwappingStrategy"
  @module("@dnd-kit/sortable")
  external verticalListSortingStrategy: strategy = "verticalListSortingStrategy"

  @module("@dnd-kit/sortable") @react.component
  external make: (
    ~items: array<'a>,
    ~strategy: strategy=?,
    ~children: React.element,
  ) => React.element = "SortableContext"
}

module SortableItem = {
  @module("./sortableItem.tsx") @react.component
  external make: (~id: string, ~handle: bool=?, ~children: React.element) => React.element = "SortableItem"
}

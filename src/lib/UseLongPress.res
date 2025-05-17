// Bindings for the 'use-long-press' npm package
// Package docs: https://github.com/minwork/use-long-press

// The event object passed to callbacks is MouseEvent | TouchEvent.
// We use ReactEvent.Synthetic.t as a general type, and users can
// attempt to narrow it down if needed (e.g., using ReactEvent.Mouse.fromSynthetic).

type meta<'context> = {context: option<'context>}

// Type for the main long-press callback and event handlers in options (onStart, onFinish, onCancel)
type eventCallback<'context> = ReactEvent.Synthetic.t => unit

// Type for the filterEvents callback
type filterEventsCallback = ReactEvent.Synthetic.t => bool

// Options for the useLongPress hook
type options<'context> = {
  onStart?: eventCallback<'context>,
  onFinish?: eventCallback<'context>,
  onCancel?: eventCallback<'context>,
  threshold?: int,
  captureEvent?: bool,
  // cancelOnMovement accepts a boolean or a number (pixel threshold)
  // Use Js.true_, Js.false, or Js.Any.fromInt(number)
  cancelOnMovement?: bool,
  detect?: [#mouse | #touch | #both],
  filterEvents?: filterEventsCallback,
  cancelOutsideElement?: bool,
}

// Props object returned by the bind() function, to be spread onto the target element
type bindProps = {
  onContextMenu: ReactEvent.Mouse.t => unit,
  onMouseDown: ReactEvent.Mouse.t => unit,
  onMouseUp: ReactEvent.Mouse.t => unit,
  onMouseMove: ReactEvent.Mouse.t => unit,
  onMouseLeave: ReactEvent.Mouse.t => unit,
  onTouchStart: ReactEvent.Touch.t => unit,
  onTouchEnd: ReactEvent.Touch.t => unit,
  onTouchMove: ReactEvent.Touch.t => unit,
  onPointerUp: ReactEvent.Pointer.t => unit,
  onPointerDown: ReactEvent.Pointer.t => unit,
  onPointerMove: ReactEvent.Pointer.t => unit,
  onPointerLeave: ReactEvent.Pointer.t => unit,
  onPointerCancel: ReactEvent.Pointer.t => unit,
}

// The useLongPress hook returns a `bind` function.
// This `bind` function can be called with an optional context argument.
type bindFn = unit => bindProps

@module("use-long-press") @react.hook
external use: (option<eventCallback<'context>>, option<options<'context>>) => bindFn =
  "useLongPress"

/*
Example Usage:

module MyComponent = {
  @react.component
  let make = () => {
    let handleLongPress = React.useCallback((_event: ReactEvent.Synthetic.t, meta: meta<string>) => {
      switch meta.context {
      | Some(ctx) => Js.log2("Long pressed with context:", ctx)
      | None => Js.log("Long pressed without context")
      }
    }, [])

    let handleStart = React.useCallback((_event, meta: meta<string>) => {
      Js.log2("Press started with context:", meta.context)
    }, [])

    let options: options<string> = {
      onStart: Some(handleStart),
      threshold: Some(500),
      cancelOnMovement: Js.true_, // or Js.Any.fromInt(25) for pixel threshold
      detect: Some(#both),
    }

    // Using string as context type
    let bind = use(. Some(handleLongPress), ~options)

    // Using int as context type for another element
    let bindWithIntContext = use(. 
      Some((_, meta: meta<int>) => Js.log2("Integer context:", meta.context)), 
      ~options={threshold: Some(300)}
    )

    <div>
      <div {...bind(~context="Hello from ReScript", ())}>
        {"Press and hold me (string context)"->React.string}
      </div>
      <div {...bindWithIntContext(~context=123, ())}>
        {"Press and hold me (int context)"->React.string}
      </div>
      <div {...bind()}> // No context passed
        {"Press and hold me (no context)"->React.string}
      </div>
    </div>
  }
}
*/

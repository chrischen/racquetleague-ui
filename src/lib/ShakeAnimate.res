let getRandomTransformOrigin = () => {
  let value = (16. +. 40. *. Js.Math.random()) /. 100.
  let value2 = (15. +. 36. *. Js.Math.random()) /. 100.
  {
    FramerMotion.originX: value,
    originY: value2,
  }
}

let getRandomDelay = (): float => -.(Js.Math.random() *. 0.7 +. 0.05)

let randomDuration = () => Js.Math.random() *. 0.07 +. 0.23

type transition = {
  delay: float,
  repeat: float, // Using float for Infinity, Framer Motion might handle Js.Float._Infinity
  duration: float,
}

type variant = {
  rotate: array<float>,
  transition?: transition, // Make transition optional for the reset case
}

@unboxed
type variant_ = Variant(variant) | VariantFn(int => variant)

let variants = {
  "start": VariantFn(
    (i): variant => {
      rotate: mod(i, 2) == 0 ? [-1., 1.3, 0.] : [1., -1.4, 0.],
      transition: {
        delay: getRandomDelay(),
        repeat: infinity, // Use Js.Float._Infinity for Infinity
        duration: randomDuration(),
      },
    },
  ),
  "reset": Variant({rotate: [0.]}), // Rotate is an array, transition is None
}

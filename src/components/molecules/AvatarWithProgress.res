// AvatarWithProgress component in ReScript React
// Props: src, alt, optional progress (0-100, default 100), optional sigmaProgress for uncertainty display

@react.component
let make = (
  ~src: string,
  ~alt: string,
  ~progress: option<int>=?,
  ~sigmaProgress: option<int>=?,
  (),
) => {
  // Defaults
  let progressVal = progress->Option.getOr(100)
  let sigmaProgressVal = sigmaProgress->Option.getOr(0)
  // Core dimensions
  let size = 32
  let strokeWidth = 2.
  let radius = (size->Int.toFloat -. strokeWidth) /. 2.
  let pi = 3.141592653589793
  let circumference = radius *. 2. *. pi
  let strokeDashoffset = circumference -. progressVal->Int.toFloat /. 100. *. circumference
  // Calculate sigma portion that starts from end of normal progress
  let sigmaArcLength = sigmaProgressVal->Int.toFloat /. 100. *. circumference
  let sigmaStrokeDashoffset = circumference -. sigmaArcLength
  // Rotation angle for sigma circle to start from end of normal progress (in degrees)
  let sigmaRotationAngle = progressVal->Int.toFloat *. 360. /. 100.

  <div
    className="relative flex-shrink-0"
    style={
      width: size->Int.toFloat->Belt.Float.toString ++ "px",
      height: size->Int.toFloat->Belt.Float.toString ++ "px",
    }>
    <svg
      className="absolute inset-0 w-full h-full -rotate-90"
      viewBox={"0 0 " ++ size->Int.toString ++ " " ++ size->Int.toString}>
      <circle
        className="text-gray-200"
        strokeWidth={strokeWidth->Belt.Float.toString}
        stroke="currentColor"
        fill="transparent"
        r={radius->Belt.Float.toString}
        cx={(size->Int.toFloat /. 2.)->Belt.Float.toString}
        cy={(size->Int.toFloat /. 2.)->Belt.Float.toString}
      />
      {sigmaProgress
      ->Option.map(_ =>
        <circle
          className="text-red-300" // Light pink color for sigma, same as bar version
          strokeWidth={strokeWidth->Belt.Float.toString}
          strokeDasharray={circumference->Belt.Float.toString}
          strokeDashoffset={sigmaStrokeDashoffset->Belt.Float.toString}
          strokeLinecap="round"
          stroke="currentColor"
          fill="transparent"
          r={radius->Belt.Float.toString}
          cx={(size->Int.toFloat /. 2.)->Belt.Float.toString}
          cy={(size->Int.toFloat /. 2.)->Belt.Float.toString}
          transform={`rotate(${sigmaRotationAngle->Belt.Float.toString} ${(size->Int.toFloat /. 2.)
              ->Belt.Float.toString} ${(size->Int.toFloat /. 2.)->Belt.Float.toString})`}
          style={opacity: "0.7"} // Make it slightly transparent to show layering
        />
      )
      ->Option.getOr(React.null)}
      <circle
        className="text-red-500"
        strokeWidth={strokeWidth->Belt.Float.toString}
        strokeDasharray={circumference->Belt.Float.toString}
        strokeDashoffset={strokeDashoffset->Belt.Float.toString}
        strokeLinecap="round"
        stroke="currentColor"
        fill="transparent"
        r={radius->Belt.Float.toString}
        cx={(size->Int.toFloat /. 2.)->Belt.Float.toString}
        cy={(size->Int.toFloat /. 2.)->Belt.Float.toString}
      />
    </svg>
    <img
      src
      alt
      className="rounded-full w-full h-full object-cover"
      style={padding: strokeWidth->Belt.Float.toString ++ "px"}
    />
  </div>
}

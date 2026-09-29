// AvatarWithProgress component in ReScript React
// Props: src, alt, optional progress (0-100, default 100), optional sigmaProgress for uncertainty display
// An empty src (no picture) shows the initial of alt instead.

// The letter or digit a picture-less avatar shows for a name: the first one
// in it (so "[Line username missing]" gives "L"), or "?" when there is none.
let initialOf = (name: string) =>
  switch name->String.match(%re("/[\p{L}\p{N}]/u")) {
  | Some(m) => m->RegExp.Result.fullMatch->String.toUpperCase
  | None => "?"
  }

@react.component
let make = (
  ~src: string,
  ~alt: string,
  ~progress: option<int>=?,
  ~sigmaProgress: option<int>=?,
  ~size: int=32,
  ~strokeWidth: float=2.,
  (),
) => {
  // Defaults
  let progressVal = progress->Option.getOr(100)
  let sigmaProgressVal = sigmaProgress->Option.getOr(0)
  // Core dimensions
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
    // No picture: the name's initial, as AvatarWithProgressBar shows.
    {src == ""
      ? <div
          role="img"
          ariaLabel=alt
          className="absolute rounded-full bg-slate-300 flex items-center justify-center text-slate-600 font-semibold leading-none select-none"
          style={
            top: strokeWidth->Belt.Float.toString ++ "px",
            left: strokeWidth->Belt.Float.toString ++ "px",
            right: strokeWidth->Belt.Float.toString ++ "px",
            bottom: strokeWidth->Belt.Float.toString ++ "px",
            fontSize: (size->Int.toFloat *. 0.4)->Belt.Float.toString ++ "px",
          }>
          {initialOf(alt)->React.string}
        </div>
      : <img
          src
          alt
          className="rounded-full w-full h-full object-cover"
          style={padding: strokeWidth->Belt.Float.toString ++ "px"}
        />}
  </div>
}

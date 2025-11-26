// AvatarWithProgressBar Component
//
// Displays a user avatar with a circular progress bar indicating skill level
// Progress is normalized 0-100% with color coding:
// - Green (75%+): High skill
// - Blue (50-75%): Medium-high skill  
// - Amber (25-50%): Medium-low skill
// - Red (<25%): Low skill

// Helper function to get skill color based on level
let getSkillColor = (skillLevel: float): string => {
  if skillLevel >= 75. {
    "#10b981" // green-500
  } else if skillLevel >= 50. {
    "#3b82f6" // blue-500
  } else if skillLevel >= 25. {
    "#f59e0b" // amber-500
  } else {
    "#ef4444" // red-500
  }
}

@react.component
let make = (
  ~pictureUrl: option<string>=?,
  ~name: string,
  ~skillLevel: float,
  ~size: [#small | #medium | #large]=#medium,
) => {
  // Size configurations
  let (containerSize, avatarSize, radius) = switch size {
  | #small => ("w-8 h-8", "w-6 h-6", 14.)
  | #medium => ("w-10 h-10", "w-7 h-7", 18.)
  | #large => ("w-12 h-12", "w-9 h-9", 22.)
  }

  let skillColor = getSkillColor(skillLevel)

  // Calculate circle progress (starts at top, goes clockwise)
  let pi = 3.14159265359
  let circumference = 2. *. pi *. radius
  let progress = (skillLevel /. 100.) *. circumference

  let svgSize = switch size {
  | #small => "32"
  | #medium => "40"
  | #large => "48"
  }

  let svgViewBox = `0 0 ${svgSize} ${svgSize}`
  let center = switch size {
  | #small => "16"
  | #medium => "20"
  | #large => "24"
  }

  <div className={`relative flex-shrink-0 ${containerSize}`}>
    <svg className={`${containerSize} -rotate-90`} viewBox={svgViewBox}>
      // Background circle
      <circle
        cx={center}
        cy={center}
        r={radius->Float.toString}
        fill="none"
        stroke="#e5e7eb"
        strokeWidth="2"
      />
      // Progress circle
      <circle
        cx={center}
        cy={center}
        r={radius->Float.toString}
        fill="none"
        stroke={skillColor}
        strokeWidth="2"
        strokeDasharray={circumference->Float.toString}
        strokeDashoffset={(circumference -. progress)->Float.toString}
        strokeLinecap="round"
        className="transition-all duration-300"
      />
    </svg>
    {switch pictureUrl {
    | Some(url) =>
      <img
        src={url}
        alt={name}
        className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 ${avatarSize} rounded-full object-cover`}
      />
    | None =>
      <div
        className={`absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 ${avatarSize} rounded-full bg-slate-300 flex items-center justify-center text-slate-600 font-semibold text-xs`}>
        {name->String.charAt(0)->String.toUpperCase->React.string}
      </div>
    }}
  </div>
}

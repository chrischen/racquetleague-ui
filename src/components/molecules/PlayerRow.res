// PlayerRow Component - Displays a player with avatar and info
//
// This component shows a player with their avatar, name, ID, and play count.
// Used in both MatchCard and ScoreModal components.

open Rating

module Fragment = %relay(`
  fragment PlayerRow_user on User {
    picture
  }
`)

type winners = Left | Right

@react.component
let make = (
  ~player: Player.t<'a>,
  ~isEditing: bool,
  ~winner: option<winners>,
  ~teamSide: winners,
  ~skillLevel: float,
  ~getUserFragmentRefs: 'a => option<RescriptRelay.fragmentRefs<[> #PlayerRow_user]>>,
  ~onClick: option<unit => unit>=?,
  ~debug: bool=false,
  ~incrementDisplayCount: bool=false,
) => {
  // If incrementDisplayCount is true, add 1 to show this player is in the current/upcoming match
  let playCount = incrementDisplayCount ? player.count : player.count

  // Determine if player name should be bold (no winner or their team wins)
  let isBold = switch winner {
  | None => true
  | Some(w) => w == teamSide
  }

  let containerClassName = if isEditing {
    "flex items-center gap-2 bg-white p-2 rounded border border-slate-200 hover:border-blue-500 hover:bg-blue-50 transition-all cursor-pointer"
  } else {
    "flex items-center gap-1.5 flex-1 min-w-0"
  }

  <div
    onClick={switch onClick {
    | Some(handler) => _ => handler()
    | None => _ => ()
    }}
    className={containerClassName}>
    {
      // Get picture URL from fragment if available
      let pictureUrl = player.data->Option.flatMap(data => {
        getUserFragmentRefs(data)->Option.flatMap(fragmentRefs => {
          let userData = Fragment.use(fragmentRefs)
          userData.picture
        })
      })
      <AvatarWithProgressBar ?pictureUrl name={player.name} skillLevel size=#medium />
    }
    <div className="flex flex-col min-w-0 flex-1">
      <span
        className={
          let colorClass = switch player.gender {
          | Female => isBold ? "text-pink-700" : "text-pink-600"
          | Male => isBold ? "text-slate-800" : "text-slate-600"
          }
          let weightClass = isBold ? "font-bold" : "font-normal"
          `text-base ${weightClass} ${colorClass} truncate leading-tight`
        }>
        {player.name->React.string}
      </span>
      <div className="flex items-center gap-1.5 text-xs text-slate-500">
        <span className="font-mono"> {("#" ++ player.intId->Int.toString)->React.string} </span>
        {playCount > 0
          ? <>
              <span> {"•"->React.string} </span>
              <Lucide.Play className="w-3 h-3" />
              <span> {playCount->Int.toString->React.string} </span>
            </>
          : React.null}
      </div>
      {debug
        ? <div className="text-xs text-slate-400 font-mono">
            {`μ: ${player.rating.mu->Float.toFixed(
                ~digits=2,
              )} σ: ${player.rating.sigma->Float.toFixed(~digits=2)}`->React.string}
          </div>
        : React.null}
    </div>
  </div>
}

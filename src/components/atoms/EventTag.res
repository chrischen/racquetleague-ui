%%raw("import { t } from '@lingui/macro'")
type tagType = [#comp | #recreational | #drill | #level | #other]

let getTagType = tag =>
  switch tag {
  | "comp" => #comp
  | "rec" => #recreational
  | "drill" => #drill
  | "all level" | "3.0+" | "3.5+" | "4.0+" | "4.5+" | "5.0+" => #level
  | _ => #other
  }
let getTagTooltip = tag => {
  let ts = Lingui.UtilString.t
  switch tag {
  | "drill" => ts`Skills practice and drills focused on technique improvement`
  | "rec" => ts`Recreational play that will not be submitted to competitive ratings nor DUPR.`
  | "comp" => ts`Results will be submitted to competitive ratings.`
  | "dupr" => ts`Matches will be submitted to DUPR.`
  | "unlisted" =>
    ts`This event is private. Please do not share this event without permission from the organizer.`
  | "all level" => ts`No restriction on skill level. Open to all players.`
  | "3.0+" => ts`Lower intermediate and above`
  | "3.5+" => ts`Upper intermediate and above`
  | "4.0+" => ts`Advanced players`
  | "4.5+" => ts`Highly skilled players`
  | "5.0+" => ts`Professional players`
  | _ => ts`Event tag: ${tag}`
  }
}

@react.component
let make = (~tag: string, ~responsive: bool=false) => {
  let ts = Lingui.UtilString.t
  let td = Lingui.UtilString.dynamic

  let content = switch tag {
  | "unlisted" =>
    <span
      className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-violet-100 dark:bg-violet-900/30 text-violet-600 dark:text-violet-400 text-[10px] font-medium whitespace-nowrap">
      <Lucide.Lock size=10 strokeWidth={2.5} />
      {responsive
        ? <span className="hidden md:inline"> {(ts`Private`)->React.string} </span>
        : (ts`Private`)->React.string}
    </span>
  | "comp" =>
    <span
      className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-800/40 text-[10px] font-medium whitespace-nowrap">
      <Lucide.Trophy size=10 strokeWidth={2.5} />
      {responsive
        ? <span className="hidden md:inline"> {(ts`Rated`)->React.string} </span>
        : (ts`Rated`)->React.string}
    </span>
  | _ =>
    <span
      className="px-2 py-0.5 bg-gray-100 dark:bg-[#2a2b30] text-gray-600 dark:text-gray-400 rounded text-[10px] font-medium whitespace-nowrap">
      {td(tag)->React.string}
    </span>
  }

  <ResponsiveTooltip content={getTagTooltip(tag)}> {content} </ResponsiveTooltip>
}

// Component for rendering a list of tags
module TagList = {
  @react.component
  let make = (~tags: array<string>, ~responsive: bool=false, ~className: string="") => {
    let ts = Lingui.UtilString.t
    let td = Lingui.UtilString.dynamic

    <div className={`flex gap-2 ${className}`}>
      <ResponsiveTooltip.Provider>
        {tags
        ->Array.map(tag => {
          let content = switch tag {
          | "unlisted" =>
            <span
              className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-violet-100 dark:bg-violet-900/30 text-violet-600 dark:text-violet-400 text-[10px] font-medium whitespace-nowrap">
              <Lucide.Lock size=10 strokeWidth={2.5} />
              {responsive
                ? <span className="hidden md:inline"> {(ts`Private`)->React.string} </span>
                : (ts`Private`)->React.string}
            </span>
          | "comp" =>
            <span
              className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-800/40 text-[10px] font-medium whitespace-nowrap">
              <Lucide.Trophy size=10 strokeWidth={2.5} />
              {responsive
                ? <span className="hidden md:inline"> {(ts`Rated`)->React.string} </span>
                : (ts`Rated`)->React.string}
            </span>
          | _ =>
            <span
              className="px-2 py-0.5 bg-gray-100 dark:bg-[#2a2b30] text-gray-600 dark:text-gray-400 rounded text-[10px] font-medium whitespace-nowrap">
              {td(tag)->React.string}
            </span>
          }

          <ResponsiveTooltip key={tag} content={getTagTooltip(tag)}> {content} </ResponsiveTooltip>
        })
        ->React.array}
      </ResponsiveTooltip.Provider>
    </div>
  }
}

// @NOTE Force lingui to include the potential dynamic values here
let __unused = () => {
  let td = Lingui.UtilString.td

  @live (td({id: "Badminton"})->ignore)

  @live (td({id: "Table Tennis"})->ignore)

  @live (td({id: "Pickleball"})->ignore)

  @live (td({id: "Futsal"})->ignore)
  @live (td({id: "drill"})->ignore)
  @live (td({id: "comp"})->ignore)
  @live (td({id: "rec"})->ignore)
  @live (td({id: "all level"})->ignore)
}

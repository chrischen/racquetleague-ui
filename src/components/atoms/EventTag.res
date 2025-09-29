%%raw("import { css, cx } from '@linaria/core'")
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
let make = (~tag: string, ~size: [#small | #medium]=#small) => {
  let td = Lingui.UtilString.dynamic
  let tagType = getTagType(tag)

  let iconSize = switch size {
  | #small => "h-4 w-4"
  | #medium => "h-5 w-5"
  }

  let content = switch tagType {
  | #comp =>
    <span className="inline-flex items-center text-yellow-500 cursor-help">
      <Lucide.Trophy className={iconSize} />
    </span>
  | #other if tag == "unlisted" =>
    <span
      className="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 cursor-help">
      <HeroIcons.LockClosed className={`${iconSize} text-gray-600`} />
    </span>
  | _ =>
    <span
      className="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 cursor-help">
      {td(tag)->React.string}
    </span>
  }

  <ResponsiveTooltip content={getTagTooltip(tag)}> {content} </ResponsiveTooltip>
}

// Component for rendering a list of tags
module TagList = {
  @react.component
  let make = (~tags: array<string>, ~size: [#small | #medium]=#small, ~className: string="") => {
    let td = Lingui.UtilString.dynamic

    let iconSize = switch size {
    | #small => "h-4 w-4"
    | #medium => "h-5 w-5"
    }

    <div className={`flex gap-2 ${className}`}>
      <ResponsiveTooltip.Provider>
        {tags
        ->Array.map(tag => {
          let tagType = getTagType(tag)
          let content = switch tagType {
          | #comp =>
            <span className="inline-flex items-center text-yellow-500 cursor-help">
              <Lucide.Trophy className={iconSize} />
            </span>
          | #other if tag == "unlisted" =>
            <span
              className="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 cursor-help">
              <HeroIcons.LockClosed className={`${iconSize} text-gray-600`} />
            </span>
          | _ =>
            <span
              className="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 cursor-help">
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

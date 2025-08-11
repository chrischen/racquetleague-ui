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
  | "all level" => ts`No restriction on skill level. Open to all players.`
  | "3.0+" => ts`Lower intermediate and above`
  | "3.5+" => ts`Upper intermediate and above`
  | "4.0+" => ts`Advanced players`
  | "4.5+" => ts`Highly skilled players`
  | "5.0+" => ts`Professional players`
  | _ => ts`Event tag: ${tag}`
  }
}

// Hook for mobile detection
let useMobileDetection = () => {
  let (isMobile, setIsMobile) = React.useState(() => false)

  React.useEffect0(() => {
    let checkIsMobile = () => {
      setIsMobile(_ => %raw("typeof window !== 'undefined' && window.innerWidth < 768"))
    }
    checkIsMobile()

    let handleResize = () => checkIsMobile()
    %raw("window.addEventListener")("resize", handleResize)->ignore

    Some(() => %raw("window.removeEventListener")("resize", handleResize)->ignore)
  })

  isMobile
}

@react.component
let make = (~tag: string, ~size: [#small | #medium]=#small) => {
  let td = Lingui.UtilString.dynamic
  let isMobile = useMobileDetection()
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
  | _ =>
    <span
      className="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 cursor-help">
      {td(tag)->React.string}
    </span>
  }

  isMobile
    ? <Radix.Popover.Root>
        <Radix.Popover.Trigger asChild=true> {content} </Radix.Popover.Trigger>
        <Radix.Popover.Content
          side=#top
          className="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95">
          {getTagTooltip(tag)->React.string}
        </Radix.Popover.Content>
      </Radix.Popover.Root>
    : <Radix.Tooltip.Root delayDuration=200.>
        <Radix.Tooltip.Trigger asChild=true> {content} </Radix.Tooltip.Trigger>
        <Radix.Tooltip.Content
          side=#top
          className="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95">
          {getTagTooltip(tag)->React.string}
        </Radix.Tooltip.Content>
      </Radix.Tooltip.Root>
}

// Component for rendering a list of tags
module TagList = {
  @react.component
  let make = (~tags: array<string>, ~size: [#small | #medium]=#small, ~className: string="") => {
    let isMobile = useMobileDetection()
    let td = Lingui.UtilString.dynamic

    let iconSize = switch size {
    | #small => "h-4 w-4"
    | #medium => "h-5 w-5"
    }

    <div className={`flex gap-2 ${className}`}>
      {isMobile
        ? tags
          ->Array.map(tag => {
            let tagType = getTagType(tag)
            let content = switch tagType {
            | #comp =>
              <span className="inline-flex items-center text-yellow-500 cursor-help">
                <Lucide.Trophy className={iconSize} />
              </span>
            | _ =>
              <span
                className="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 cursor-help">
                {td(tag)->React.string}
              </span>
            }

            <Radix.Popover.Root key={tag}>
              <Radix.Popover.Trigger asChild=true> {content} </Radix.Popover.Trigger>
              <Radix.Popover.Content
                side=#top
                className="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95">
                {getTagTooltip(tag)->React.string}
              </Radix.Popover.Content>
            </Radix.Popover.Root>
          })
          ->React.array
        : <Radix.Tooltip.Provider>
            {tags
            ->Array.map(tag => {
              let tagType = getTagType(tag)
              let content = switch tagType {
              | #comp =>
                <span className="inline-flex items-center text-yellow-500 cursor-help">
                  <Lucide.Trophy className={iconSize} />
                </span>
              | _ =>
                <span
                  className="inline-flex items-center rounded-md bg-gray-50 px-2 py-1 text-xs font-medium text-gray-600 ring-1 ring-inset ring-gray-500/10 cursor-help">
                  {td(tag)->React.string}
                </span>
              }

              <Radix.Tooltip.Root key={tag} delayDuration=200.>
                <Radix.Tooltip.Trigger asChild=true> {content} </Radix.Tooltip.Trigger>
                <Radix.Tooltip.Content
                  side=#top
                  className="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95">
                  {getTagTooltip(tag)->React.string}
                </Radix.Tooltip.Content>
              </Radix.Tooltip.Root>
            })
            ->React.array}
          </Radix.Tooltip.Provider>}
    </div>
  }
}

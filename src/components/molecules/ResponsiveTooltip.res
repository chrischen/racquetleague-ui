// ResponsiveTooltip - renders as Popover on mobile, Tooltip on desktop
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
let make = (
  ~children: React.element,
  ~content: string,
  ~side: [#top | #bottom | #left | #right]=#top,
  ~delayDuration: float=200.,
  ~className: string="z-50 overflow-hidden rounded-md bg-gray-900 px-3 py-1.5 text-xs text-white animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95",
) => {
  let isMobile = useMobileDetection()

  <WaitForMessages>
    {() =>
      isMobile
        ? <Radix.Popover.Root>
            <Radix.Popover.Trigger asChild=true> {children} </Radix.Popover.Trigger>
            <Radix.Popover.Content side className> {content->React.string} </Radix.Popover.Content>
          </Radix.Popover.Root>
        : <Radix.Tooltip.Root delayDuration>
            <Radix.Tooltip.Trigger asChild=true> {children} </Radix.Tooltip.Trigger>
            <Radix.Tooltip.Content side className> {content->React.string} </Radix.Tooltip.Content>
          </Radix.Tooltip.Root>}
  </WaitForMessages>
}

// Provider component for when multiple tooltips are used together (desktop only)
module Provider = {
  @react.component
  let make = (~children: React.element) => {
    <Radix.Tooltip.Provider> {children} </Radix.Tooltip.Provider>
  }
}

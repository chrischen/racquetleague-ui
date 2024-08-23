@react.component
let make = (
  ~children: React.element,
  ~cta: option<React.element>=?,
  ~ctaClick: option<unit => unit>=?,
) =>
  <div className="border-l-4 border-red-400 bg-red-50 p-4">
    <div className="flex">
      <div className="flex-shrink-0">
        <HeroIcons.LockClosed \"aria-hidden"="true" className="h-5 w-5 text-red-400" />
      </div>
      <div className="ml-3">
        <p className="text-sm text-red-700">
          {children}
          {cta
          ->Option.flatMap(cta =>
            ctaClick->Option.map(ctaClick => <>
              {" "->React.string}
              <UiAction
                className="font-medium text-red-700 underline hover:text-red-600"
                onClick={_ => ctaClick()}>
                {cta}
              </UiAction>
            </>)
          )
          ->Option.getOr(React.null)}
        </p>
      </div>
    </div>
  </div>

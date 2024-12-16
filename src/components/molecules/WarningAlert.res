@react.component
let make = (~children: React.element, ~cta: option<React.element>=?, ~ctaClick: unit => unit) =>
  <div className="border-l-4 border-yellow-400 bg-yellow-50 p-4">
    <div className="flex">
      <div className="flex-shrink-0">
        <HeroIcons.InformationCircleIcon
          \"aria-hidden"="true" className="h-5 w-5 text-yellow-400"
        />
      </div>
      <div className="ml-3">
        <p className="text-sm text-yellow-700">
          {children}
          {" "->React.string}
          {cta
          ->Option.map(cta =>
            <UiAction
              className="font-medium text-yellow-700 underline hover:text-yellow-600"
              onClick={_ => ctaClick()}>
              {cta}
            </UiAction>
          )
          ->Option.getOr(React.null)}
        </p>
      </div>
    </div>
  </div>

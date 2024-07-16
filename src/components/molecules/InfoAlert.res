@react.component
let make = (~children: React.element, ~cta: React.element, ~ctaClick: unit => unit) =>
  <div className="border-l-4 border-yellow-400 bg-yellow-50 p-4">
    <div className="flex">
      <div className="flex-shrink-0">
        <HeroIcons.ExclamationTriangleIcon
          \"aria-hidden"="true" className="h-5 w-5 text-yellow-400"
        />
      </div>
      <div className="ml-3">
        <p className="text-sm text-yellow-700">
          {children}
          {" "->React.string}
          <UiAction className="font-medium text-yellow-700 underline hover:text-yellow-600" onClick=ctaClick> {cta} </UiAction>
        </p>
      </div>
    </div>
  </div>

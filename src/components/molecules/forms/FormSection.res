%%raw("import { t } from '@lingui/macro'")

@react.component
let make = (~title: React.element, ~description: option<React.element>=?, ~children) => {
  <div className="border-b border-gray-900/10 dark:border-gray-700 pb-12">
    <h2 className="text-base font-semibold leading-7 text-gray-900 dark:text-gray-100"> {title} </h2>
    {description
    ->Option.map(description =>
      <p className="mt-1 text-sm leading-6 text-gray-600 dark:text-gray-400"> {description} </p>
    )
    ->Option.getOr(React.null)}
    {children}
  </div>
}

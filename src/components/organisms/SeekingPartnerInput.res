%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

@react.component
let make = (~seekingPartner: option<int>, ~onChange) => {
  open Lingui.Util
  let checked = seekingPartner->Option.isSome
  <>
    <HeadlessUi.Switch.Group \"as"="div" className="flex items-center">
      <HeadlessUi.Switch
        checked
        onChange
        className={Util.cx([
          checked ? "bg-indigo-600" : "bg-gray-200",
          "relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2",
        ])}>
        <span
          ariaHidden=true
          className={Util.cx([
            checked ? "translate-x-5" : "translate-x-0",
            "pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out",
          ])}
        />
      </HeadlessUi.Switch>
      <HeadlessUi.Switch.Label \"as"="span" className="ml-3 text-sm">
        <span className="font-medium text-gray-900"> {t`seeking a doubles partner`} </span>
        {" "->React.string}
        <span className="text-gray-500">
          {t`shows a badge next to your name in RSVP lists to tell people you are looking for a partner`}
        </span>
      </HeadlessUi.Switch.Label>
    </HeadlessUi.Switch.Group>
  </>
}

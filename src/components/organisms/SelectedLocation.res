%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

// type data<'a> = Promise('a) | Empty

module Fragment = %relay(`
  fragment SelectedLocation_location on Location
  {
    id
    name
  }
`)

@module("../layouts/appContext")
external sessionContext: React.Context.t<UserProvider.session> = "SessionContext"

@react.component
let make = (~location, ~onNewLocation) => {
  open Lingui.Util
  let (showUpdateLocation, setShowUpdateLocation) = React.useState(() => false)
  let location = Fragment.use(location)

  <WaitForMessages>
    {() =>
      <FormSection
        title={t`event location`}
        description={t`choose the location where this event will be held.`}>
        <div className="mt-10 grid grid-cols-1 gap-x-6 gap-y-8">
          <div>
            <span className="font-extrabold">
              {location.name->Option.getOr("?")->React.string}
            </span>
            <UiAction className="ml-2" onClick={_ => setShowUpdateLocation(prev => !prev)}>
              {t`change location`}
            </UiAction>
          </div>
          {showUpdateLocation
            ? <AutocompleteLocation key="autocomplete" onSelected=onNewLocation />
            : React.null}
        </div>
      </FormSection>}
  </WaitForMessages>
}

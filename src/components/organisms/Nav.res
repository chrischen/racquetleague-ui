%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")
open Lingui.Util
open LangProvider.Router

module Fragment = %relay(`
  fragment Nav_query on Query {
    viewer {
      user {
        lineUsername
      }
      ... Nav_viewer
    }

  }
`)

module ViewerFragment = %relay(`
  fragment Nav_viewer on Viewer {
    user {
      id
      lineUsername
    }
  }
`)

module Viewer = {
  @genType @react.component
  let make = (~viewer) => {
    // Uses the Query fragment directly
    let viewer = ViewerFragment.use(viewer)

    {
      viewer.user
      ->Option.flatMap(user =>
        user.lineUsername->Option.map(lineUsername => <>
          <span> {React.string(lineUsername)} </span>
          {React.string(" ")}
          <LogoutLink />
        </>)
      )
      ->Option.getOr(<LoginLink />)
    }
  }
}
module MenuInstance = {
  @module("../ui/navigation-menu") @react.component
  external make: unit => React.element = "MenuInstance"
}

@genType @react.component
let make = (~query) => {
  let query = Fragment.use(query)
  <WaitForMessages>
    {() =>
      <Layout.Container className="mt-4">
        <header>
          <nav>
            <Link to={"/"}>
              <span> {t`racquet league`} </span>
            </Link>
            {React.string(" - ")}
            {query.viewer
            ->Option.map(viewer =>
              <React.Suspense fallback={React.string("...")}>
                <Viewer viewer={viewer.fragmentRefs} />
              </React.Suspense>
            )
            ->Option.getOr(<LoginLink />)}
            {React.string(" - ")}
            <LangSwitch />
            {React.string(" - ")}
            <Link to="/events/create"> {"Add Event"->React.string} </Link>
          </nav>
        </header>
      </Layout.Container>}
  </WaitForMessages>
}

@genType
let default = make

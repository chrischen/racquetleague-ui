%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

// module Query = %relay(`
//   query LeaguePageQuery($after: String, $first: Int, $before: String, $activitySlug: String!, $namespace: String!) {
//     ... RatingListFragment @arguments(after: $after, first: $first, before: $before, activitySlug: $activitySlug, namespace: $namespace)
//   }
// `)

type params = {activitySlug: option<string>, lang: option<string>}
type loaderData = {}

@react.component
let make = () => {
  //let { fragmentRefs } = Fragment.use(events)
  <WaitForMessages>
    {() =>
      <main>
        <Router.Outlet />
      </main>}
  </WaitForMessages>
}

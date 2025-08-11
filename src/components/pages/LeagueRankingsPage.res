%%raw("import { css, cx } from '@linaria/core'")
%%raw("import { t } from '@lingui/macro'")

module Query = %relay(`
  query LeagueRankingsPageQuery(
    $after: String
    $first: Int
    $before: String
    $activitySlug: String!
    $namespace: String!
  ) {
    viewer {
      # Add viewer block
      user {
        id
        lineUsername
        picture
      }
    }
    ...RatingListFragment
      @arguments(
        after: $after
        first: $first
        before: $before
        activitySlug: $activitySlug
        namespace: $namespace
      )
  }
`)

type loaderData = {query: LeagueRankingsPageQuery_graphql.queryRef}
type params = {ns?: string, activitySlug?: string, lang?: string}

@module("react-router-dom")
external useLoaderData: unit => WaitForMessages.data<loaderData> = "useLoaderData"

@genType @react.component
let make = () => {
  open Lingui.Util
  //let { fragmentRefs } = Fragment.use(events)
  let query = useLoaderData()
  let params: params = Router.useParams()
  // let viewer = GlobalQuery.useViewer()
  let {viewer, fragmentRefs} = Query.usePreloaded(~queryRef=query.data.query)

  // Determine title based on ns parameter
  let title = switch params.ns {
  | Some("doubles:rec") => t`Recreational Doubles`
  | _ => t`Competitive Doubles` // Default for empty or other values
  }

  <WaitForMessages>
    {() => {
      <>
        {viewer
        ->Option.flatMap(v => v.user) // Chain the optional access
        ->Option.map(user => {
          <Layout.Container>
            <div
              className="mb-8 flex max-w-lg mx-auto items-center justify-between gap-x-6 rounded-lg border border-white/20 bg-leaguePrimaryDark p-4 ring-1 ring-inset ring-white/10">
              <div className="flex min-w-0 items-center gap-x-4">
                {user.picture
                ->Option.map(picture =>
                  <img
                    className="h-12 w-12 flex-none rounded-full bg-gray-800 ring-1 ring-white/20"
                    src={picture}
                    alt="User profile picture"
                  />
                )
                ->Option.getOr(
                  // Placeholder if no picture
                  <div
                    className="h-12 w-12 flex-none rounded-full bg-gray-800 ring-1 ring-white/20 flex items-center justify-center">
                    <Lucide.User className="h-6 w-6 text-gray-400" />
                  </div>,
                )}
                <div className="min-w-0 flex-auto">
                  <p className="text-base font-semibold leading-6 text-black">
                    {user.lineUsername
                    ->Option.map(name => name->React.string)
                    ->Option.getOr("Unknown User"->React.string)}
                  </p>
                </div>
              </div>
              <div className="flex shrink-0 items-center gap-x-4">
                <Button.Button href={"./p/" ++ user.id} color=#white>
                  {t`View My Profile`}
                </Button.Button>
              </div>
            </div>
          </Layout.Container>
        })
        ->Option.getOr(React.null)}
        <div className="py-10 text-white bg-leaguePrimary">
          <Layout.Container>
            <PageTitle>
              <span className="text-white font-extrabold text-3xl"> {title} </span>
            </PageTitle>
            <p className="mt-5">
              {t`Play doubles games with different partners and receive an individual rating. Prizes are awarded monthly to top players.`}
            </p>
            <p>
              {t`To participate, please join the events here:`}
              {" "->React.string}
              <a className="text-gray-200" href="https://www.pkuru.com">
                {"> P*kuru <"->React.string}
              </a>
            </p>
          </Layout.Container>
        </div>
        <React.Suspense fallback={<Layout.Container> {t`Loading rankings...`} </Layout.Container>}>
          <RatingList ratings=fragmentRefs />
        </React.Suspense>
      </>
    }}
  </WaitForMessages>
}
